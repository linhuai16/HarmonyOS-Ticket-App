import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  RefundApplyPageVO
} from '../../model/vo/order/RefundApplyPageVO'

import {
  RefundApplyViewModel
} from '../../viewmodel/RefundApplyViewModel'

import {
  RefundOrderResponse
} from '../../repository/RefundRepository'

import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { RefundType } from '../../model/enums/RefundType'

interface RefundApplyRouteParams {
  userId?: string
  orderId?: string
}

@Entry
@Component
struct RefundApplyPage {
  private vm: RefundApplyViewModel = new RefundApplyViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVO: RefundApplyPageVO | undefined = undefined
  @State errorMessage: string = ''
  @State reason: string = ''
  @State isLoading: boolean = false
  @State isSubmitting: boolean = false
  @State pageVersion: number = 0
  @State isRefreshingPage: boolean = false
  @State canSubmitValue: boolean = false
  @StorageLink('order_changed_version') @Watch('onRefundDependencyChanged') orderChangedVersion: number = 0
  @StorageLink('refund_changed_version') @Watch('onRefundDependencyChanged') refundChangedVersion: number = 0

  private routeUserId: string = ''
  private routeOrderId: string = ''

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
  }

  private onRefundDependencyChanged(): void {
    if (this.isLoading || this.isSubmitting || this.isRefreshingPage) {
      return
    }
    this.loadPageData()
  }

  private async loadPageData(): Promise<void> {
    const params: RefundApplyRouteParams = this.getRouteParams()

    const userId: string = this.resolveUserId(params.userId)
    const orderId: string = this.resolveOrderId(params.orderId)

    this.isLoading = true
    this.errorMessage = ''
    this.pageVO = undefined
    this.refreshPage()

    if (userId.length === 0) {
      this.isLoading = false
      this.errorMessage = '请先登录后申请退款'
      this.refreshPage()
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    if (orderId.length === 0) {
      this.isLoading = false
      this.errorMessage = '退款订单参数不存在'
      this.refreshPage()
      return
    }

    AppStorage.setOrCreate('refund_apply_user_id', userId)
    AppStorage.setOrCreate('refund_apply_order_id', orderId)

    try {
      await this.vm.loadPage(userId, orderId)
    } catch (error) {
      this.vm.errorMessage = error instanceof Error ? error.message : '退款申请数据加载失败'
    }

    this.syncFromVm()
  }

  private getRouteParams(): RefundApplyRouteParams {
    const rawParams: RefundApplyRouteParams | undefined = router.getParams() as RefundApplyRouteParams | undefined

    if (rawParams !== undefined && rawParams !== null) {
      if (rawParams.userId !== undefined && String(rawParams.userId).length > 0) {
        this.routeUserId = String(rawParams.userId)
        AppStorage.setOrCreate('refund_apply_user_id', this.routeUserId)
      }
      if (rawParams.orderId !== undefined && String(rawParams.orderId).length > 0) {
        this.routeOrderId = String(rawParams.orderId)
        AppStorage.setOrCreate('refund_apply_order_id', this.routeOrderId)
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

    const storageUserId: string | undefined = AppStorage.get<string>('refund_apply_user_id')
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

    const storageOrderId: string | undefined = AppStorage.get<string>('refund_apply_order_id')
    if (storageOrderId !== undefined && storageOrderId.trim().length > 0) {
      return storageOrderId.trim()
    }

    return ''
  }


  private cloneRefundPage(source: RefundApplyPageVO | undefined): RefundApplyPageVO | undefined {
    if (source === undefined) return undefined
    return {
      orderId: source.orderId, projectTitle: source.projectTitle, posterUrl: source.posterUrl, startTime: source.startTime,
      venueName: source.venueName, venueAddress: source.venueAddress, skuName: source.skuName, quantity: source.quantity,
      payAmount: source.payAmount, estimatedRefundAmount: source.estimatedRefundAmount, feeAmount: source.feeAmount,
      refundType: source.refundType, refundRuleText: source.refundRuleText, canRefund: source.canRefund
    }
  }

  private syncFromVm(): void {
    this.pageVO = this.cloneRefundPage(this.vm.pageVO)
    this.errorMessage = this.vm.errorMessage
    this.reason = this.vm.reason
    this.isLoading = this.vm.isLoading
    this.isSubmitting = this.vm.isSubmitting
    this.canSubmitValue = this.vm.canSubmit()
    this.refreshPage()
  }

  build() {
    Column() {
      this.TopBar()

      if (this.isLoading) {
        this.LoadingArea()
      } else if (this.pageVO === undefined) {
        this.EmptyArea()
      } else {
        Scroll() {
          Column() {
            this.ProjectArea()
            this.RefundRuleArea()
            this.AmountArea()
            this.ReasonArea()
            Blank().height(92)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .layoutWeight(1)

        this.BottomButton()
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

      Text('申请退款')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 8 })

      Blank()
      Text(this.isRefreshingPage ? '刷新中' : '刷新')
        .fontSize(14)
        .fontColor(this.isRefreshingPage ? '#BBBBBB' : '#E33B3B')
        .height(44)
        .padding({ left: 10, right: 4 })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (!this.isRefreshingPage) this.manualRefreshRefundPage()
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private LoadingArea() {
    Column() {
      Text('退款申请数据加载中...')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '退款申请数据不存在')
        .fontSize(15)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20 })

      Button('重新加载')
        .height(38)
        .width(120)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#E33B3B')
        .borderRadius(19)
        .margin({ top: 18 })
        .onClick(() => {
          this.loadPageData()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private ProjectArea() {
    Row() {
      Image(MediaResourceUtil.getMedia((this.pageVO as RefundApplyPageVO).posterUrl))
        .width(86)
        .height(114)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column() {
        Text((this.pageVO as RefundApplyPageVO).projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text((this.pageVO as RefundApplyPageVO).startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })

        Text((this.pageVO as RefundApplyPageVO).venueName)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })

        Text((this.pageVO as RefundApplyPageVO).skuName + ' x ' + (this.pageVO as RefundApplyPageVO).quantity)
          .fontSize(13)
          .fontColor('#333333')
          .margin({ top: 8 })
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
  private RefundRuleArea() {
    Column() {
      Text('退款规则')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      if ((this.pageVO as RefundApplyPageVO).refundType === RefundType.FULL_ORDER) {
        Text('退款方式：整单退款')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 10 })
          .width('100%')
      }

      Text((this.pageVO as RefundApplyPageVO).refundRuleText.length > 0 ? (this.pageVO as RefundApplyPageVO).refundRuleText : '暂无退款规则说明')
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(22)
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
  private AmountArea() {
    Column() {
      Text('退款金额')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      this.InfoRow('实付金额', '￥' + (this.pageVO as RefundApplyPageVO).payAmount)
      this.InfoRow('手续费', '￥' + (this.pageVO as RefundApplyPageVO).feeAmount)
      this.InfoRow('预估退款金额', '￥' + (this.pageVO as RefundApplyPageVO).estimatedRefundAmount)

      Text('最终退款金额以退款审核结果为准')
        .fontSize(12)
        .fontColor('#999999')
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
        .fontColor(label === '预估退款金额' ? '#E33B3B' : '#222222')
        .fontWeight(label === '预估退款金额' ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height(36)
  }

  @Builder
  private ReasonArea() {
    Column() {
      Text('退款原因')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      TextArea({
        placeholder: '请输入退款原因（选填）',
        text: this.reason
      })
        .height(96)
        .margin({ top: 10 })
        .backgroundColor('#F7F7F7')
        .borderRadius(10)
        .onChange((value: string) => {
          this.reason = value
          this.vm.changeReason(value)
        })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private async manualRefreshRefundPage(): Promise<void> {
    if (this.isRefreshingPage) return
    this.isRefreshingPage = true
    await this.loadPageData()
    this.isRefreshingPage = false
    promptAction.showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '退款信息已刷新' })
  }

  @Builder
  private BottomButton() {
    Row() {
      Button(this.isSubmitting ? '提交中...' : '确认申请退款')
        .height(44)
        .width('100%')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.canSubmitValue && !this.isSubmitting ? '#E33B3B' : '#CCCCCC')
        .enabled(this.canSubmitValue && !this.isSubmitting)
        .onClick(() => {
          this.submitRefund()
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private async submitRefund(): Promise<void> {
    this.vm.changeReason(this.reason)
    this.isSubmitting = true
    this.refreshPage()

    const response: RefundOrderResponse | undefined = await this.vm.submitRefund()
    this.syncFromVm()

    if (response === undefined) {
      promptAction.showToast({
        message: this.errorMessage.length > 0 ? this.errorMessage : '退款申请失败'
      })
      return
    }

    promptAction.showToast({
      message: '退款申请已提交'
    })

    router.back()
  }

  private refreshPage(): void {
    this.pageVersion++
  }
}
