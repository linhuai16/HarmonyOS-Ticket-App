import {
  TicketDetailPageVO,
  ElectronicTicketVO
} from '../model/vo/ticket/TicketDetailPageVO'

import { TicketRepository } from '../repository/TicketRepository'
import { TicketStatus } from '../model/enums/TicketStatus'

export interface TicketCodeDisplayState {
  /** 状态标题，如：生成中 / 未使用 / 已检票 / 已失效 / 异常 */
  statusText: string

  /** 电子票码区域下方提示文案 */
  tipText: string

  /** 是否展示二维码 */
  showQRCode: boolean

  /** 二维码内容 */
  qrCodeValue: string

  /** 是否展示占位区域 */
  showPlaceholder: boolean

  /** 占位文案 */
  placeholderText: string

  /** 是否将二维码置灰 */
  grayQRCode: boolean

  /** 是否展示覆盖层 */
  showOverlay: boolean

  /** 覆盖层文案，如：已失效 */
  overlayText: string

  /** 是否是真正可用于入场的票码 */
  canUseForEntry: boolean
}
/**
 
 */
export class TicketDetailViewModel {
  pageVO: TicketDetailPageVO | undefined = undefined

  userId: string = ''
  orderId: string = ''
  currentTicketId: string = ''

  currentIndex: number = 0

  isLoading: boolean = false
  errorMessage: string = ''

  private ticketRepository: TicketRepository = new TicketRepository()

  loadPage(userId: string, orderId: string, ticketId: string = ''): void {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    this.orderId = orderId

    const pageVO: TicketDetailPageVO | undefined =
      this.ticketRepository.getTicketDetailPage(
        userId,
        orderId,
        ticketId.length === 0 ? undefined : ticketId
      )

    if (pageVO === undefined) {
      this.pageVO = undefined
      this.currentIndex = 0
      this.currentTicketId = ''
      this.errorMessage = '电子票详情不存在'
      this.isLoading = false
      return
    }

    this.pageVO = pageVO
    this.currentIndex = this.findInitialIndex(ticketId)
    this.updateCurrentTicketId()

    this.isLoading = false
  }

  refresh(): void {
    if (this.userId.length === 0 || this.orderId.length === 0) {
      return
    }

    this.loadPage(this.userId, this.orderId, this.currentTicketId)
  }

  getCurrentTicket(): ElectronicTicketVO | undefined {
    if (this.pageVO === undefined || this.pageVO.tickets.length === 0) {
      return undefined
    }

    if (this.currentIndex < 0 || this.currentIndex >= this.pageVO.tickets.length) {
      return undefined
    }

    return this.pageVO.tickets[this.currentIndex]
  }

  switchToPreviousTicket(): boolean {
    if (!this.canSwitchPrevious()) {
      return false
    }

    this.currentIndex--
    this.updateCurrentTicketId()
    return true
  }

