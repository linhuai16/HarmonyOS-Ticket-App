import router from '@ohos.router'

import {
  PaySuccessPageVO
} from '../../model/vo/order/PaySuccessPageVO'

import {
  PaySuccessViewModel
} from '../../viewmodel/PaySuccessViewModel'

import { DeliveryType } from '../../model/enums/DeliveryType'
import { PayMethod } from '../../model/enums/PayMethod'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface PaySuccessRouteParams {
  userId?: string
  orderId?: string
  payMethod?: PayMethod
}


@Entry
@Component
struct PaySuccessPage {
  private vm: PaySuccessViewModel = new PaySuccessViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVersion: number = 0
  @State paySuccessVO: PaySuccessPageVO | undefined = undefined
  @State errorMessage: string = ''
  @State routeUserId: string = ''
  @StorageLink('order_changed_version') @Watch('onOrderChanged') orderChangedVersion: number = 0
  @StorageLink('ticket_changed_version') @Watch('onOrderChanged') ticketChangedVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadPaySuccess()
  }

  private onOrderChanged(): void {
    this.reloadPaySuccess()
  }

  private async reloadPaySuccess(): Promise<void> {
    if (this.vm.userId.length === 0 || this.vm.orderId.length === 0) return
    await this.vm.reload()
    this.syncFromVm()
  }

  onBackPress(): boolean {
    // 支付成功页不能再回到提交订单页。系统返回键统一回首页，并清理中间购票栈。
    this.backAfterPaySuccess()
    return true
  }

  private async loadPageData(): Promise<void> {
    const params: PaySuccessRouteParams = (router.getParams() ?? {}) as PaySuccessRouteParams

    const userId: string = this.resolveUserId(params.userId)
    const orderId: string = params.orderId ?? ''
    const payMethod: PayMethod = params.payMethod ?? PayMethod.ALIPAY

    this.routeUserId = userId

    if (userId.length === 0) {
      this.errorMessage = '请先登录后查看支付结果'
      this.paySuccessVO = undefined
      this.refreshPage()
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    if (orderId.length === 0) {
      this.errorMessage = '订单参数不存在'
      this.paySuccessVO = undefined
      this.refreshPage()
      return
    }

    await this.vm.loadPaySuccess(userId, orderId, payMethod)
    this.syncFromVm()
  }

  build() {
    Column() {
      this.TopBar()

      if (this.paySuccessVO === undefined) {
        this.EmptyArea()
      } else {
        Scroll() {
          Column() {
            this.SuccessHeader()
            this.PerformanceCard()
            this.OrderInfoCard()
            Blank().height(24)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .layoutWeight(1)

        this.BottomButtons()
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
          this.backAfterPaySuccess()
        })

      Text('支付完成')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 8 })

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '支付完成数据不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private SuccessHeader() {
    Column() {
      Text('支付成功')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')

      Text('您的订单已成功提交，请耐心等待')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })

      Text('￥' + (this.paySuccessVO as PaySuccessPageVO).payAmount)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E33B3B')
        .margin({ top: 16 })
    }
    .width('100%')
    .padding({ top: 28, bottom: 28 })
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private PerformanceCard() {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia((this.paySuccessVO as PaySuccessPageVO).performance.posterUrl))
          .width(96)
          .height(128)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)

        Text((this.paySuccessVO as PaySuccessPageVO).performance.categoryName)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .backgroundColor('#E33B3B')
          .borderRadius({ topLeft: 8, bottomRight: 8 })
      }

      Column() {
        Text((this.paySuccessVO as PaySuccessPageVO).performance.projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text((this.paySuccessVO as PaySuccessPageVO).performance.startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 10 })

        Text((this.paySuccessVO as PaySuccessPageVO).performance.venueAddress)
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private OrderInfoCard() {
    Column() {
      this.InfoRow('订单编号', (this.paySuccessVO as PaySuccessPageVO).orderNo)
      this.InfoRow('票档', (this.paySuccessVO as PaySuccessPageVO).skuName)
      this.InfoRow('配送方式', this.getDeliveryTypeText((this.paySuccessVO as PaySuccessPageVO).deliveryType))
      this.InfoRow('支付方式', this.getPayMethodText((this.paySuccessVO as PaySuccessPageVO).payMethod))
      this.InfoRow('支付金额', '￥' + (this.paySuccessVO as PaySuccessPageVO).payAmount)
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

  @Builder
  private BottomButtons() {
    Row() {
      Button('返回首页')
        .height(44)
        .layoutWeight(1)
        .fontSize(16)
        .fontColor('#E33B3B')
        .backgroundColor('#FFFFFF')
        .border({
          width: 1,
          color: '#E33B3B'
        })
        .onClick(() => {
          this.goHome()
        })

      Button('查看订单')
        .height(44)
        .layoutWeight(1)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#E33B3B')
        .margin({ left: 12 })
        .onClick(() => {
          this.goOrderDetail((this.paySuccessVO as PaySuccessPageVO).orderId)
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private backAfterPaySuccess(): void {
    this.goHome()
  }

  private goHome(): void {
    router.clear()
    router.pushUrl({
      url: 'pages/Index'
    })
  }

  private goOrderDetail(orderId: string): void {
    const effectiveUserId: string = this.resolveUserId(this.routeUserId)

    if (effectiveUserId.length === 0 || orderId.length === 0) {
      this.goHome()
      return
    }

    // 支付成功后的“查看订单”不再保留提交订单页，避免订单详情返回后回到已失效的提交订单链路。
    router.clear()
    router.pushUrl({
      url: 'pages/order/OrderDetailPage',
      params: {
        userId: effectiveUserId,
        orderId: orderId
      }
    })
  }

  private resolveUserId(routeUserId?: string): string {
    const normalizedRouteUserId: string = (routeUserId ?? '').trim()
    if (normalizedRouteUserId.length > 0) {
      return normalizedRouteUserId
    }

    const normalizedVmUserId: string = this.vm.userId.trim()
    if (normalizedVmUserId.length > 0) {
      return normalizedVmUserId
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  private getDeliveryTypeText(deliveryType: DeliveryType): string {
    if (deliveryType === DeliveryType.ETICKET) {
      return '电子票'
    }

    if (deliveryType === DeliveryType.PAPER_TICKET) {
      return '实体票'
    }

    return ''
  }

  private getPayMethodText(payMethod: PayMethod | undefined): string {
    if (payMethod === PayMethod.ALIPAY) {
      return '支付宝'
    }

    if (payMethod === PayMethod.WECHAT) {
      return '微信'
    }

    if (payMethod === PayMethod.OTHER) {
      return '其他'
    }

    return '-'
  }


  private clonePaySuccessVO(source: PaySuccessPageVO | undefined): PaySuccessPageVO | undefined {
    if (source === undefined) return undefined
    return {
      payAmount: source.payAmount,
      performance: { posterUrl: source.performance.posterUrl, categoryName: source.performance.categoryName, projectTitle: source.performance.projectTitle, startTime: source.performance.startTime, venueAddress: source.performance.venueAddress },
      orderNo: source.orderNo, skuName: source.skuName, deliveryType: source.deliveryType, payMethod: source.payMethod, orderId: source.orderId
    }
  }

  private syncFromVm(): void {
    this.paySuccessVO = this.clonePaySuccessVO(this.vm.paySuccessVO)
    this.errorMessage = this.vm.errorMessage
    this.refreshPage()
  }

  private refreshPage(): void {
    this.pageVersion++
  }
}
