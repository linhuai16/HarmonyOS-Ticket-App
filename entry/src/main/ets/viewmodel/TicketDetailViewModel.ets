import { TicketDetailPageVO, ElectronicTicketVO } from '../model/vo/ticket/TicketDetailPageVO'
import { TicketRepository } from '../repository/TicketRepository'
import { TicketStatus } from '../model/enums/TicketStatus'
import { ShipmentRepository } from '../repository/ShipmentRepository'
import { ShipmentVO } from '../model/vo/ticketsource/ShipmentVO'
import { TicketSourceFulfillmentRepository } from '../repository/TicketSourceFulfillmentRepository'
import { CredentialType } from '../model/vo/ticketsource/TicketSourceTypes'
import { DynamicCredentialVO } from '../model/vo/ticketsource/DynamicCredentialVO'

export type CredentialDisplayMode = 'QR' | 'TEXT' | 'ID_CARD' | 'PLACEHOLDER'

export interface TicketCodeDisplayState {
  statusText: string
  tipText: string
  displayMode: CredentialDisplayMode
  credentialTitle: string
  credentialText: string
  showQRCode: boolean
  qrCodeValue: string
  showPlaceholder: boolean
  placeholderText: string
  grayQRCode: boolean
  showOverlay: boolean
  overlayText: string
  canUseForEntry: boolean
  canRefreshDynamic: boolean
}

export class TicketDetailViewModel {
  pageVO: TicketDetailPageVO | undefined = undefined
  userId: string = ''
  orderId: string = ''
  currentTicketId: string = ''
  currentIndex: number = 0
  isLoading: boolean = false
  errorMessage: string = ''
  shipmentErrorMessage: string = ''
  shipmentVO: ShipmentVO | undefined = undefined
  isRefreshingShipment: boolean = false

  /** 动态码明文只存在于当前 VM 内存，不写 AppStorage/Preferences/实体。 */
  dynamicCredentialPayload: string = ''
  dynamicCredentialExpiresAt: string = ''
  dynamicRefreshAfterSeconds: number = 0
  dynamicCredentialErrorMessage: string = ''
  isRefreshingDynamicCredential: boolean = false

  private shipmentRepository: ShipmentRepository = new ShipmentRepository()
  private ticketRepository: TicketRepository = new TicketRepository()
  private fulfillmentRepository: TicketSourceFulfillmentRepository = new TicketSourceFulfillmentRepository()

  async loadPage(userId: string, orderId: string, ticketId: string = ''): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.shipmentErrorMessage = ''
    this.shipmentVO = undefined
    this.clearDynamicCredential()
    this.userId = userId
    this.orderId = orderId

    const pageVO: TicketDetailPageVO | undefined = await this.ticketRepository.getTicketDetailPage(
      userId, orderId, ticketId.length === 0 ? undefined : ticketId)

    if (pageVO === undefined) {
      this.pageVO = undefined
      this.currentIndex = 0
      this.currentTicketId = ''
      this.errorMessage = '票夹详情不存在'
      this.isLoading = false
      return
    }

    this.pageVO = pageVO
    this.currentIndex = this.findInitialIndex(ticketId)
    this.updateCurrentTicketId()