  //根据票状态进行提示
  getTicketCodeDisplayState(ticket: ElectronicTicketVO | undefined): TicketCodeDisplayState {
    if (ticket === undefined) {
      return {
        statusText: '无票信息',
        tipText: '当前电子票信息不存在',
        showQRCode: false,
        qrCodeValue: '',
        showPlaceholder: true,
        placeholderText: '暂无电子票信息',
        grayQRCode: false,
        showOverlay: false,
        overlayText: '',
        canUseForEntry: false
      }
    }

    const hasCode: boolean =
      ticket.qrCodeValue !== undefined && ticket.qrCodeValue.length > 0

    switch (ticket.ticketStatus) {
      case TicketStatus.GENERATING:
        return {
          statusText: '生成中',
          tipText: '订单已支付，但二维码暂未生成',
          showQRCode: false,
          qrCodeValue: '',
          showPlaceholder: true,
          placeholderText: '二维码生成中',
          grayQRCode: false,
          showOverlay: false,
          overlayText: '',
          canUseForEntry: false
        }

      case TicketStatus.UNUSED:
        return {
          statusText: '未使用',
          tipText: '二维码已生成，未核验',
          showQRCode: hasCode,
          qrCodeValue: ticket.qrCodeValue ?? '',
          showPlaceholder: !hasCode,
          placeholderText: hasCode ? '' : '二维码暂不可用',
          grayQRCode: false,
          showOverlay: false,
          overlayText: '',
          canUseForEntry: hasCode
        }

      case TicketStatus.CHECKED:
        return {
          statusText: '已检票',
          tipText: '二维码已核验入场',
          showQRCode: hasCode,
          qrCodeValue: ticket.qrCodeValue ?? '',
          showPlaceholder: !hasCode,
          placeholderText: hasCode ? '' : '该电子票已检票',
          grayQRCode: true,
          showOverlay: false,
          overlayText: '',
          canUseForEntry: false
        }

      case TicketStatus.EXPIRED:
        return {
          statusText: '已失效',
          tipText: '超过演出时间未使用 / 票不可用 / 已退款',
          showQRCode: hasCode,
          qrCodeValue: ticket.qrCodeValue ?? '',
          showPlaceholder: !hasCode,
          placeholderText: hasCode ? '' : '该电子票已失效',
          grayQRCode: true,
          showOverlay: true,
          overlayText: '已失效',
          canUseForEntry: false
        }

      case TicketStatus.ERROR:
        return {
          statusText: '异常',
          tipText: ticket.abnormalReason ?? '二维码获取失败或票信息异常',
          showQRCode: false,
          qrCodeValue: '',
          showPlaceholder: true,
          placeholderText: '票码异常',
          grayQRCode: false,
          showOverlay: false,
          overlayText: '',
          canUseForEntry: false
        }

      default:
        return {
          statusText: '未知状态',
          tipText: '当前电子票状态异常',
          showQRCode: false,
          qrCodeValue: '',
          showPlaceholder: true,
          placeholderText: '暂无可用票码',
          grayQRCode: false,
          showOverlay: false,
          overlayText: '',
          canUseForEntry: false
        }
    }
  }

  switchToNextTicket(): boolean {
    if (!this.canSwitchNext()) {
      return false
    }

    this.currentIndex++
    this.updateCurrentTicketId()
    return true
  }

  canSwitchPrevious(): boolean {
    if (this.pageVO === undefined || this.pageVO.tickets.length <= 1) {
      return false
    }

    return this.currentIndex > 0
  }

  canSwitchNext(): boolean {
    if (this.pageVO === undefined || this.pageVO.tickets.length <= 1) {
      return false
    }

    return this.currentIndex < this.pageVO.tickets.length - 1
  }


  mockIssueSuccess(): void {
    if (this.orderId.length === 0) {
      return
    }

    const success: boolean = this.ticketRepository.mockIssueSuccess(this.orderId)

    if (success) {
      this.refresh()
    }
  }

  mockIssueFailed(): void {
    if (this.orderId.length === 0) {
      return
    }

    const success: boolean = this.ticketRepository.mockIssueFailed(this.orderId)

    if (success) {
      this.refresh()
    }
  }

  mockCheckCurrentTicket(): void {
    const ticket: ElectronicTicketVO | undefined = this.getCurrentTicket()

    if (ticket === undefined) {
      return
    }

    const success: boolean = this.ticketRepository.mockCheckTicket(ticket.ticketId)

    if (success) {
      this.refresh()
    }
  }



  clearError(): void {
    this.errorMessage = ''
  }

  private findInitialIndex(ticketId: string): number {
    if (this.pageVO === undefined || this.pageVO.tickets.length === 0) {
      return 0
    }

    if (ticketId.length > 0) {
      const index: number = this.pageVO.tickets.findIndex((item: ElectronicTicketVO) => {
        return item.ticketId === ticketId
      })

      if (index >= 0) {
        return index
      }
    }

    const usableIndex: number = this.pageVO.tickets.findIndex((item: ElectronicTicketVO) => {
      return item.ticketStatus === TicketStatus.UNUSED
    })

    if (usableIndex >= 0) {
      return usableIndex
    }

    return 0
  }

  private updateCurrentTicketId(): void {
    const ticket: ElectronicTicketVO | undefined = this.getCurrentTicket()

    if (ticket !== undefined) {
      this.currentTicketId = ticket.ticketId
      return
    }

    this.currentTicketId = ''
  }
  //票状态快捷方法
  getCurrentTicketCodeDisplayState(): TicketCodeDisplayState {
    return this.getTicketCodeDisplayState(this.getCurrentTicket())
  }
}