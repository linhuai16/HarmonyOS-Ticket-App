import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { common } from '@kit.AbilityKit'

import {
  TicketDetailPageVO,
  ElectronicTicketVO
} from '../../model/vo/ticket/TicketDetailPageVO'

import {
  TicketDetailViewModel,
  TicketCodeDisplayState
} from '../../viewmodel/TicketDetailViewModel'

import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { CertificateType } from '../../model/enums/CertificateType'
import { TicketStatus } from '../../model/enums/TicketStatus'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ShipmentVO } from '../../model/vo/ticketsource/ShipmentVO'
import { VenueNavigationUtil } from '../../utils/VenueNavigationUtil'
interface TicketDetailRouteParams {
  userId?: string
  orderId?: string
  ticketId?: string
}


@Entry
@Component
struct TicketDetailPage {
  private vm: TicketDetailViewModel = new TicketDetailViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVO: TicketDetailPageVO | undefined = undefined
  @State currentTicket: ElectronicTicketVO | undefined = undefined
  @State currentTicketIdValue: string = ''
  @State ticketIndexText: string = '0/0 张'
  @State audienceNameText: string = '-'
  @State maskedCertificateNoText: string = '-'
  @State certificateTypeText: string = '-'
  @State skuNameText: string = '-'
  @State seatInfoText: string = '暂无座位信息'
  @State displayState: TicketCodeDisplayState = this.createEmptyDisplayState()
  @State userId: string = ''
  @State orderId: string = ''
  @State canSwitchPreviousValue: boolean = false
  @State canSwitchNextValue: boolean = false
  @State errorMessage: string = ''
  @State shipmentVO: ShipmentVO | undefined = undefined
  @State shipmentErrorMessage: string = ''
  @State dynamicCredentialErrorMessage: string = ''
  @State dynamicCredentialExpiresAt: string = ''
  @State dynamicRefreshAfterSeconds: number = 0
  @State isRefreshingDynamicCredential: boolean = false
  @State isRefreshingShipment: boolean = false
  @State isRefreshingPage: boolean = false
  @State pageVersion: number = 0
  @StorageLink('ticket_changed_version') @Watch('onTicketChanged') ticketChangedVersion: number = 0
  @StorageLink('refund_changed_version') @Watch('onTicketChanged') refundChangedVersion: number = 0
  @StorageLink('shipment_changed_version') @Watch('onTicketChanged') shipmentChangedVersion: number = 0
  @StorageLink('order_changed_version') @Watch('onTicketChanged') orderChangedVersion: number = 0
  private dynamicRefreshTimerId: number = -1
  private stateRefreshTimerId: number = -1
  private isReloadingPage: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  aboutToDisappear(): void {
    this.stopDynamicRefreshTimer()
    this.stopStateRefreshTimer()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentTicketDetail()
  }

  private onTicketChanged(): void {
    this.reloadCurrentTicketDetail()
  }

  private async loadPageData(): Promise<void> {
    const params: TicketDetailRouteParams | undefined = router.getParams() as TicketDetailRouteParams | undefined
    const routeUserId: string = params?.userId ?? ''
    const currentUserId: string = this.userRepository.getCurrentUserId()
    const userId: string = routeUserId.length > 0 ? routeUserId : currentUserId
    const orderId: string = params?.orderId ?? ''
    const ticketId: string = params?.ticketId ?? ''

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    if (orderId.length === 0) {
      this.errorMessage = '票夹详情参数不存在'
      this.syncFromVm()
      return
    }

    await this.vm.loadPage(userId, orderId, ticketId)
    this.syncFromVm()
  }