    if (pageVO.deliveryType === 'PAPER_TICKET' && pageVO.deliveryMode === 'EXPRESS') {
      try {
        this.shipmentVO = await this.shipmentRepository.getShipment(orderId, userId)
      } catch (error) {
        this.shipmentVO = undefined
        this.shipmentErrorMessage = this.message(error, '物流信息暂未生成，请稍后刷新')
      }
    }
    this.isLoading = false
  }

  async refresh(): Promise<void> {
    if (this.userId.length === 0 || this.orderId.length === 0) return
    await this.loadPage(this.userId, this.orderId, this.currentTicketId)
  }

  async syncShipment(): Promise<void> {
    if (this.userId.length === 0 || this.orderId.length === 0 || this.isRefreshingShipment) return
    this.isRefreshingShipment = true
    this.shipmentErrorMessage = ''
    try {
      this.shipmentVO = await this.shipmentRepository.syncShipment(this.orderId, this.userId)
    } catch (error) {
      this.shipmentErrorMessage = this.message(error, '物流刷新失败，请稍后重试')
    }
    this.isRefreshingShipment = false
  }

  async refreshDynamicCredential(): Promise<boolean> {
    const ticket: ElectronicTicketVO | undefined = this.getCurrentTicket()
    if (ticket === undefined || ticket.ticketStatus !== TicketStatus.UNUSED || ticket.credentialType !== 'DYNAMIC_QR') {
      this.dynamicCredentialErrorMessage = '当前票不支持刷新动态二维码'
      return false
    }
    if (ticket.dynamicQrMode === 'PROVIDER_WALLET') {
      this.dynamicCredentialErrorMessage = '请按页面提示前往官方票夹查看动态入场凭证'
      return false
    }
    if (ticket.dynamicQrMode !== 'REMOTE_REFRESH') {
      this.dynamicCredentialErrorMessage = '当前动态凭证模式暂不支持页面刷新'
      return false
    }
    if (this.isRefreshingDynamicCredential) return false

    this.isRefreshingDynamicCredential = true
    this.dynamicCredentialErrorMessage = ''
    try {
      const value: DynamicCredentialVO = await this.fulfillmentRepository.refreshDynamicCredential(
        this.orderId, ticket.ticketId, this.userId)
      this.dynamicCredentialPayload = value.credentialPayload
      this.dynamicCredentialExpiresAt = value.expiresAt
      this.dynamicRefreshAfterSeconds = value.refreshAfterSeconds
      this.isRefreshingDynamicCredential = false
      return true
    } catch (error) {
      this.dynamicCredentialPayload = ''
      this.dynamicCredentialExpiresAt = ''
      this.dynamicRefreshAfterSeconds = 0
      this.dynamicCredentialErrorMessage = this.message(error, '动态二维码刷新失败，请稍后重试')
      this.isRefreshingDynamicCredential = false
      return false
    }
  }

  getCurrentTicket(): ElectronicTicketVO | undefined {
    if (this.pageVO === undefined || this.pageVO.tickets.length === 0) return undefined
    if (this.currentIndex < 0 || this.currentIndex >= this.pageVO.tickets.length) return undefined
    return this.pageVO.tickets[this.currentIndex]
  }

  switchToPreviousTicket(): boolean {
    if (!this.canSwitchPrevious()) return false
    this.currentIndex--
    this.updateCurrentTicketId()
    this.clearDynamicCredential()
    return true
  }

  switchToNextTicket(): boolean {
    if (!this.canSwitchNext()) return false
    this.currentIndex++
    this.updateCurrentTicketId()
    this.clearDynamicCredential()
    return true
  }

  getTicketCodeDisplayState(ticket: ElectronicTicketVO | undefined): TicketCodeDisplayState {
    if (ticket === undefined) return this.placeholder('无票信息', '当前电子票信息不存在', '暂无电子票信息')

    if (ticket.ticketStatus === TicketStatus.GENERATING) {
      return this.placeholder('生成中', '订单已支付，但入场凭证暂未生成', '入场凭证生成中')
    }
    if (ticket.ticketStatus === TicketStatus.ERROR) {
      return this.placeholder('异常', ticket.abnormalReason ?? '票信息获取失败或凭证异常', '票凭证异常')
    }

    const inactive: boolean = ticket.ticketStatus === TicketStatus.CHECKED || ticket.ticketStatus === TicketStatus.EXPIRED
    const statusText: string = ticket.ticketStatus === TicketStatus.UNUSED ? '未使用' :
      (ticket.ticketStatus === TicketStatus.CHECKED ? '已检票' : '已失效')
    const overlay: string = ticket.ticketStatus === TicketStatus.EXPIRED ? '已失效' : ''
    const type: CredentialType | undefined = ticket.credentialType

    if (type === 'DYNAMIC_QR') {
      if (ticket.dynamicQrMode === 'PROVIDER_WALLET') {
        return this.textState(statusText, '请按出票方要求在官方票夹中查看动态入场凭证', '官方票夹动态凭证', '请前往官方票夹查看', inactive, overlay, false)
      }
      const payload: string = inactive ? '' : this.dynamicCredentialPayload
      return {
        statusText: statusText,
        tipText: inactive ? '该票已不可用于入场' : '动态二维码会定期变化，请在入场前刷新',
        displayMode: payload.length > 0 ? 'QR' : 'PLACEHOLDER',
        credentialTitle: '动态二维码',
        credentialText: '',
        showQRCode: payload.length > 0,
        qrCodeValue: payload,
        showPlaceholder: payload.length === 0,
        placeholderText: inactive ? '该电子票已不可用' : '点击下方按钮刷新动态二维码',
        grayQRCode: inactive,
        showOverlay: overlay.length > 0,
        overlayText: overlay,
        canUseForEntry: !inactive && payload.length > 0,
        canRefreshDynamic: !inactive && ticket.dynamicQrMode === 'REMOTE_REFRESH'
      }
    }

    if (type === 'ID_CARD') {
      return this.textState(statusText, inactive ? '该票已不可用于入场' : '请携带购票时绑定的有效身份证件入场', '身份证入场', ticket.maskedCertificateNo, inactive, overlay, !inactive, 'ID_CARD')
    }

    const displayValue: string = ticket.credentialDisplayValue ?? ticket.qrCodeValue ?? ''
    if (type === 'STATIC_QR') {
      return this.qrState(statusText, inactive ? '该二维码已不可用于入场' : '请出示二维码核验入场', displayValue, inactive, overlay)
    }
    if (type === 'SMS_CODE') {
      return this.textState(statusText, inactive ? '该票已不可用于入场' : '请按现场核验要求出示短信凭证', '短信凭证', displayValue, inactive, overlay, !inactive)
    }
    if (type === 'EXCHANGE_CODE') {
      return this.textState(statusText, inactive ? '该票已不可用于入场' : '请按演出场馆现场指引使用兑换码', '兑换码', displayValue, inactive, overlay, !inactive)
    }
    if (type === 'URL') {
      return this.textState(statusText, '请按页面提示使用入场链接', '入场链接', displayValue, inactive, overlay, !inactive)
    }
    if (type === 'TEXT') {
      return this.textState(statusText, '请按页面提示使用入场凭证', '入场凭证', displayValue, inactive, overlay, !inactive)
    }

    return this.placeholder(statusText, inactive ? '该票已不可用于入场' : '入场凭证暂不可用', inactive ? '该电子票已不可用' : '凭证暂未生成')
  }

  getCurrentTicketCodeDisplayState(): TicketCodeDisplayState { return this.getTicketCodeDisplayState(this.getCurrentTicket()) }
  canSwitchPrevious(): boolean { return this.pageVO !== undefined && this.pageVO.tickets.length > 1 && this.currentIndex > 0 }
  canSwitchNext(): boolean { return this.pageVO !== undefined && this.pageVO.tickets.length > 1 && this.currentIndex < this.pageVO.tickets.length - 1 }

  async mockIssueSuccess(): Promise<void> { if (this.orderId.length > 0 && await this.ticketRepository.mockIssueSuccess(this.orderId)) await this.refresh() }
  async mockIssueFailed(): Promise<void> { if (this.orderId.length > 0 && await this.ticketRepository.mockIssueFailed(this.orderId)) await this.refresh() }
  async mockCheckCurrentTicket(): Promise<void> {
    const ticket: ElectronicTicketVO | undefined = this.getCurrentTicket()
    if (ticket !== undefined && await this.ticketRepository.mockCheckTicket(ticket.ticketId)) await this.refresh()
  }

  clearError(): void { this.errorMessage = '' }

  private clearDynamicCredential(): void {
    this.dynamicCredentialPayload = ''
    this.dynamicCredentialExpiresAt = ''
    this.dynamicRefreshAfterSeconds = 0
    this.dynamicCredentialErrorMessage = ''
  }

  private findInitialIndex(ticketId: string): number {
    if (this.pageVO === undefined || this.pageVO.tickets.length === 0) return 0
    if (ticketId.length > 0) {
      const index: number = this.pageVO.tickets.findIndex((item: ElectronicTicketVO) => item.ticketId === ticketId)
      if (index >= 0) return index
    }
    const usableIndex: number = this.pageVO.tickets.findIndex((item: ElectronicTicketVO) => item.ticketStatus === TicketStatus.UNUSED)
    return usableIndex >= 0 ? usableIndex : 0
  }

  private updateCurrentTicketId(): void {
    const ticket: ElectronicTicketVO | undefined = this.getCurrentTicket()
    this.currentTicketId = ticket === undefined ? '' : ticket.ticketId
  }

  private qrState(statusText: string, tipText: string, value: string, inactive: boolean, overlay: string): TicketCodeDisplayState {
    return {
      statusText: statusText, tipText: tipText, displayMode: value.length > 0 ? 'QR' : 'PLACEHOLDER',
      credentialTitle: '二维码入场凭证', credentialText: '', showQRCode: value.length > 0, qrCodeValue: value,
      showPlaceholder: value.length === 0, placeholderText: value.length > 0 ? '' : '二维码暂不可用', grayQRCode: inactive,
      showOverlay: overlay.length > 0, overlayText: overlay, canUseForEntry: !inactive && value.length > 0, canRefreshDynamic: false
    }
  }

  private textState(statusText: string, tipText: string, title: string, value: string, inactive: boolean,
                    overlay: string, canUse: boolean, mode: CredentialDisplayMode = 'TEXT'): TicketCodeDisplayState {
    return {
      statusText: statusText, tipText: tipText, displayMode: mode, credentialTitle: title,
      credentialText: value.length > 0 ? value : '-', showQRCode: false, qrCodeValue: '', showPlaceholder: false,
      placeholderText: '', grayQRCode: inactive, showOverlay: overlay.length > 0, overlayText: overlay,
      canUseForEntry: canUse && !inactive, canRefreshDynamic: false
    }
  }

  private placeholder(statusText: string, tipText: string, text: string): TicketCodeDisplayState {
    return {
      statusText: statusText, tipText: tipText, displayMode: 'PLACEHOLDER', credentialTitle: '', credentialText: '',
      showQRCode: false, qrCodeValue: '', showPlaceholder: true, placeholderText: text, grayQRCode: false,
      showOverlay: false, overlayText: '', canUseForEntry: false, canRefreshDynamic: false
    }
  }

  private message(error: Object, fallback: string): string {
    return error instanceof Error && error.message.length > 0 ? error.message : fallback
  }
}
