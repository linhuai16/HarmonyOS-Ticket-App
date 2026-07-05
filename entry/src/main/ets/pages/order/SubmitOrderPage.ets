import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  SubmitOrderPageVO,
  SubmitOrderItemVO
} from '../../model/vo/order/SubmitOrderPageVO'
import { AudienceItemVO } from '../../model/vo/user/AudiencePageVO'
import { AddressItemVO } from '../../model/vo/user/AddressPageVO'
import { SubmitOrderViewModel } from '../../viewmodel/SubmitOrderViewModel'
import { CreateOrderResponse } from '../../repository/OrderRepository'
import { PayMethod } from '../../model/enums/PayMethod'
import { PayOrderDialog } from '../../common/PayOrderDialog'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface SubmitOrderRouteParams {
  userId?: string
  projectId?: string
  sessionId?: string
  skuId?: string
  quantity?: number
}


@Entry
@Component
struct SubmitOrderPage {
  private vm: SubmitOrderViewModel = new SubmitOrderViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVO: SubmitOrderPageVO | undefined = undefined
  @State audienceList: AudienceItemVO[] = []
  @State addressList: AddressItemVO[] = []
  @State selectedAudienceIds: string[] = []
  @State selectedAddressId: string = ''
  @State audienceSelectText: string = ''
  @State deliveryTypeText: string = ''
  @State deliveryTipText: string = ''
  @State shouldShowAddressAreaValue: boolean = false
  @State canSubmitValue: boolean = false
  @State isSubmitting: boolean = false
  @State errorMessage: string = ''
  @State submitErrorMessage: string = ''
  @State showPriceDetail: boolean = false
  @State showPayDialog: boolean = false
  @State selectedPayMethod: PayMethod = PayMethod.WECHAT
  @State pendingOrderResponse: CreateOrderResponse | undefined = undefined
  @State payRemainText: string = '15:00'
  @State pageVersion: number = 0

  @StorageLink('audience_changed_version')
  audienceChangedVersion: number = 0

  @StorageLink('address_list_version')
  addressListVersion: number = 0

  @StorageLink('login_version')
  loginVersion: number = 0

  private handledAudienceChangedVersion: number = -1
  private handledAddressListVersion: number = -1
  private handledLoginVersion: number = -1
  private payTimerId: number = -1

  private routeUserId: string = ''
  private routeProjectId: string = ''
  private routeSessionId: string = ''
  private routeSkuId: string = ''
  private routeQuantity: number = 1

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  aboutToDisappear(): void {
    this.stopPayCountdown()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.handlePageShow()
  }

  private async handlePageShow(): Promise<void> {
    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    const loginChanged: boolean = this.loginVersion !== this.handledLoginVersion

    if (currentUserId.length > 0 && (this.vm.userId !== currentUserId || loginChanged)) {
      if (this.vm.projectId.length > 0 && this.vm.sessionId.length > 0 && this.vm.skuId.length > 0) {
        await this.vm.loadPage(currentUserId, this.vm.projectId, this.vm.sessionId, this.vm.skuId, this.vm.quantity)
        this.handledAudienceChangedVersion = this.audienceChangedVersion
        this.handledAddressListVersion = this.addressListVersion
        this.handledLoginVersion = this.loginVersion
        this.syncFromVm()
        return
      }

      await this.loadPageData()
      return
    }

    if (this.vm.userId.length > 0) {
      const shouldPreferDefaultAudience: boolean =
        this.audienceChangedVersion !== this.handledAudienceChangedVersion

      this.vm.refreshAudienceList(shouldPreferDefaultAudience)
      this.handledAudienceChangedVersion = this.audienceChangedVersion

      if (this.vm.shouldShowAddressArea()) {
        const shouldPreferDefaultAddress: boolean =
          this.addressListVersion !== this.handledAddressListVersion

        this.vm.refreshAddressList(shouldPreferDefaultAddress)
        this.handledAddressListVersion = this.addressListVersion
      }
      this.handledLoginVersion = this.loginVersion
      this.syncFromVm()
    }
  }