  private async reloadCurrentTicketDetail(): Promise<void> {
    if (this.userId.length === 0 || this.orderId.length === 0 || this.isReloadingPage) {
      return
    }
    this.stopDynamicRefreshTimer()

    if (!this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.isReloadingPage = true
    try {
      await this.vm.refresh()
      this.syncFromVm()
    } finally {
      this.isReloadingPage = false
    }
  }

  private async manualRefreshPage(): Promise<void> {
    if (this.isRefreshingPage) return
    this.isRefreshingPage = true
    await this.reloadCurrentTicketDetail()
    this.isRefreshingPage = false
    promptAction.showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '票务状态已刷新' })
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.orderId = this.vm.orderId
    this.pageVO = this.clonePageVO(this.vm.pageVO)
    this.currentTicket = this.cloneTicket(this.vm.getCurrentTicket())
    this.syncCurrentTicketDisplayFields()
    this.displayState = this.vm.getTicketCodeDisplayState(this.currentTicket)
    this.canSwitchPreviousValue = this.vm.canSwitchPrevious()
    this.canSwitchNextValue = this.vm.canSwitchNext()
    this.errorMessage = this.vm.errorMessage
    this.shipmentVO = this.cloneShipment(this.vm.shipmentVO)
    this.shipmentErrorMessage = this.vm.shipmentErrorMessage
    this.dynamicCredentialErrorMessage = this.vm.dynamicCredentialErrorMessage
    this.dynamicCredentialExpiresAt = this.vm.dynamicCredentialExpiresAt
    this.dynamicRefreshAfterSeconds = this.vm.dynamicRefreshAfterSeconds
    this.isRefreshingDynamicCredential = this.vm.isRefreshingDynamicCredential
    this.isRefreshingShipment = this.vm.isRefreshingShipment
    this.pageVersion++
    this.startStateRefreshTimerIfNeeded()
  }

  private syncCurrentTicketDisplayFields(): void {
    const ticket: ElectronicTicketVO | undefined = this.currentTicket

    if (ticket === undefined) {
      this.currentTicketIdValue = ''
      this.ticketIndexText = '0/0 张'
      this.audienceNameText = '-'
      this.maskedCertificateNoText = '-'
      this.certificateTypeText = '-'
      this.skuNameText = '-'
      this.seatInfoText = '暂无座位信息'
      return
    }

    this.currentTicketIdValue = ticket.ticketId
    this.ticketIndexText = ticket.ticketIndex + '/' + ticket.ticketTotal + ' 张'
    this.audienceNameText = (ticket.audienceName ?? '').length > 0 ? ticket.audienceName : '-'
    this.maskedCertificateNoText = (ticket.maskedCertificateNo ?? '').length > 0 ? ticket.maskedCertificateNo : '-'
    this.certificateTypeText = this.getCertificateTypeText(ticket.certificateType)
    this.skuNameText = (ticket.skuName ?? '').length > 0 ? ticket.skuName : '-'
    this.seatInfoText = (ticket.seatInfo ?? '').length > 0 ? (ticket.seatInfo ?? '') : '暂无座位信息'
  }

  build() {
    Column() {
      this.TopBar()

      if (this.pageVO === undefined) {
        this.EmptyArea()
      } else {
        Scroll() {
          Column() {
            this.PerformanceArea()
            this.RefundStateArea()
            if (this.isPaperTicketPage()) {
              this.PaperTicketArea()
            } else {
              this.TicketArea()
            }
            this.CustomerServiceArea()
            Blank().height(24)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TopBar() {
    Row() {
      Row() {
        Image($r('app.media.fanhui'))
          .width(22)
          .height(22)
      }
      .width(40)
      .height(52)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        router.back()
      })

      Text(this.isPaperTicketPage() ? '纸质票详情' : '电子票详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')

      Blank()
      Text(this.isRefreshingPage ? '刷新中' : '刷新')
        .fontSize(14)
        .fontColor(this.isRefreshingPage ? '#BBBBBB' : '#E33B3B')
        .height(44)
        .padding({ left: 10, right: 4 })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (!this.isRefreshingPage) this.manualRefreshPage()
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '票夹详情不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private PerformanceArea() {
    Row() {
      Image(MediaResourceUtil.getMedia((this.pageVO as TicketDetailPageVO).posterUrl))
        .width(80)
        .height(108)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column() {
        Text((this.pageVO as TicketDetailPageVO).projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
          .width('100%')

        Text((this.pageVO as TicketDetailPageVO).startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })
          .textAlign(TextAlign.Start)
          .width('100%')

        Text((this.pageVO as TicketDetailPageVO).venueName)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })
          .textAlign(TextAlign.Start)
          .width('100%')

        Text('导航到场馆 >')
          .fontSize(13)
          .fontColor('#E33B3B')
          .margin({ top: 6 })
          .onClick(() => {
            this.openVenueNavigation((this.pageVO as TicketDetailPageVO))
          })
      }
      .layoutWeight(1)
      .height(108)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private TicketArea() {
    Column() {
      Row() {
        this.SwitchButton(false)

        Text(this.getTicketIndexText())
          .fontSize(15)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        this.SwitchButton(true)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)



      this.TicketCodeCard()

      Text(this.displayState.tipText)
        .fontSize(13)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 8 })

      ForEach([`${this.currentTicketIdValue}_${this.pageVersion}`], (ticketKey: string) => {
        this.TicketInfoArea()
      }, (ticketKey: string) => ticketKey)
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private SwitchButton(isNext: boolean) {
    Row() {
      Image(isNext ? $r('app.media.you') : $r('app.media.fanhui'))
        .width(20)
        .height(20)
    }
    .width(40)
    .height(40)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F2F2F2')
    .borderRadius(20)
    .opacity(this.canSwitchButton(isNext) ? 1 : 0.35)
    .onClick(() => {
      if (isNext) {
        this.switchToNextTicket()
      } else {
        this.switchToPreviousTicket()
      }
    })
  }

  @Builder
  private TicketCodeCard() {
    Column() {
      Text('请按当前凭证类型和页面提示完成入场核验')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 12, bottom: 12 })

      if (this.displayState.displayMode === 'QR' && this.displayState.qrCodeValue.length > 0) {
        Stack() {
          Column() {
            Text(this.displayState.credentialTitle)
              .fontSize(14)
              .fontColor(this.displayState.grayQRCode ? '#999999' : '#666666')

            QRCode(this.displayState.qrCodeValue)
              .width(190)
              .height(190)
              .margin({ top: 10 })
              .opacity(this.displayState.grayQRCode ? 0.35 : 1)
          }
          .width(230)
          .height(240)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          if (this.displayState.showOverlay) {
            Text(this.displayState.overlayText)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor('rgba(0,0,0,0.45)')
              .padding({ left: 18, right: 18, top: 8, bottom: 8 })
              .borderRadius(8)
          }
        }
        .width(230)
        .height(240)
      } else if (this.displayState.displayMode === 'TEXT' || this.displayState.displayMode === 'ID_CARD') {
        Column() {
          Text(this.displayState.credentialTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(this.displayState.credentialText)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.displayState.grayQRCode ? '#999999' : '#222222')
            .margin({ top: 16 })
            .maxLines(4)
            .textAlign(TextAlign.Center)
        }
        .width(230)
        .height(180)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F7F7F7')
        .borderRadius(12)
      } else {
        Column() {
          Text(this.displayState.placeholderText)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)

          if (this.getAbnormalReasonText().length > 0) {
            Text(this.getAbnormalReasonText())
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 10 })
              .textAlign(TextAlign.Center)
          }
        }
        .width(230)
        .height(180)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#EEEEEE')
        .borderRadius(12)
      }

      if (this.displayState.canRefreshDynamic) {
        Button(this.isRefreshingDynamicCredential ? '刷新中...' : '刷新动态二维码')
          .height(36)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#E33B3B')
          .borderRadius(18)
          .enabled(!this.isRefreshingDynamicCredential)
          .margin({ top: 12 })
          .onClick(() => {
            this.refreshDynamicCredential()
          })
      }

      if (this.dynamicCredentialExpiresAt.length > 0) {
        Text('本次动态码有效至：' + this.dynamicCredentialExpiresAt)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 8 })
      }

      if (this.dynamicCredentialErrorMessage.length > 0) {
        Text(this.dynamicCredentialErrorMessage)
          .fontSize(12)
          .fontColor('#E33B3B')
          .margin({ top: 8 })
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 18, bottom: 8 })
  }

  @Builder
  private TicketInfoArea() {
    Column() {
      this.InfoRow('观演人', this.getTicketAudienceName(this.currentTicket))
      this.InfoRow('证件类型', this.getTicketCertificateTypeText(this.currentTicket))
      this.InfoRow('证件号', this.getTicketMaskedCertificateNo(this.currentTicket))

      this.InfoRow('票档', this.getTicketSkuName(this.currentTicket))
      this.InfoRow('座位', this.getTicketSeatInfo(this.currentTicket))
      this.InfoRow('票状态', this.displayState.statusText)

    }
    .width('100%')
    .padding({ top: 12 })
  }

  @Builder
  private PaperTicketArea() {
    if ((this.pageVO as TicketDetailPageVO).deliveryMode === 'EXPRESS') {
      this.PaperExpressArea()
    } else {
      this.PaperSelfPickupArea()
    }
  }

  @Builder
  private PaperSelfPickupArea() {
    Column() {
      Text('现场取票')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Text('本订单为纸质票，请于演出当天提前到演出场馆现场领取。')
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 10 })

      this.InfoRow('取票方式', '现场取票')
      this.InfoRow('取票地点', '演出场馆')
      this.InfoRow('场馆', (this.pageVO as TicketDetailPageVO).venueName)
      this.InfoRow('场馆地址', (this.pageVO as TicketDetailPageVO).venueAddress.length > 0 ? (this.pageVO as TicketDetailPageVO).venueAddress : '-')
      this.InfoRow('纸质票数量', (this.pageVO as TicketDetailPageVO).totalQuantity + ' 张')

      Text('取票说明')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .margin({ top: 10 })

      Text('请根据演出场馆当天的现场票务指引领取纸质票。本系统不再展示或要求选择固定取票点。')
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 6 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private PaperExpressArea() {
    Column() {
      Text('物流信息')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      this.InfoRow('配送方式', '快递纸质票')
      this.InfoRow('纸质票数量', (this.pageVO as TicketDetailPageVO).totalQuantity + ' 张')

      if (this.shipmentVO === undefined) {
        Text(this.shipmentErrorMessage.length > 0 ? this.shipmentErrorMessage : '物流信息暂未生成，请稍后刷新')
          .fontSize(13)
          .fontColor('#999999')
          .width('100%')
          .margin({ top: 12 })
      } else {
        this.InfoRow('物流状态', this.getShipmentStatusText(this.shipmentVO.shipmentStatus, (this.pageVO as TicketDetailPageVO).orderStatus))
        this.InfoRow('快递公司', this.optionalText(this.shipmentVO.carrierName))
        this.InfoRow('运单号', this.optionalText(this.shipmentVO.waybillNo))
        this.InfoRow('发货时间', this.optionalText(this.shipmentVO.shippedTime))
        this.InfoRow('签收时间', this.optionalText(this.shipmentVO.signedTime))
        this.InfoRow('最近同步', this.optionalText(this.shipmentVO.lastSyncTime))

        if (this.shipmentVO.warnings.length > 0) {
          Text(this.shipmentVO.warnings.join('；'))
            .fontSize(12)
            .fontColor('#999999')
            .lineHeight(18)
            .width('100%')
            .margin({ top: 8 })
        }
      }

      Button('刷新物流')
        .height(36)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor('#E33B3B')
        .borderRadius(18)
        .margin({ top: 12 })
        .enabled(!this.isRefreshingShipment && (this.shipmentVO === undefined || this.shipmentVO.canRefresh))
        .onClick(() => {
          this.syncShipment()
        })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private CustomerServiceArea() {
    Column() {
      Text('联系客服')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Text((this.pageVO as TicketDetailPageVO).customerServicePhone ?? '暂无客服电话')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')

      Blank()

      Text(value)
        .fontSize(14)
        .fontColor('#222222')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(34)
  }

  private switchToPreviousTicket(): void {
    this.stopDynamicRefreshTimer()
    this.vm.switchToPreviousTicket()
    this.syncFromVm()
  }

  private switchToNextTicket(): void {
    this.stopDynamicRefreshTimer()
    this.vm.switchToNextTicket()
    this.syncFromVm()
  }

  private canSwitchButton(isNext: boolean): boolean {
    return isNext ? this.canSwitchNextValue : this.canSwitchPreviousValue
  }

  private getTicketIndexText(): string {
    return this.ticketIndexText
  }

  private getSkuName(): string {
    return this.skuNameText
  }

  private getSeatInfo(): string {
    return this.seatInfoText
  }

  private getAbnormalReasonText(): string {
    if (this.currentTicket === undefined) {
      return ''
    }

    const abnormalReason: string = this.currentTicket.abnormalReason ?? ''
    return abnormalReason.length > 0 ? abnormalReason : ''
  }

  private getTicketAudienceName(ticket: ElectronicTicketVO | undefined): string {
    const audienceName: string = ticket?.audienceName ?? ''
    return audienceName.length > 0 ? audienceName : '-'
  }

  private getTicketCertificateTypeText(ticket: ElectronicTicketVO | undefined): string {
    if (ticket === undefined) {
      return '-'
    }

    return this.getCertificateTypeText(ticket.certificateType)
  }

  private getTicketMaskedCertificateNo(ticket: ElectronicTicketVO | undefined): string {
    const maskedCertificateNo: string = ticket?.maskedCertificateNo ?? ''
    return maskedCertificateNo.length > 0 ? maskedCertificateNo : '-'
  }

  private getTicketSkuName(ticket: ElectronicTicketVO | undefined): string {
    const skuName: string = ticket?.skuName ?? ''
    return skuName.length > 0 ? skuName : '-'
  }

  private getTicketSeatInfo(ticket: ElectronicTicketVO | undefined): string {
    const seatInfo: string = ticket?.seatInfo ?? ''
    return seatInfo.length > 0 ? seatInfo : '暂无座位信息'
  }

  private getCertificateTypeText(certificateType?: CertificateType): string {
    if (certificateType === CertificateType.ID_CARD) {
      return '身份证'
    }

    if (certificateType === CertificateType.PASSPORT) {
      return '护照'
    }

    if (certificateType === CertificateType.HK_MACAO_PASS) {
      return '港澳通行证'
    }

    return '-'
  }

  private clonePageVO(pageVO: TicketDetailPageVO | undefined): TicketDetailPageVO | undefined {
    if (pageVO === undefined) {
      return undefined
    }

    const tickets: ElectronicTicketVO[] = pageVO.tickets.map((item: ElectronicTicketVO): ElectronicTicketVO => {
      return this.cloneTicket(item) as ElectronicTicketVO
    })

    return {
      posterUrl: pageVO.posterUrl,
      projectTitle: pageVO.projectTitle,
      startTime: pageVO.startTime,
      venueName: pageVO.venueName,
      venueAddress: pageVO.venueAddress,
      venueLongitude: pageVO.venueLongitude,
      venueLatitude: pageVO.venueLatitude,
      orderStatus: pageVO.orderStatus,
      deliveryType: pageVO.deliveryType,
      deliveryMode: pageVO.deliveryMode,
      totalQuantity: pageVO.totalQuantity,
      tickets: tickets,
      customerServicePhone: pageVO.customerServicePhone
    }
  }

  private cloneTicket(ticket: ElectronicTicketVO | undefined): ElectronicTicketVO | undefined {
    if (ticket === undefined) {
      return undefined
    }

    return {
      ticketId: ticket.ticketId,
      ticketStatus: ticket.ticketStatus,
      ticketIndex: ticket.ticketIndex,
      ticketTotal: ticket.ticketTotal,
      credentialType: ticket.credentialType,
      dynamicQrMode: ticket.dynamicQrMode,
      credentialVersion: ticket.credentialVersion,
      credentialExpireTime: ticket.credentialExpireTime,
      refreshAfterSeconds: ticket.refreshAfterSeconds,
      credentialDisplayValue: ticket.credentialDisplayValue,
      qrCodeValue: ticket.qrCodeValue ?? undefined,
      skuName: ticket.skuName ?? '',
      seatInfo: ticket.seatInfo ?? undefined,
      entranceInfo: ticket.entranceInfo ?? undefined,
      audienceName: ticket.audienceName ?? '',
      certificateType: ticket.certificateType,
      maskedCertificateNo: ticket.maskedCertificateNo ?? '',
      abnormalReason: ticket.abnormalReason ?? undefined
    }
  }

  private startStateRefreshTimerIfNeeded(): void {
    this.stopStateRefreshTimer()
    const refunding: boolean = this.pageVO?.orderStatus === 'REFUNDING'
    const generating: boolean = this.currentTicket?.ticketStatus === TicketStatus.GENERATING
    const shipmentActive: boolean = this.shipmentVO !== undefined &&
      this.shipmentVO.shipmentStatus !== 'DELIVERED' && this.shipmentVO.shipmentStatus !== 'RETURNED' &&
      this.shipmentVO.shipmentStatus !== 'NOT_REQUIRED'
    if (!refunding && !generating && !shipmentActive) return
    this.stateRefreshTimerId = setInterval(() => {
      this.reloadCurrentTicketDetail()
    }, shipmentActive ? 30000 : 15000)
  }

  private stopStateRefreshTimer(): void {
    if (this.stateRefreshTimerId >= 0) {
      clearInterval(this.stateRefreshTimerId)
      this.stateRefreshTimerId = -1
    }
  }

  private async refreshDynamicCredential(): Promise<void> {
    const refreshed: boolean = await this.vm.refreshDynamicCredential()
    this.syncFromVm()
    if (refreshed) {
      this.startDynamicRefreshTimer()
    } else {
      this.stopDynamicRefreshTimer()
    }
  }

  private startDynamicRefreshTimer(): void {
    this.stopDynamicRefreshTimer()
    if (this.dynamicRefreshAfterSeconds <= 0 || this.vm.dynamicCredentialPayload.length === 0) return
    this.dynamicRefreshTimerId = setInterval(() => {
      this.refreshDynamicCredential()
    }, this.dynamicRefreshAfterSeconds * 1000)
  }

  private stopDynamicRefreshTimer(): void {
    if (this.dynamicRefreshTimerId >= 0) {
      clearInterval(this.dynamicRefreshTimerId)
      this.dynamicRefreshTimerId = -1
    }
  }

  private async syncShipment(): Promise<void> {
    await this.vm.syncShipment()
    this.syncFromVm()
  }

  private openVenueNavigation(pageVO: TicketDetailPageVO): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    VenueNavigationUtil.open(context, pageVO.venueName, pageVO.venueAddress, pageVO.venueLatitude, pageVO.venueLongitude)
  }

  @Builder
  private RefundStateArea() {
    if ((this.pageVO as TicketDetailPageVO).orderStatus === 'REFUNDING' || (this.pageVO as TicketDetailPageVO).orderStatus === 'REFUND_SUCCESS') {
      Column() {
        Text((this.pageVO as TicketDetailPageVO).orderStatus === 'REFUNDING' ? '退款处理中' : '退款已完成')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor((this.pageVO as TicketDetailPageVO).orderStatus === 'REFUNDING' ? '#C07A00' : '#666666')
        Text((this.pageVO as TicketDetailPageVO).orderStatus === 'REFUNDING' ? '退款期间票凭证暂不可使用，请在订单详情查看退款进度。' : '该订单已退款，原票凭证不可再使用。')
          .fontSize(13)
          .fontColor('#777777')
          .margin({ top: 6 })
      }
      .width('100%')
      .padding(12)
      .margin({ top: 12 })
      .backgroundColor('#FFF8E8')
      .borderRadius(12)
    }
  }

  private isPaperTicketPage(): boolean {
    return this.pageVO?.deliveryType === 'PAPER_TICKET'
  }

  private cloneShipment(shipment: ShipmentVO | undefined): ShipmentVO | undefined {
    if (shipment === undefined) {
      return undefined
    }
    return {
      orderId: shipment.orderId,
      orderNo: shipment.orderNo,
      deliveryType: shipment.deliveryType,
      deliveryFee: {
        amountMinor: shipment.deliveryFee.amountMinor,
        currency: shipment.deliveryFee.currency
      },
      shipmentStatus: shipment.shipmentStatus,
      carrierName: shipment.carrierName,
      waybillNo: shipment.waybillNo,
      trackingUrl: shipment.trackingUrl,
      shippedTime: shipment.shippedTime,
      signedTime: shipment.signedTime,
      lastSyncTime: shipment.lastSyncTime,
      canRefresh: shipment.canRefresh,
      deliveryFeeRefundableHint: shipment.deliveryFeeRefundableHint,
      deliveryFeeRefundHint: shipment.deliveryFeeRefundHint,
      lastSyncStatus: shipment.lastSyncStatus,
      warnings: shipment.warnings.slice()
    }
  }

  private getShipmentStatusText(status: string, orderStatus: string = ''): string {
    if (orderStatus === 'REFUND_SUCCESS' && (status === 'WAIT_SHIPMENT' || status === 'NOT_REQUIRED')) {
      return '已退款，物流已关闭'
    }
    if (status === 'WAIT_SHIPMENT') return '待发货'
    if (status === 'SHIPPED') return '已发货'
    if (status === 'IN_TRANSIT') return '运输中'
    if (status === 'DELIVERED') return '已签收'
    if (status === 'EXCEPTION') return '物流异常'
    if (status === 'RETURNED') return '已退回'
    if (status === 'NOT_REQUIRED') return '无需物流'
    return status.length > 0 ? status : '-'
  }

  private optionalText(value: string | undefined): string {
    return value !== undefined && value.length > 0 ? value : '-'
  }

  private createEmptyDisplayState(): TicketCodeDisplayState {
    return {
      statusText: '无票信息',
      tipText: '当前电子票信息不存在',
      displayMode: 'PLACEHOLDER',
      credentialTitle: '',
      credentialText: '',
      showQRCode: false,
      qrCodeValue: '',
      showPlaceholder: true,
      placeholderText: '暂无电子票信息',
      grayQRCode: false,
      showOverlay: false,
      overlayText: '',
      canUseForEntry: false,
      canRefreshDynamic: false
    }
  }

  private getAudienceName(): string {
    return this.audienceNameText
  }

  private getMaskedCertificateNo(): string {
    return this.maskedCertificateNoText
  }
}
