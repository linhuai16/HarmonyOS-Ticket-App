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
  @State showPayDialog: boolean = false
  @State selectedPayMethod: PayMethod = PayMethod.WECHAT
  @State payRemainText: string = '00:00'
  @State pageVersion: number = 0
  @StorageLink('order_changed_version') @Watch('onOrderChanged') orderChangedVersion: number = 0

  private payTimerId: number = -1
  private isRefreshingExpiredOrder: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  aboutToDisappear(): void {
    this.stopPayCountdown()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentOrderDetail()
  }

  private onOrderChanged(): void {
    this.reloadCurrentOrderDetail()
  }

  private reloadCurrentOrderDetail(): void {
    if (this.userId.length === 0 || this.orderId.length === 0) {
      return
    }

    this.vm.reload().then(() => {
      this.syncFromVm()
      this.startPayCountdownIfNeeded()
    })
  }

  private async loadPageData(): Promise<void> {
    const params = router.getParams() as OrderDetailRouteParams
    const userId: string = this.resolveUserId(params.userId)
    const orderId: string = params.orderId ?? ''

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

    await this.vm.loadPage(userId, orderId)
    this.syncFromVm()
    this.startPayCountdownIfNeeded()
  }

  private resolveUserId(routeUserId?: string): string {
    if (routeUserId !== undefined && routeUserId.length > 0) {
      return routeUserId
    }

    return this.userRepository.getCurrentUserId()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.RefreshMarker()
        this.TopBar()

        if (this.orderDetailVO === undefined) {
          this.EmptyArea()
        } else {
          Scroll() {
            Column() {
              this.StatusArea(this.orderDetailVO)
              this.PerformanceArea(this.orderDetailVO)
              this.AudienceArea(this.orderDetailVO)
              this.DeliveryArea(this.orderDetailVO)
              this.DetailInfoArea(this.orderDetailVO)
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
    }
    .width('100%')
    .height(52)
    .padding({ left: 8, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '订单详情不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private StatusArea(vo: OrderDetailVO) {
    Column() {
      Text(this.getOrderStatusText(vo.orderStatus))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')

      Text(this.getOrderStatusTip(vo))
        .fontSize(13)
        .fontColor('#FFFFFF')
        .margin({ top: 8 })
        .width('100%')

      if (vo.orderStatus === OrderStatus.WAIT_PAY) {
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
  private PerformanceArea(vo: OrderDetailVO) {
    Row() {
      Image(MediaResourceUtil.getMedia(vo.posterUrl))
        .width(86)
        .height(116)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column() {
        Text(vo.projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(vo.startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })
          .width('100%')

        Text(vo.venueName)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })
          .width('100%')

        ForEach(vo.orderItems, (item: OrderDetailItemVO) => {
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
  private AudienceArea(vo: OrderDetailVO) {
    Column() {
      Text('观演人信息')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      ForEach(vo.audiences, (item: OrderDetailAudienceVO) => {
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
  private DeliveryArea(vo: OrderDetailVO) {
    Column() {
      Text('配送方式')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      this.InfoRow('配送方式', vo.deliveryType === DeliveryType.PAPER_TICKET ? '实体票/快递票' : '电子票')

      if (vo.deliveryType === DeliveryType.PAPER_TICKET && vo.address !== undefined) {
        this.AddressInfo(vo.address)
      }
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AddressInfo(address: OrderDetailAddressVO) {
    Column() {
      Text(address.receiverName + '  ' + address.receiverPhone)
        .fontSize(14)
        .fontColor('#222222')
        .width('100%')
      Text(address.fullAddress)
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
  private DetailInfoArea(vo: OrderDetailVO) {
    Column() {
      Text('订单明细')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      this.InfoRow('订单编号', vo.orderNo)
      this.InfoRow('订单状态', this.getOrderStatusText(vo.orderStatus))
      this.InfoRow('下单时间', vo.createTime)
      if (vo.orderStatus === OrderStatus.WAIT_PAY && vo.payExpireTime !== undefined) {
        this.InfoRow('支付截止时间', vo.payExpireTime)
        this.InfoRow('支付剩余时间', this.payRemainText)
      }

      if (vo.payTime !== undefined) {
        this.InfoRow('支付方式', this.getPayMethodText(vo.payMethod))
        this.InfoRow('支付时间', vo.payTime)
      }
      if (vo.ticketIssuedTime !== undefined) {
        this.InfoRow('电子票生成时间', vo.ticketIssuedTime)
      }
      if (vo.cancelTime !== undefined) {
        this.InfoRow('取消时间', vo.cancelTime)
      }
      if (vo.finishTime !== undefined) {
        this.InfoRow('完成时间', vo.finishTime)
      }
      if (vo.refundTime !== undefined) {
        this.InfoRow('退款完成时间', vo.refundTime)
      }
      if (vo.refundAmount !== undefined && vo.orderStatus === OrderStatus.REFUNDING) {
        this.InfoRow('预计退款金额', '￥' + vo.refundAmount)
      }
      if (vo.refundAmount !== undefined && vo.orderStatus === OrderStatus.REFUND_SUCCESS) {
        this.InfoRow('退款金额', '￥' + vo.refundAmount)
      }
      if (vo.refundFeeAmount !== undefined) {
        this.InfoRow('手续费', '￥' + vo.refundFeeAmount)
      }

      this.InfoRow('订单总额', '￥' + vo.totalAmount)
      this.InfoRow('服务费', '￥' + (vo.serviceFee ?? 0))
      this.InfoRow('配送费', '￥' + (vo.deliveryFee ?? 0))
      this.InfoRow(vo.orderStatus === OrderStatus.WAIT_PAY ? '待支付金额' : '实付金额', '￥' + vo.payAmount)
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

      if (this.vm.canViewTicket()) {
        Button('查看电子票')
          .height(38)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#E33B3B')
          .onClick(() => {
            this.jumpTicketDetail()
          })
      } else if (this.vm.isTicketing()) {
        Button('出票中')
          .height(38)
          .fontSize(14)
          .enabled(false)
      }

      if (this.vm.canRefund()) {
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
    const success: boolean = await this.vm.payOrder(this.selectedPayMethod)
    this.syncFromVm()

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
    const success: boolean = await this.vm.cancelOrder()

    this.syncFromVm()

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
    router.pushUrl({ url: 'pages/order/RefundApplyPage', params: params })
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

  private getPayMethodText(method: PayMethod | undefined): string {
    if (method === PayMethod.ALIPAY) return '支付宝'
    if (method === PayMethod.WECHAT) return '微信'
    if (method === PayMethod.OTHER) return '其他'
    return '-'
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.orderId = this.vm.orderId
    this.orderDetailVO = this.vm.orderDetailVO
    this.errorMessage = this.vm.errorMessage
    if (this.orderDetailVO !== undefined && this.orderDetailVO.payExpireTime !== undefined) {
      this.payRemainText = this.buildRemainText(this.orderDetailVO.payExpireTime)
    }
    this.refreshPage()
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