  private async loadPageData(): Promise<void> {
    const params: SubmitOrderRouteParams = this.getRouteParams()

    const routeUserId: string = params.userId ?? ''
    const userId: string = this.getEffectiveUserId(routeUserId)
    const projectId: string = params.projectId ?? this.vm.projectId
    const sessionId: string = params.sessionId ?? this.vm.sessionId
    const skuId: string = params.skuId ?? this.vm.skuId
    const quantity: number = params.quantity ?? this.vm.quantity

    if (projectId.length === 0 || sessionId.length === 0 || skuId.length === 0) {
      this.vm.errorMessage = '订单参数不存在'
      this.handledLoginVersion = this.loginVersion
      this.syncFromVm()
      return
    }

    await this.vm.loadPage(userId, projectId, sessionId, skuId, quantity)
    this.handledAudienceChangedVersion = this.audienceChangedVersion
    this.handledAddressListVersion = this.addressListVersion
    this.handledLoginVersion = this.loginVersion
    this.syncFromVm()
  }

  private getRouteParams(): SubmitOrderRouteParams {
    const rawParams: SubmitOrderRouteParams | undefined = router.getParams() as SubmitOrderRouteParams | undefined

    if (rawParams !== undefined && rawParams !== null) {
      if (rawParams.userId !== undefined) {
        this.routeUserId = rawParams.userId
      }
      if (rawParams.projectId !== undefined && rawParams.projectId.length > 0) {
        this.routeProjectId = rawParams.projectId
      }
      if (rawParams.sessionId !== undefined && rawParams.sessionId.length > 0) {
        this.routeSessionId = rawParams.sessionId
      }
      if (rawParams.skuId !== undefined && rawParams.skuId.length > 0) {
        this.routeSkuId = rawParams.skuId
      }
      if (rawParams.quantity !== undefined && rawParams.quantity > 0) {
        this.routeQuantity = rawParams.quantity
      }
    }

    const params: SubmitOrderRouteParams = {
      userId: this.routeUserId,
      projectId: this.routeProjectId,
      sessionId: this.routeSessionId,
      skuId: this.routeSkuId,
      quantity: this.routeQuantity
    }
    return params
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.RefreshMarker()
        this.TopBar()

        if (this.pageVO === undefined) {
          this.EmptyArea()
        } else {
          Scroll() {
            Column() {
              this.PayExpireTip(this.pageVO)
              this.PerformanceArea(this.pageVO)
              this.OrderItemArea(this.pageVO)
              this.AudienceArea(this.pageVO)
              this.DeliveryArea()
              Blank().height(96)
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

      this.BottomBar()

      if (this.showPriceDetail) {
        this.PriceDetailPanel()
      }

      if (this.showPayDialog) {
        PayOrderDialog({
          payAmount: this.getPendingPayAmount(),
          payExpireText: this.payRemainText,
          selectedPayMethod: this.selectedPayMethod,
          onPayMethodChange: (payMethod: PayMethod): void => {
            this.selectedPayMethod = payMethod
          },
          onConfirmPay: (): void => {
            this.confirmPay()
          },
          onCancelPay: (): void => {
            this.cancelPayAndGoOrderDetail()
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
      .width(40)
      .height(52)
      .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.back()
        })

      Text('提交订单')
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
      Text(this.errorMessage.length > 0 ? this.errorMessage : '订单数据不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private PayExpireTip(pageVO: SubmitOrderPageVO) {
    Text('请在下单后 ' + pageVO.payExpireMinutes + ' 分钟内完成支付，逾期订单将自动取消')
      .fontSize(13)
      .fontColor('#E33B3B')
      .width('100%')
      .padding(10)
      .margin({ top: 12 })
      .backgroundColor('#FFF1F1')
      .borderRadius(10)
  }

  @Builder
  private PerformanceArea(pageVO: SubmitOrderPageVO) {
    Column() {
      Text(pageVO.performance.projectTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(pageVO.performance.startTime)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })
        .width('100%')

      Text(pageVO.performance.venueName)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 6 })
        .width('100%')

      Text(pageVO.performance.venueAddress)
        .fontSize(13)
        .fontColor('#999999')
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private OrderItemArea(pageVO: SubmitOrderPageVO) {
    Column() {
      Text('票品信息')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      ForEach(pageVO.orderItems, (item: SubmitOrderItemVO) => {
        Row() {
          Column() {
            Text(item.skuName)
              .fontSize(15)
              .fontColor('#222222')
              .fontWeight(FontWeight.Medium)

            Text('实名制票品，请选择对应观演人')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text('￥' + item.unitPrice + ' x ' + item.quantity)
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('100%')
        .margin({ top: 12 })
      }, (item: SubmitOrderItemVO) => item.skuId)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AudienceArea(pageVO: SubmitOrderPageVO) {
    Column() {
      Row() {
        Text('实名观演人')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Blank()

        Text('新增观演人')
          .fontSize(14)
          .fontColor('#E33B3B')
          .onClick(() => {
            this.openAudienceEditPage()
          })
      }
      .width('100%')

      Text('需选择 ' + pageVO.requiredAudienceCount + ' 位观演人，入场需携带对应证件')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 8 })
        .width('100%')

      Text(this.audienceSelectText)
        .fontSize(12)
        .fontColor('#E33B3B')
        .margin({ top: 6 })
        .width('100%')

      if (this.audienceList.length === 0) {
        Text('暂无观演人，请先新增')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })
      } else {
        ForEach(this.audienceList, (item: AudienceItemVO) => {
          Row() {
            this.SelectMark(this.isAudienceSelected(item.audienceId))

            Column() {
              Row() {
                Text(item.realName)
                  .fontSize(15)
                  .fontColor('#222222')
                  .fontWeight(FontWeight.Medium)

                if (item.isDefault) {
                  Text('默认')
                    .fontSize(10)
                    .fontColor('#E33B3B')
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .margin({ left: 8 })
                    .backgroundColor('#FFECEC')
                    .borderRadius(6)
                }
              }

              Text('证件号：' + item.maskedCertificateNo)
                .fontSize(13)
                .fontColor('#666666')
                .margin({ top: 4 })

              Text('手机号：' + this.getDisplayPhone(item.maskedPhone))
                .fontSize(13)
                .fontColor('#666666')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .margin({ left: 8 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(10)
          .margin({ top: 10 })
          .backgroundColor(this.isAudienceSelected(item.audienceId) ? '#FFF3F3' : '#F7F7F7')
          .borderRadius(10)
          .onClick(() => {
            this.toggleAudience(item.audienceId)
          })
        }, (item: AudienceItemVO) => {
          return `${item.audienceId}_${item.realName}_${item.maskedCertificateNo}_${item.maskedPhone ?? ''}_${item.isDefault}_${this.isAudienceSelected(item.audienceId)}_${this.pageVersion}`
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private DeliveryArea() {
    Column() {
      Text('配送方式')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Column() {
        Text(this.deliveryTypeText)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .width('100%')

        Text(this.deliveryTipText)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 6 })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(10)
      .margin({ top: 10 })
      .backgroundColor('#F7F7F7')
      .borderRadius(10)

      if (this.shouldShowAddressAreaValue) {
        this.AddressArea()
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AddressArea() {
    Column() {
      Row() {
        Text('收货地址')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)

        Blank()

        Text('新增收货地址')
          .fontSize(13)
          .fontColor('#E33B3B')
          .onClick(() => {
            this.openAddressEditPage()
          })
      }
      .width('100%')
      .margin({ top: 12 })

      if (this.addressList.length === 0) {
        Text('暂无收货地址，请先新增')
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 12 })
      } else {
        ForEach(this.addressList, (item: AddressItemVO) => {
          Row() {
            this.RadioMark(this.isAddressSelected(item.addressId))

            Column() {
              Row() {
                Text(item.receiverName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)

                Text(item.maskedReceiverPhone)
                  .fontSize(13)
                  .fontColor('#666666')
                  .margin({ left: 8 })

                if (item.isDefault) {
                  Text('默认')
                    .fontSize(10)
                    .fontColor('#E33B3B')
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .margin({ left: 8 })
                    .backgroundColor('#FFECEC')
                    .borderRadius(6)
                }
              }
              .width('100%')

              Text(item.fullAddress)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
            .layoutWeight(1)
            .margin({ left: 8 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(10)
          .margin({ top: 8 })
          .backgroundColor(this.isAddressSelected(item.addressId) ? '#FFF3F3' : '#F7F7F7')
          .borderRadius(10)
          .onClick(() => {
            this.selectAddress(item.addressId)
          })
        }, (item: AddressItemVO) => {
          return `${item.addressId}_${item.receiverName}_${item.maskedReceiverPhone}_${item.fullAddress}_${item.isDefault}_${this.isAddressSelected(item.addressId)}_${this.pageVersion}`
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private BottomBar() {
    Row() {
      Column() {
        Text(this.getPayAmountText())
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E33B3B')

        Text('价格明细')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 2 })
          .onClick(() => {
            this.showPriceDetail = true
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button(this.isSubmitting ? '提交中...' : '提交订单')
        .height(44)
        .width(130)
        .fontSize(16)
        .backgroundColor(this.canSubmitValue ? '#E33B3B' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .borderRadius(22)
        .enabled(this.canSubmitValue && !this.isSubmitting)
        .onClick(() => {
          this.submitOrder()
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private PriceDetailPanel() {
    Column() {
      Blank()
        .layoutWeight(1)
        .onClick(() => {
          this.showPriceDetail = false
        })

      Column() {
        Row() {
          Text('价格明细')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)

          Blank()

          Text('×')
            .fontSize(22)
            .onClick(() => {
              this.showPriceDetail = false
            })
        }
        .width('100%')

        Text('实际支付金额以下单结算页为准')
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 8 })
          .width('100%')

        if (this.pageVO !== undefined) {
          this.PriceRow('票款', this.pageVO.priceDetail.ticketAmount)
          this.PriceRow('服务费', this.pageVO.priceDetail.serviceFee ?? 0)
          this.PriceRow('配送费', this.pageVO.priceDetail.deliveryFee ?? 0)
          this.PriceRow('合计', this.pageVO.priceDetail.payAmount, true)
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 18, topRight: 18 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }

  @Builder
  private PriceRow(label: string, amount: number, strong: boolean = false) {
    Row() {
      Text(label)
        .fontSize(strong ? 16 : 14)
        .fontWeight(strong ? FontWeight.Bold : FontWeight.Normal)
        .fontColor('#333333')

      Blank()

      Text('￥' + amount)
        .fontSize(strong ? 18 : 14)
        .fontWeight(strong ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(strong ? '#E33B3B' : '#333333')
    }
    .width('100%')
    .margin({ top: strong ? 16 : 10 })
  }

  @Builder
  private SelectMark(selected: boolean) {
    Text(selected ? '✓' : '')
      .fontSize(14)
      .fontColor('#FFFFFF')
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
      .width(22)
      .height(22)
      .backgroundColor(selected ? '#E33B3B' : '#FFFFFF')
      .border({ width: 1, color: selected ? '#E33B3B' : '#CCCCCC' })
      .borderRadius(11)
  }

  @Builder
  private RadioMark(selected: boolean) {
    Text(selected ? '●' : '')
      .fontSize(13)
      .fontColor(selected ? '#E33B3B' : '#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(22)
      .height(22)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: selected ? '#E33B3B' : '#CCCCCC' })
      .borderRadius(11)
  }

  private toggleAudience(audienceId: string): void {
    this.vm.selectAudience(audienceId)
    this.syncFromVm()
    if (this.submitErrorMessage.length > 0) {
      promptAction.showToast({ message: this.submitErrorMessage })
    }
  }

  private selectAddress(addressId: string): void {
    this.vm.selectAddress(addressId)
    this.syncFromVm()
  }

  private openAudienceEditPage(): void {
    router.pushUrl({
      url: 'pages/user/AudienceEditPage',
      params: {
        userId: this.getEffectiveUserId(),
        from: 'submitOrder'
      }
    })
  }

  private openAddressEditPage(): void {
    router.pushUrl({
      url: 'pages/user/AddressEditPage',
      params: {
        userId: this.getEffectiveUserId(),
        from: 'submitOrder'
      }
    })
  }

  private getEffectiveUserId(routeUserId: string = ''): string {
    const normalizedRouteUserId: string = routeUserId.trim()
    if (normalizedRouteUserId.length > 0) {
      return normalizedRouteUserId
    }

    const normalizedVmUserId: string = this.vm.userId.trim()
    if (normalizedVmUserId.length > 0) {
      return normalizedVmUserId
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  private async submitOrder(): Promise<void> {
    if (!this.vm.isLogin()) {
      promptAction.showToast({ message: '请先登录后再提交订单' })
      router.pushUrl({
        url: 'pages/user/LoginPage'
      })
      return
    }

    const response: CreateOrderResponse | undefined = await this.vm.submitOrder()
    this.syncFromVm()

    if (response === undefined) {
      const message: string = this.submitErrorMessage.length > 0 ? this.submitErrorMessage : this.errorMessage
      promptAction.showToast({
        message: message.length > 0 ? message : '提交订单失败'
      })
      return
    }

    this.pendingOrderResponse = response
    this.selectedPayMethod = PayMethod.WECHAT
    this.startPayCountdown()
    this.showPayDialog = true
  }

  private confirmPay(): void {
    if (this.pendingOrderResponse === undefined) {
      promptAction.showToast({ message: '支付订单不存在，请重新提交订单' })
      this.showPayDialog = false
      this.stopPayCountdown()
      return
    }

    const orderId: string = this.pendingOrderResponse.orderId
    this.showPayDialog = false
    this.stopPayCountdown()

    router.pushUrl({
      url: 'pages/order/PaySuccessPage',
      params: {
        userId: this.vm.userId,
        orderId: orderId,
        payMethod: this.selectedPayMethod
      }
    })
  }

  private cancelPayAndGoOrderDetail(): void {
    this.showPayDialog = false
    this.stopPayCountdown()

    if (this.pendingOrderResponse === undefined) {
      return
    }

    router.replaceUrl({
      url: 'pages/order/OrderDetailPage',
      params: {
        userId: this.vm.userId,
        orderId: this.pendingOrderResponse.orderId
      }
    })
  }

  private startPayCountdown(): void {
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
    if (this.pendingOrderResponse === undefined || this.pendingOrderResponse.payExpireTime.length === 0) {
      if (this.pageVO === undefined) {
        this.payRemainText = '15:00'
        return
      }
      this.payRemainText = this.pad(this.pageVO.payExpireMinutes) + ':00'
      return
    }

    this.payRemainText = this.buildRemainText(this.pendingOrderResponse.payExpireTime)
  }

  private getPayAmountText(): string {
    if (this.pageVO === undefined) {
      return '￥0'
    }
    return '￥' + this.pageVO.priceDetail.payAmount
  }

  private getPendingPayAmount(): number {
    if (this.pendingOrderResponse !== undefined) {
      return this.pendingOrderResponse.payAmount
    }
    if (this.pageVO !== undefined) {
      return this.pageVO.priceDetail.payAmount
    }
    return 0
  }

  private getPendingPayAmountText(): string {
    if (this.pendingOrderResponse !== undefined) {
      return '￥' + this.pendingOrderResponse.payAmount
    }
    if (this.pageVO !== undefined) {
      return '￥' + this.pageVO.priceDetail.payAmount
    }
    return '￥0'
  }

  private getPayRemainText(): string {
    if (this.pendingOrderResponse === undefined || this.pendingOrderResponse.payExpireTime.length === 0) {
      if (this.pageVO === undefined) {
        return '15:00'
      }
      return this.pageVO.payExpireMinutes + ':00'
    }
    return this.buildRemainText(this.pendingOrderResponse.payExpireTime)
  }

  private buildRemainText(payExpireTime: string): string {
    const expireTime: number = new Date(payExpireTime.replace(' ', 'T')).getTime()
    const nowTime: number = new Date().getTime()
    const remainSeconds: number = Math.max(0, Math.floor((expireTime - nowTime) / 1000))
    const minute: number = Math.floor(remainSeconds / 60)
    const second: number = remainSeconds % 60
    return this.pad(minute) + ':' + this.pad(second)
  }

  private pad(value: number): string {
    return value < 10 ? '0' + value : '' + value
  }


  private getDisplayPhone(maskedPhone: string | undefined): string {
    if (maskedPhone === undefined || maskedPhone.length === 0) {
      return '未填写'
    }

    return maskedPhone
  }

  private isAudienceSelected(audienceId: string): boolean {
    return this.selectedAudienceIds.indexOf(audienceId) >= 0
  }

  private isAddressSelected(addressId: string): boolean {
    return this.selectedAddressId === addressId
  }

  private syncFromVm(): void {
    this.pageVO = this.vm.pageVO
    this.audienceList = this.vm.audienceList.slice()
    this.addressList = this.vm.addressList.slice()
    this.selectedAudienceIds = this.vm.selectedAudienceIds.slice()
    this.selectedAddressId = this.vm.selectedAddressId
    this.audienceSelectText = this.vm.getAudienceSelectText()
    this.deliveryTypeText = this.vm.getDeliveryTypeText()
    this.deliveryTipText = this.vm.getDeliveryTipText()
    this.shouldShowAddressAreaValue = this.vm.shouldShowAddressArea()
    this.canSubmitValue = this.vm.isLogin() ? this.vm.canSubmit() : this.pageVO !== undefined
    this.isSubmitting = this.vm.isSubmitting
    this.errorMessage = this.vm.errorMessage
    this.submitErrorMessage = this.vm.submitErrorMessage
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
