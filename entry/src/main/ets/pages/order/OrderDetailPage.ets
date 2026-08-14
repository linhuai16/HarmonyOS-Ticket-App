import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  OrderDetailVO,
  OrderDetailItemVO,
  OrderDetailAudienceVO,
  OrderDetailAddressVO
} from '../../model/vo/order/OrderDetailVO'
import {
  OrderDetailViewModel,
  TicketDetailJumpParams,
  RefundApplyJumpParams
} from '../../viewmodel/OrderDetailViewModel'
import { OrderStatus } from '../../model/enums/OrderStatus'
import { DeliveryType } from '../../model/enums/DeliveryType'
import { PayMethod } from '../../model/enums/PayMethod'
import { UserRepository } from '../../repository/UserRepository'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { PayOrderDialog } from '../../common/PayOrderDialog'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface OrderDetailRouteParams {
  userId?: string
  orderId?: string
}


@Entry
@Component
struct OrderDetailPage {
  private vm: OrderDetailViewModel = new OrderDetailViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State userId: string = ''
  @State orderId: string = ''
  @State orderDetailVO: OrderDetailVO | undefined = undefined
  @State errorMessage: string = ''
  @State isLoading: boolean = false
  @State showPayDialog: boolean = false
  @State selectedPayMethod: PayMethod = PayMethod.WECHAT
  @State payRemainText: string = '00:00'
  @State pageVersion: number = 0
  @State refundProgressStatusText: string = ''
  @State refundProgressApplyTime: string = ''
  @State refundProgressFailReason: string = ''
  @State isRefreshingPage: boolean = false
  @State canViewTicketValue: boolean = false
  @State isTicketingValue: boolean = false
  @State canRefundValue: boolean = false
  @State ticketDetailActionText: string = '查看电子票'
  @StorageLink('order_changed_version') @Watch('onOrderChanged') orderChangedVersion: number = 0
  @StorageLink('refund_changed_version') @Watch('onOrderRelatedChanged') refundChangedVersion: number = 0
  @StorageLink('ticket_changed_version') @Watch('onOrderRelatedChanged') ticketChangedVersion: number = 0

