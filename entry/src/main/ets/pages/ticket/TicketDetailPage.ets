import router from '@ohos.router'

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
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
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
  @State pageVersion: number = 0
  @StorageLink('ticket_changed_version') @Watch('onTicketChanged') ticketChangedVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentTicketDetail()
  }

  private onTicketChanged(): void {
    this.reloadCurrentTicketDetail()
  }

  private loadPageData(): void {
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
      this.errorMessage = '电子票参数不存在'
      this.syncFromVm()
      return
    }

    this.vm.loadPage(userId, orderId, ticketId)
    this.syncFromVm()
  }

  private reloadCurrentTicketDetail(): void {
    if (this.userId.length === 0 || this.orderId.length === 0) {
      return
    }

    if (!this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.vm.refresh()
    this.syncFromVm()
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
    this.pageVersion++
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
    this.audienceNameText = ticket.audienceName.length > 0 ? ticket.audienceName : '-'
    this.maskedCertificateNoText = ticket.maskedCertificateNo.length > 0 ? ticket.maskedCertificateNo : '-'
    this.certificateTypeText = this.getCertificateTypeText(ticket.certificateType)
    this.skuNameText = ticket.skuName.length > 0 ? ticket.skuName : '-'
    this.seatInfoText = ticket.seatInfo !== undefined && ticket.seatInfo.length > 0 ? ticket.seatInfo : '暂无座位信息'
  }

  build() {
    Column() {
      this.TopBar()

      if (this.pageVO === undefined) {
        this.EmptyArea()
      } else {
        Scroll() {
          Column() {
            this.PerformanceArea(this.pageVO)
            this.TicketArea()
            this.CustomerServiceArea(this.pageVO)
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

      Text('电子票详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '电子票详情不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private PerformanceArea(pageVO: TicketDetailPageVO) {
    Row() {
      Image(MediaResourceUtil.getMedia(pageVO.posterUrl))
        .width(80)
        .height(108)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column() {
        Text(pageVO.projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
          .width('100%')

        Text(pageVO.startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })
          .textAlign(TextAlign.Start)
          .width('100%')

        Text(pageVO.venueName)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })
          .textAlign(TextAlign.Start)
          .width('100%')
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
        this.TicketInfoArea(this.currentTicket, this.displayState.statusText)
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

      Text('请携带与该电子票绑定的观演人证件入场')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 12, bottom:12 })

      if (this.displayState.showQRCode) {
        Stack() {
          Column() {
            Text('二维码入场凭证')
              .fontSize(14)
              .fontColor(this.displayState.grayQRCode ? '#999999' : '#666666')

            Text(this.displayState.qrCodeValue)
              .fontSize(16)
              .fontColor(this.displayState.grayQRCode ? '#999999' : '#222222')
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16 })
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width(220)
          .height(220)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.displayState.grayQRCode ? '#EAEAEA' : '#F7F7F7')
          .borderRadius(12)
          .opacity(this.displayState.grayQRCode ? 0.55 : 1)

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
        .width(220)
        .height(220)
      } else {
        Column() {
          Text(this.displayState.placeholderText)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#999999')

          if (this.getAbnormalReasonText().length > 0) {
            Text(this.getAbnormalReasonText())
              .fontSize(13)
              .fontColor('#999999')
              .margin({ top: 10 })
              .textAlign(TextAlign.Center)
          }
        }
        .width(220)
        .height(220)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#EEEEEE')
        .borderRadius(12)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 18, bottom: 8 })
  }

  @Builder
  private TicketInfoArea(ticket: ElectronicTicketVO | undefined, statusText: string) {
    Column() {
      this.InfoRow('观演人', this.getTicketAudienceName(ticket))
      this.InfoRow('证件类型', this.getTicketCertificateTypeText(ticket))
      this.InfoRow('证件号', this.getTicketMaskedCertificateNo(ticket))

      this.InfoRow('票档', this.getTicketSkuName(ticket))
      this.InfoRow('座位', this.getTicketSeatInfo(ticket))
      this.InfoRow('票状态', statusText)

    }
    .width('100%')
    .padding({ top: 12 })
  }

  @Builder
  private CustomerServiceArea(pageVO: TicketDetailPageVO) {
    Column() {
      Text('联系客服')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Text(pageVO.customerServicePhone ?? '暂无客服电话')
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
    this.vm.switchToPreviousTicket()
    this.syncFromVm()
  }

  private switchToNextTicket(): void {
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
    if (this.currentTicket === undefined || this.currentTicket.abnormalReason === undefined ||
      this.currentTicket.abnormalReason.length === 0) {
      return ''
    }

    return this.currentTicket.abnormalReason
  }

  private getTicketAudienceName(ticket: ElectronicTicketVO | undefined): string {
    if (ticket === undefined || ticket.audienceName.length === 0) {
      return '-'
    }

    return ticket.audienceName
  }

  private getTicketCertificateTypeText(ticket: ElectronicTicketVO | undefined): string {
    if (ticket === undefined) {
      return '-'
    }

    return this.getCertificateTypeText(ticket.certificateType)
  }

  private getTicketMaskedCertificateNo(ticket: ElectronicTicketVO | undefined): string {
    if (ticket === undefined || ticket.maskedCertificateNo.length === 0) {
      return '-'
    }

    return ticket.maskedCertificateNo
  }

  private getTicketSkuName(ticket: ElectronicTicketVO | undefined): string {
    if (ticket === undefined || ticket.skuName.length === 0) {
      return '-'
    }

    return ticket.skuName
  }

  private getTicketSeatInfo(ticket: ElectronicTicketVO | undefined): string {
    if (ticket === undefined || ticket.seatInfo === undefined || ticket.seatInfo.length === 0) {
      return '暂无座位信息'
    }

    return ticket.seatInfo
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
      qrCodeValue: ticket.qrCodeValue,
      skuName: ticket.skuName,
      seatInfo: ticket.seatInfo,
      audienceName: ticket.audienceName,
      certificateType: ticket.certificateType,
      maskedCertificateNo: ticket.maskedCertificateNo,
      abnormalReason: ticket.abnormalReason
    }
  }

  private createEmptyDisplayState(): TicketCodeDisplayState {
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

  private getAudienceName(): string {
    return this.audienceNameText
  }

  private getMaskedCertificateNo(): string {
    return this.maskedCertificateNoText
  }
}