  private payTimerId: number = -1
  private stateRefreshTimerId: number = -1
  private isReloadingPage: boolean = false
  private isRefreshingExpiredOrder: boolean = false
  private isLocalMutation: boolean = false
  private routeUserId: string = ''
  private routeOrderId: string = ''
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    this.loadPageData()
  }

  aboutToDisappear(): void {
    this.stopPayCountdown()
    this.stopStateRefreshTimer()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    this.pendingExternalRefresh = false
    this.reloadCurrentOrderDetail()
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  private onOrderChanged(): void {
    if (this.isLocalMutation) return
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadCurrentOrderDetail()
  }

  private onOrderRelatedChanged(): void {
    if (this.isLocalMutation) return
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadCurrentOrderDetail()
  }

  private async reloadCurrentOrderDetail(): Promise<boolean> {
    if (this.userId.length === 0 || this.orderId.length === 0 || this.isReloadingPage) {
      return false
    }

    this.isReloadingPage = true
    try {
      await this.vm.reload()
      this.syncFromVm()
      this.startPayCountdownIfNeeded()
      this.startStateRefreshTimerIfNeeded()
    } finally {
      this.isReloadingPage = false
    }
    return true
  }

  private async manualRefreshPage(): Promise<void> {
    if (this.isRefreshingPage) return
    this.isRefreshingPage = true
    const refreshed: boolean = await this.reloadCurrentOrderDetail()
    this.isRefreshingPage = false
    if (!refreshed) {
      promptAction.showToast({ message: '正在刷新，请稍候' })
      return
    }
    promptAction.showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '已获取最新订单状态' })
  }

  private async loadPageData(): Promise<void> {
    const params: OrderDetailRouteParams = this.getRouteParams()
    const userId: string = this.resolveUserId(params.userId)
    const orderId: string = this.resolveOrderId(params.orderId)

    if (userId.length === 0) {
      this.errorMessage = '请先登录后查看订单详情'
      this.orderDetailVO = undefined
      this.refreshPage()
      promptAction.showToast({ message: '请先登录后查看订单详情' })
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    if (orderId.length === 0) {
      this.errorMessage = '订单参数不存在'
      this.orderDetailVO = undefined
      this.refreshPage()
      return
    }

    try {
      this.isLoading = true
      this.errorMessage = ''
      this.refreshPage()
      AppStorage.setOrCreate('order_detail_user_id', userId)
      AppStorage.setOrCreate('order_detail_order_id', orderId)
      await this.vm.loadPage(userId, orderId)
      this.syncFromVm()
      this.startPayCountdownIfNeeded()
      this.startStateRefreshTimerIfNeeded()
    } catch (error) {
      this.isLoading = false
      this.errorMessage = error instanceof Error ? error.message : '订单详情加载失败'
      this.orderDetailVO = undefined
      this.refreshPage()
    }
  }

  private getRouteParams(): OrderDetailRouteParams {
    const rawParams: OrderDetailRouteParams | undefined = router.getParams() as OrderDetailRouteParams | undefined

    if (rawParams !== undefined && rawParams !== null) {
      if (rawParams.userId !== undefined && String(rawParams.userId).length > 0) {
        this.routeUserId = String(rawParams.userId)
      }
      if (rawParams.orderId !== undefined && String(rawParams.orderId).length > 0) {
        this.routeOrderId = String(rawParams.orderId)
      }
    }

    return {
      userId: this.routeUserId,
      orderId: this.routeOrderId
    }
  }

  private resolveUserId(routeUserId?: string): string {
    const normalizedRouteUserId: string = (routeUserId ?? '').trim()
    if (normalizedRouteUserId.length > 0) {
      return normalizedRouteUserId
    }

    const storageUserId: string | undefined = AppStorage.get<string>('order_detail_user_id')
    if (storageUserId !== undefined && storageUserId.trim().length > 0) {
      return storageUserId.trim()
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  private resolveOrderId(routeOrderId?: string): string {
    const normalizedRouteOrderId: string = (routeOrderId ?? '').trim()
    if (normalizedRouteOrderId.length > 0) {
      return normalizedRouteOrderId
    }

    const storageOrderId: string | undefined = AppStorage.get<string>('order_detail_order_id')
    if (storageOrderId !== undefined && storageOrderId.trim().length > 0) {
      return storageOrderId.trim()
    }

    return ''
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.RefreshMarker()
        this.TopBar()

        if (this.orderDetailVO === undefined && this.isLoading) {
          this.LoadingArea('正在加载订单详情...')
        } else if (this.orderDetailVO === undefined) {
          this.EmptyArea()
        } else {
          Scroll() {
            Column() {
              this.StatusArea()
              this.PerformanceArea()
              this.AudienceArea()
              this.DeliveryArea()
              this.DetailInfoArea()
              this.ActionArea()
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

      if (this.showPayDialog && this.orderDetailVO !== undefined) {
        PayOrderDialog({
          payAmount: this.orderDetailVO.payAmount,
          payExpireText: this.payRemainText,
          selectedPayMethod: this.selectedPayMethod,
          onPayMethodChange: (payMethod: PayMethod): void => {
            this.selectedPayMethod = payMethod
          },
          onConfirmPay: (): void => {
            this.confirmPay()
          },
          onCancelPay: (): void => {
            this.cancelPayFromDialog()
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private TopBar() {
    Row() {
      Row() {
        Image($r('app.media.fanhui'))
          .width(22)
          .height(22)
      }
      .justifyContent(FlexAlign.Center)
        .width(36)
        .height(44)
        .onClick(() => {
          router.back()
        })

      Text('订单详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4 })

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
    .padding({ left: 8, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private LoadingArea(message: string) {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color('#E33B3B')

      Text(message)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '订单详情不存在')
        .fontSize(15)
        .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private StatusArea() {
    Column() {
      Text(this.getOrderStatusText((this.orderDetailVO as OrderDetailVO).orderStatus))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')

      Text(this.getOrderStatusTip(this.orderDetailVO as OrderDetailVO))
        .fontSize(13)
        .fontColor('#FFFFFF')
        .margin({ top: 8 })
        .width('100%')

      if ((this.orderDetailVO as OrderDetailVO).orderStatus === OrderStatus.WAIT_PAY) {
        Row() {
          Button('取消订单')
            .height(38)
            .layoutWeight(1)
            .fontSize(14)
            .fontColor('#E33B3B')
            .backgroundColor('#FFFFFF')
            .borderRadius(19)
            .onClick(() => {
              this.cancelOrder()
            })

          Button('立即支付')
            .height(38)
            .layoutWeight(1)
            .fontSize(14)
            .fontColor('#E33B3B')
            .backgroundColor('#FFFFFF')
            .borderRadius(19)
            .margin({ left: 12 })
            .onClick(() => {
              this.openPayDialog()
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
    }
    .width('100%')
    .padding(16)
    .margin({ top: 12 })
    .backgroundColor('#F04444')
    .borderRadius(14)
  }

  @Builder
  private PerformanceArea() {
    Row() {
      Image(MediaResourceUtil.getMedia((this.orderDetailVO as OrderDetailVO).posterUrl))
        .width(86)
        .height(116)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column() {
        Text((this.orderDetailVO as OrderDetailVO).projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text((this.orderDetailVO as OrderDetailVO).startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })
          .width('100%')

        Text((this.orderDetailVO as OrderDetailVO).venueName)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })
          .width('100%')

        ForEach((this.orderDetailVO as OrderDetailVO).orderItems, (item: OrderDetailItemVO) => {
          Text(item.skuName + ' ￥' + item.unitPrice + ' x ' + item.quantity)
            .fontSize(13)
            .fontColor('#333333')
            .margin({ top: 6 })
            .width('100%')
        }, (item: OrderDetailItemVO) => item.skuName + item.quantity)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AudienceArea() {
    Column() {
      Text('观演人信息')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      ForEach((this.orderDetailVO as OrderDetailVO).audiences, (item: OrderDetailAudienceVO) => {
        Column() {
          Row() {
            Text(item.realName)
              .fontSize(14)
              .fontColor('#222222')
              .fontWeight(FontWeight.Medium)

            Blank()

            Text('证件号：' + item.maskedCertificateNo)
              .fontSize(13)
              .fontColor('#666666')
          }
          .width('100%')

          Row() {
            Text('手机号：' + this.getDisplayPhone(item.maskedPhone))
              .fontSize(13)
              .fontColor('#666666')

            Blank()
          }
          .width('100%')
          .margin({ top: 6 })
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
      }, (item: OrderDetailAudienceVO) => item.realName + item.maskedCertificateNo + (item.maskedPhone ?? ''))
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }


  private getDisplayPhone(maskedPhone: string | undefined): string {
    if (maskedPhone === undefined || maskedPhone.length === 0) {
      return '未填写'
    }

    return maskedPhone
  }

  @Builder
  private DeliveryArea() {
    Column() {
      Text('配送方式')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      if ((this.orderDetailVO as OrderDetailVO).deliveryType === DeliveryType.PAPER_TICKET && (this.orderDetailVO as OrderDetailVO).deliveryMode === 'SELF_PICKUP') {
        this.InfoRow('配送方式', '纸质票 · 现场取票')
        this.InfoRow('取票地点', '演出场馆')
        this.InfoRow('场馆', (this.orderDetailVO as OrderDetailVO).venueName)
        this.InfoRow('场馆地址', (this.orderDetailVO as OrderDetailVO).venueAddress.length > 0 ? (this.orderDetailVO as OrderDetailVO).venueAddress : '-')
      } else if ((this.orderDetailVO as OrderDetailVO).deliveryType === DeliveryType.PAPER_TICKET) {
        this.InfoRow('配送方式', '纸质票 · 快递配送')
        if ((this.orderDetailVO as OrderDetailVO).address !== undefined) {
          this.AddressInfo()
        }
      } else {
        this.InfoRow('配送方式', '电子票')
      }
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AddressInfo() {
    Column() {
      Text(this.currentOrderDetailAddress().receiverName + '  ' + this.currentOrderDetailAddress().receiverPhone)
        .fontSize(14)
        .fontColor('#222222')
        .width('100%')
      Text(this.currentOrderDetailAddress().fullAddress)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 4 })
        .width('100%')
    }
    .width('100%')
    .padding(10)
    .margin({ top: 8 })
    .backgroundColor('#F7F7F7')
    .borderRadius(10)
  }

  @Builder
  private DetailInfoArea() {
    Column() {
      Text('订单明细')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      this.InfoRow('订单编号', (this.orderDetailVO as OrderDetailVO).orderNo)
      this.InfoRow('订单状态', this.getOrderStatusText((this.orderDetailVO as OrderDetailVO).orderStatus))
      this.InfoRow('下单时间', (this.orderDetailVO as OrderDetailVO).createTime)
      if ((this.orderDetailVO as OrderDetailVO).orderStatus === OrderStatus.WAIT_PAY && (this.orderDetailVO as OrderDetailVO).payExpireTime !== undefined) {
        this.InfoRow('支付截止时间', (this.orderDetailVO as OrderDetailVO).payExpireTime ?? '')
        this.InfoRow('支付剩余时间', this.payRemainText)
      }

      if ((this.orderDetailVO as OrderDetailVO).payTime !== undefined) {
        this.InfoRow('支付方式', this.getPayMethodText((this.orderDetailVO as OrderDetailVO).payMethod))
        this.InfoRow('支付时间', (this.orderDetailVO as OrderDetailVO).payTime ?? '')
      }
      if ((this.orderDetailVO as OrderDetailVO).ticketIssuedTime !== undefined) {
        this.InfoRow('电子票生成时间', (this.orderDetailVO as OrderDetailVO).ticketIssuedTime ?? '')
      }
      if ((this.orderDetailVO as OrderDetailVO).cancelTime !== undefined) {
        this.InfoRow('取消时间', (this.orderDetailVO as OrderDetailVO).cancelTime ?? '')
      }
      if ((this.orderDetailVO as OrderDetailVO).finishTime !== undefined) {
        this.InfoRow('完成时间', (this.orderDetailVO as OrderDetailVO).finishTime ?? '')
      }
      if ((this.orderDetailVO as OrderDetailVO).refundTime !== undefined) {
        this.InfoRow('退款完成时间', (this.orderDetailVO as OrderDetailVO).refundTime ?? '')
      }
      if ((this.orderDetailVO as OrderDetailVO).refundAmount !== undefined && (this.orderDetailVO as OrderDetailVO).orderStatus === OrderStatus.REFUNDING) {
        this.InfoRow('预计退款金额', '￥' + (this.orderDetailVO as OrderDetailVO).refundAmount)
      }
      if ((this.orderDetailVO as OrderDetailVO).refundAmount !== undefined && (this.orderDetailVO as OrderDetailVO).orderStatus === OrderStatus.REFUND_SUCCESS) {
        this.InfoRow('退款金额', '￥' + (this.orderDetailVO as OrderDetailVO).refundAmount)
      }
      if ((this.orderDetailVO as OrderDetailVO).refundFeeAmount !== undefined) {
        this.InfoRow('手续费', '￥' + (this.orderDetailVO as OrderDetailVO).refundFeeAmount)
      }
      if (this.refundProgressStatusText.length > 0) {
        this.InfoRow('退款进度', this.refundProgressStatusText)
      }
      if (this.refundProgressApplyTime.length > 0) {
        this.InfoRow('退款申请时间', this.refundProgressApplyTime)
      }
      if (this.refundProgressFailReason.length > 0) {
        this.InfoRow('退款说明', this.refundProgressFailReason)
      }

      this.InfoRow('订单总额', '￥' + (this.orderDetailVO as OrderDetailVO).totalAmount)
      this.InfoRow('服务费', '￥' + ((this.orderDetailVO as OrderDetailVO).serviceFee ?? 0))
      this.InfoRow('配送费', '￥' + ((this.orderDetailVO as OrderDetailVO).deliveryFee ?? 0))
      this.InfoRow((this.orderDetailVO as OrderDetailVO).orderStatus === OrderStatus.WAIT_PAY ? '待支付金额' : '实付金额', '￥' + (this.orderDetailVO as OrderDetailVO).payAmount)
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private ActionArea() {
    Row() {
      Blank()

      if (this.canViewTicketValue) {
        Button(this.ticketDetailActionText)
          .height(38)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#E33B3B')
          .onClick(() => {
            this.jumpTicketDetail()
          })
      } else if (this.isTicketingValue) {
        Button('出票中')
          .height(38)
          .fontSize(14)
          .enabled(false)
      }

      if (this.canRefundValue) {
        Button('申请退款')
          .height(38)
          .fontSize(14)
          .fontColor('#E33B3B')
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E33B3B' })
          .margin({ left: 10 })
          .onClick(() => {
            this.jumpRefundApply()
          })
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
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

  private openPayDialog(): void {
    if (this.orderDetailVO === undefined || this.orderDetailVO.orderStatus !== OrderStatus.WAIT_PAY) {
      promptAction.showToast({ message: '当前订单不可支付' })
      return
    }

    this.selectedPayMethod = PayMethod.WECHAT
    this.startPayCountdownIfNeeded()
    this.showPayDialog = true
  }

  private async confirmPay(): Promise<void> {
    this.isLocalMutation = true
    const success: boolean = await this.vm.payOrder(this.selectedPayMethod)
    this.syncFromVm()
    this.isLocalMutation = false

    if (!success) {
      promptAction.showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '支付失败' })
      this.showPayDialog = false
      this.startPayCountdownIfNeeded()
      return
    }

    this.showPayDialog = false
    this.stopPayCountdown()
    router.pushUrl({
      url: 'pages/order/PaySuccessPage',
      params: {
        userId: this.userId,
        orderId: this.orderId,
        payMethod: this.selectedPayMethod
      }
    })
  }

  private cancelPayFromDialog(): void {
    // 取消支付 / 点击弹窗外关闭弹窗，只关闭弹窗，不改变订单，也不停止订单详情页倒计时。
    this.showPayDialog = false
    this.updatePayRemainText()
    this.refreshPage()
  }

  private async cancelOrder(): Promise<void> {
    this.isLocalMutation = true
    const success: boolean = await this.vm.cancelOrder()

    this.syncFromVm()
    this.isLocalMutation = false

    if (success) {
      this.showPayDialog = false
      this.stopPayCountdown()
      this.payRemainText = '00:00'
      this.refreshPage()
      promptAction.showToast({ message: '订单已取消' })
      return
    }

    promptAction.showToast({
      message: this.errorMessage.length > 0 ? this.errorMessage : '取消订单失败'
    })
  }

  private getTicketDetailActionText(): string {
    const vo: OrderDetailVO | undefined = this.orderDetailVO
    if (vo?.deliveryType === DeliveryType.PAPER_TICKET) {
      return vo.deliveryMode === 'EXPRESS' ? '查看物流' : '查看取票信息'
    }
    return '查看电子票'
  }

  private jumpTicketDetail(): void {
    const params: TicketDetailJumpParams | undefined = this.vm.buildTicketDetailJumpParams()
    if (params === undefined) {
      return
    }
    router.pushUrl({ url: 'pages/ticket/TicketDetailPage', params: params })
  }

  private jumpRefundApply(): void {
    const params: RefundApplyJumpParams | undefined = this.vm.buildRefundApplyJumpParams()
    if (params === undefined) {
      return
    }

    // ArkUI 路由参数在部分页面切换/刷新时偶发取不到。
    // 进入退款申请页前先写入 AppStorage，退款页再做兜底读取。
    AppStorage.setOrCreate('refund_apply_user_id', params.userId)
    AppStorage.setOrCreate('refund_apply_order_id', params.orderId)

    router.pushUrl({ url: 'pages/order/RefundApplyPage', params: params })
  }

  private startStateRefreshTimerIfNeeded(): void {
    this.stopStateRefreshTimer()
    const status: OrderStatus | undefined = this.orderDetailVO?.orderStatus
    if (status !== OrderStatus.WAIT_PAY && status !== OrderStatus.WAIT_USE && status !== OrderStatus.REFUNDING) {
      return
    }
    this.stateRefreshTimerId = setInterval(() => {
      this.reloadCurrentOrderDetail()
    }, 15000)
  }

  private stopStateRefreshTimer(): void {
    if (this.stateRefreshTimerId >= 0) {
      clearInterval(this.stateRefreshTimerId)
      this.stateRefreshTimerId = -1
    }
  }

  private startPayCountdownIfNeeded(): void {
    if (this.orderDetailVO === undefined || this.orderDetailVO.orderStatus !== OrderStatus.WAIT_PAY) {
      this.stopPayCountdown()
      this.payRemainText = '00:00'
      return
    }

    this.stopPayCountdown()
    this.updatePayRemainText()
    this.payTimerId = setInterval(() => {
      this.updatePayRemainText()
    }, 1000)
  }

  private stopPayCountdown(): void {
    if (this.payTimerId >= 0) {
      clearInterval(this.payTimerId)
      this.payTimerId = -1
    }
  }

  private updatePayRemainText(): void {
    if (this.orderDetailVO === undefined || this.orderDetailVO.payExpireTime === undefined) {
      this.payRemainText = '00:00'
      return
    }

    const remainSeconds: number = this.getRemainSeconds(this.orderDetailVO.payExpireTime)
    this.payRemainText = this.formatRemainSeconds(remainSeconds)

    if (remainSeconds <= 0 && this.orderDetailVO.orderStatus === OrderStatus.WAIT_PAY) {
      this.stopPayCountdown()
      this.reloadAfterPayExpired()
    }
  }

  private getRemainSeconds(payExpireTime: string): number {
    const expireTime: number = new Date(payExpireTime.replace(' ', 'T')).getTime()
    const nowTime: number = new Date().getTime()
    return Math.max(0, Math.floor((expireTime - nowTime) / 1000))
  }

  private buildRemainText(payExpireTime: string): string {
    return this.formatRemainSeconds(this.getRemainSeconds(payExpireTime))
  }

  private formatRemainSeconds(remainSeconds: number): string {
    const minute: number = Math.floor(remainSeconds / 60)
    const second: number = remainSeconds % 60
    return this.pad(minute) + ':' + this.pad(second)
  }

  private async reloadAfterPayExpired(): Promise<void> {
    if (this.isRefreshingExpiredOrder) {
      return
    }

    this.isRefreshingExpiredOrder = true
    await this.vm.reload()
    this.syncFromVm()
    this.startPayCountdownIfNeeded()
    this.isRefreshingExpiredOrder = false
  }

  private pad(value: number): string {
    return value < 10 ? '0' + value : '' + value
  }

  private getOrderStatusText(status: OrderStatus): string {
    if (status === OrderStatus.WAIT_PAY) return '待支付'
    if (status === OrderStatus.WAIT_USE) return '待使用'
    if (status === OrderStatus.FINISHED) return '已完成'
    if (status === OrderStatus.REFUNDING) return '退款中'
    if (status === OrderStatus.REFUND_SUCCESS) return '退款成功'
    if (status === OrderStatus.CANCELED) return '已取消'
    return ''
  }

  private getOrderStatusTip(vo: OrderDetailVO): string {
    if (vo.orderStatus === OrderStatus.WAIT_PAY) return '请在支付截止时间前完成支付，剩余 ' + this.payRemainText
    if (vo.orderStatus === OrderStatus.WAIT_USE) return '支付成功，订单已提交'
    if (vo.orderStatus === OrderStatus.FINISHED) return '您的订单已完成'
    if (vo.orderStatus === OrderStatus.REFUNDING) return '退款申请已提交，请等待处理'
    if (vo.orderStatus === OrderStatus.REFUND_SUCCESS) return '您的电子票已退款成功'
    if (vo.orderStatus === OrderStatus.CANCELED) return '订单已取消'
    return ''
  }

  private getRefundProgressText(status: string): string {
    if (status === 'REFUNDING') return '退款处理中'
    if (status === 'REFUND_SUCCESS') return '退款成功'
    if (status === 'REFUND_FAILED') return '退款失败'
    return status
  }

  private getPayMethodText(method: PayMethod | undefined): string {
    if (method === PayMethod.ALIPAY) return '支付宝'
    if (method === PayMethod.WECHAT) return '微信'
    if (method === PayMethod.OTHER) return '其他'
    return '-'
  }

  private currentOrderDetailAddress(): OrderDetailAddressVO {
    return (this.orderDetailVO as OrderDetailVO).address as OrderDetailAddressVO
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.orderId = this.vm.orderId
    this.orderDetailVO = this.cloneOrderDetail(this.vm.orderDetailVO)
    this.errorMessage = this.vm.errorMessage
    this.isLoading = this.vm.isLoading
    this.canViewTicketValue = this.orderDetailVO?.ticketActionType === 'VIEW_TICKET'
    this.isTicketingValue = this.orderDetailVO?.ticketActionType === 'TICKETING'
    this.canRefundValue = this.orderDetailVO?.orderStatus === OrderStatus.WAIT_USE
    this.ticketDetailActionText = this.getTicketDetailActionText()
    const progress = this.vm.refundProgress
    this.refundProgressStatusText = progress === undefined ? '' : this.getRefundProgressText(progress.refundStatus as string)
    this.refundProgressApplyTime = progress?.applyTime ?? ''
    this.refundProgressFailReason = progress?.failReason ?? ''
    if (this.orderDetailVO !== undefined && this.orderDetailVO.payExpireTime !== undefined) {
      this.payRemainText = this.buildRemainText(this.orderDetailVO.payExpireTime)
    }
    if (this.orderDetailVO !== undefined) {
      console.info('[OrderDetailPage] uiSnapshot orderId=' + this.orderDetailVO.orderId +
        ', status=' + String(this.orderDetailVO.orderStatus))
    }
    this.refreshPage()
  }


  private cloneOrderDetail(source: OrderDetailVO | undefined): OrderDetailVO | undefined {
    if (source === undefined) return undefined
    return {
      orderId: source.orderId, orderNo: source.orderNo, orderStatus: source.orderStatus,
      posterUrl: source.posterUrl, categoryName: source.categoryName, projectTitle: source.projectTitle,
      startTime: source.startTime, venueName: source.venueName, venueAddress: source.venueAddress,
      orderItems: source.orderItems.map((item: OrderDetailItemVO): OrderDetailItemVO => {
        const cloned: OrderDetailItemVO = { skuName: item.skuName, unitPrice: item.unitPrice, quantity: item.quantity, subtotalAmount: item.subtotalAmount }
        return cloned
      }),
      audiences: source.audiences.map((item: OrderDetailAudienceVO): OrderDetailAudienceVO => {
        const cloned: OrderDetailAudienceVO = { realName: item.realName, maskedCertificateNo: item.maskedCertificateNo, maskedPhone: item.maskedPhone }
        return cloned
      }),
      deliveryType: source.deliveryType, deliveryMode: source.deliveryMode,
      address: source.address === undefined ? undefined : { receiverName: source.address.receiverName, receiverPhone: source.address.receiverPhone, fullAddress: source.address.fullAddress },
      createTime: source.createTime, payExpireTime: source.payExpireTime, payTime: source.payTime,
      ticketIssuedTime: source.ticketIssuedTime, cancelTime: source.cancelTime, finishTime: source.finishTime, refundTime: source.refundTime,
      totalAmount: source.totalAmount, serviceFee: source.serviceFee, deliveryFee: source.deliveryFee, payAmount: source.payAmount, payMethod: source.payMethod,
      ticketActionType: source.ticketActionType, defaultTicketId: source.defaultTicketId,
      refundAmount: source.refundAmount, refundFeeAmount: source.refundFeeAmount, projectId: source.projectId, sessionId: source.sessionId
    }
  }

  private refreshPage(): void {
    this.pageVersion++
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
}
