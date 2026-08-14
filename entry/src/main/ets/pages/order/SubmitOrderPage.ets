import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { SubmitOrderViewModel } from '../../viewmodel/SubmitOrderViewModel'
import { TicketSelectPageVO, TicketSkuSelectVO } from '../../model/vo/performance/TicketSelectPageVO'
import { AudienceItemVO } from '../../model/vo/user/AudiencePageVO'
import { AddressItemVO } from '../../model/vo/user/AddressPageVO'
import { PurchaseFulfillmentOptionVO } from '../../model/vo/ticketsource/PurchaseOptionVO'
import { QuotedOrderCreateVO, OrderActionVO } from '../../model/vo/ticketsource/OrderQuoteVO'
import { MoneyUtil } from '../../model/vo/ticketsource/MoneyVO'
import { PayMethod } from '../../model/enums/PayMethod'
import { PayOrderDialog } from '../../common/PayOrderDialog'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { AppStorageVersionUtil } from '../../utils/AppStorageVersionUtil'

interface SubmitOrderRouteParams {
  userId?: string
  projectId?: string
  sessionId?: string
  skuId?: string
  quantity?: number
}

/**
 * V1.3-B10R-5 提交订单页真实购票交互修正。
 * 页面只展示用户能理解的购票信息；满足下单条件时才点亮提交按钮。
 */
@Entry
@Component
struct SubmitOrderPage {
  private vm: SubmitOrderViewModel = new SubmitOrderViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVO: TicketSelectPageVO | undefined = undefined
  @State selectedSku: TicketSkuSelectVO | undefined = undefined
  @State audienceList: AudienceItemVO[] = []
  @State addressList: AddressItemVO[] = []
  @State fulfillmentOptions: PurchaseFulfillmentOptionVO[] = []
  @State selectedAudienceIds: string[] = []
  @State selectedAddressId: string = ''
  @State selectedOptionKey: string = ''
  @State createdOrder: QuotedOrderCreateVO | undefined = undefined
  @State audienceSelectText: string = ''
  @State payAmountText: string = '待确认'
  @State ticketAmountText: string = '待确认'
  @State deliveryFeeText: string = '¥0.00'
  @State referencePriceText: string = ''
  @State priceTipText: string = '页面金额为展示价预估，提交订单时以系统最终确认金额为准'
  @State errorMessage: string = ''
  @State actionErrorMessage: string = ''
  @State submitDisabledReason: string = ''
  @State isLoading: boolean = false
  @State isCreating: boolean = false
  @State showPriceDetail: boolean = false
  @State showPayDialog: boolean = false
  @State selectedPayMethod: PayMethod = PayMethod.WECHAT
  @State payRemainText: string = '15:00'
  @State pageVersion: number = 0
  @State isManualRefreshing: boolean = false
  @State quantityValue: number = 1
  @State requiresAddressValue: boolean = false
  @State priceChangedAwaitingConfirmValue: boolean = false

  @StorageLink('audience_changed_version') audienceChangedVersion: number = 0
  @StorageLink('address_list_version') addressListVersion: number = 0
  @StorageLink('login_version') loginVersion: number = 0

  private handledAudienceChangedVersion: number = -1
  private handledAddressListVersion: number = -1
  private handledLoginVersion: number = -1
  private payTimerId: number = -1
  private initialLoadCompleted: boolean = false

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
    if (this.initialLoadCompleted) {
      this.refreshAfterReturn()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.TopBar()

        if (this.pageVO === undefined || this.selectedSku === undefined) {
          this.EmptyArea()
        } else {
          Scroll() {
            Column() {
              this.PerformanceArea()
              this.SingleSkuArea()
              this.FulfillmentArea()
              this.AudienceArea()
              if (this.requiresAddressValue) {
                this.AddressArea()
              }
              this.PriceHintArea()
              this.ActionErrorArea()
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

      if (this.showPayDialog && this.createdOrder !== undefined) {
        PayOrderDialog({
          payAmount: MoneyUtil.toMajor(this.createdOrder.payAmount),
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
        Image($r('app.media.fanhui')).width(22).height(22)
      }
      .width(40)
      .height(52)
      .justifyContent(FlexAlign.Center)
      .onClick(() => router.back())

      Text('提交订单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4 })
      Blank()
      Text(this.isManualRefreshing ? '刷新中' : '刷新')
        .fontSize(14)
        .fontColor(this.isManualRefreshing ? '#BBBBBB' : '#E33B3B')
        .height(44)
        .padding({ left: 10, right: 4 })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (!this.isManualRefreshing) this.manualRefreshPurchase()
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 8, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      if (this.isLoading) {
        LoadingProgress().width(32).height(32)
        Text('正在加载订单信息...').fontSize(14).fontColor('#888888').margin({ top: 12 })
      } else {
        Text(this.errorMessage.length > 0 ? this.errorMessage : '订单数据不存在')
          .fontSize(15)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }

  @Builder
  private PerformanceArea() {
    Column() {
      Text((this.pageVO as TicketSelectPageVO).projectTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text((this.pageVO as TicketSelectPageVO).session.startTime).fontSize(14).fontColor('#666666').margin({ top: 10 }).width('100%')
      Text((this.pageVO as TicketSelectPageVO).session.stationName + ' · ' + (this.pageVO as TicketSelectPageVO).session.venueName)
        .fontSize(14).fontColor('#666666').margin({ top: 6 }).width('100%')
      Text((this.pageVO as TicketSelectPageVO).session.venueAddress)
        .fontSize(13).fontColor('#999999').margin({ top: 4 }).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private SingleSkuArea() {
    Column() {
      Row() {
        Text('票品信息').fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text('×' + this.quantityValue).fontSize(14).fontColor('#666666')
      }.width('100%')
      Row() {
        Column() {
          Text((this.selectedSku as TicketSkuSelectVO).skuName + ' x ' + String(this.quantityValue))
            .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#222222')
          if (((this.selectedSku as TicketSkuSelectVO).skuDesc ?? '').length > 0) {
            Text((this.selectedSku as TicketSkuSelectVO).skuDesc ?? '').fontSize(12).fontColor('#999999').margin({ top: 4 })
          }
          Text('提示：有限连坐配票')
            .fontSize(11).fontColor('#999999').margin({ top: 5 })
          Text((this.selectedSku as TicketSkuSelectVO).stockAvailable === undefined ? '库存待实时确认，以提交结果为准' : '当前库存 ' + (this.selectedSku as TicketSkuSelectVO).stockAvailable)
            .fontSize(11).fontColor('#999999').margin({ top: 4 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text(this.referencePriceText).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#E33B3B')
      }.width('100%').margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private FulfillmentArea() {
    Column() {
      Text('入场/取票方式').fontSize(16).fontWeight(FontWeight.Bold).width('100%')
      ForEach(this.fulfillmentOptions, (item: PurchaseFulfillmentOptionVO) => {
        Row() {
          this.RadioMark(this.isFulfillmentSelected(item))
          Column() {
            Row() {
              Text(item.label).fontSize(14).fontWeight(FontWeight.Medium)
              if (item.recommended) {
                Text('推荐').fontSize(10).fontColor('#E33B3B').padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .margin({ left: 6 }).backgroundColor('#FFECEC').borderRadius(6)
              }
            }
            Text(this.getFulfillmentHint(item))
              .fontSize(11).fontColor('#999999').margin({ top: 3 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
        }
        .width('100%')
        .padding(11)
        .margin({ top: 8 })
        .backgroundColor(this.isFulfillmentSelected(item) ? '#FFF3F3' : '#F7F7F7')
        .borderRadius(10)
        .onClick(() => {
          this.selectFulfillment(item)
        })
      }, (item: PurchaseFulfillmentOptionVO) => item.optionCode + '_' + String(item.deliveryFee.amountMinor) + '_' + String(this.pageVersion))
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AudienceArea() {
    Column() {
      Row() {
        Text('观演人').fontSize(16).fontWeight(FontWeight.Bold)
        Text(this.audienceSelectText).fontSize(12).fontColor('#E33B3B').margin({ left: 8 })
        Blank()
        Text('+ 新增').fontSize(13).fontColor('#E33B3B').onClick(() => this.openAudienceEditPage())
      }.width('100%')

      if (this.audienceList.length === 0) {
        Text('暂无观演人，请先新增').fontSize(13).fontColor('#999999').margin({ top: 12 })
      } else {
        ForEach(this.audienceList, (item: AudienceItemVO) => {
          Row() {
            this.SelectMark(this.isAudienceSelected(item.audienceId), this.isAudienceDisabled(item.audienceId))
            Column() {
              Row() {
                Text(item.realName).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isAudienceDisabled(item.audienceId) ? '#999999' : '#222222')
                if (item.isDefault) {
                  Text('默认').fontSize(10).fontColor('#E33B3B').margin({ left: 6 })
                }
              }
              Text(item.maskedCertificateNo).fontSize(12).fontColor('#888888').margin({ top: 4 })
              if (this.isAudienceDisabled(item.audienceId)) {
                Text(this.getAudienceDisabledReason(item.audienceId)).fontSize(11).fontColor('#E33B3B').margin({ top: 4 })
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
          }
          .width('100%')
          .padding(11)
          .margin({ top: 8 })
          .backgroundColor(this.isAudienceDisabled(item.audienceId) ? '#EEEEEE' : (this.isAudienceSelected(item.audienceId) ? '#FFF3F3' : '#F7F7F7'))
          .borderRadius(10)
          .onClick(() => this.toggleAudience(item.audienceId))
        }, (item: AudienceItemVO) => item.audienceId + '_' + String(this.pageVersion))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AddressArea() {
    Column() {
      Row() {
        Text('收货地址').fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text('+ 新增').fontSize(13).fontColor('#E33B3B').onClick(() => this.openAddressEditPage())
      }.width('100%')

      if (this.addressList.length === 0) {
        Text('暂无可用地址，请先新增').fontSize(13).fontColor('#999999').margin({ top: 12 })
      } else {
        ForEach(this.addressList, (item: AddressItemVO) => {
          Row() {
            this.RadioMark(this.isAddressSelected(item.addressId))
            Column() {
              Row() {
                Text(item.receiverName).fontSize(14).fontWeight(FontWeight.Medium)
                Text(item.maskedReceiverPhone).fontSize(12).fontColor('#666666').margin({ left: 8 })
              }
              Text(item.fullAddress).fontSize(12).fontColor('#999999').margin({ top: 4 })
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 10 })
          }
          .width('100%')
          .padding(11)
          .margin({ top: 8 })
          .backgroundColor(this.isAddressSelected(item.addressId) ? '#FFF3F3' : '#F7F7F7')
          .borderRadius(10)
          .onClick(() => {
            this.selectAddress(item.addressId)
          })
        }, (item: AddressItemVO) => item.addressId + '_' + String(this.pageVersion))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private PriceHintArea() {
    Text(this.priceTipText)
      .fontSize(12)
      .fontColor('#9A6A00')
      .width('100%')
      .padding(10)
      .margin({ top: 12 })
      .backgroundColor('#FFF8E6')
      .borderRadius(10)
  }

  @Builder
  private ActionErrorArea() {
    if (this.actionErrorMessage.length > 0) {
      Text(this.actionErrorMessage)
        .fontSize(12)
        .fontColor('#E33B3B')
        .width('100%')
        .padding(10)
        .margin({ top: 12 })
        .backgroundColor('#FFF1F1')
        .borderRadius(10)
    }
  }

  @Builder
  private BottomBar() {
    Row() {
      Column() {
        Row() {
          Text('合计').fontSize(13).fontColor('#333333')
          Text(this.payAmountText).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#E33B3B')
            .margin({ left: 4 })
          Text('明细⌃').fontSize(12).fontColor('#666666').margin({ left: 8 })
            .onClick(() => {
              this.showPriceDetail = true
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.submitDisabledReason.length > 0) {
          Text(this.submitDisabledReason)
            .fontSize(11)
            .fontColor('#E33B3B')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button(this.getBottomButtonText())
        .height(44)
        .width(142)
        .fontSize(15)
        .backgroundColor(this.canUseBottomButton() ? '#E33B3B' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .borderRadius(22)
        .enabled(this.canUseBottomButton())
        .onClick(() => this.handleBottomAction())
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private PriceDetailPanel() {
    Column() {
      Blank().layoutWeight(1).onClick(() => {
        this.showPriceDetail = false
      })
      Column() {
        Row() {
          Text('价格明细').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('×').fontSize(22).fontColor('#666666')
            .onClick(() => {
              this.showPriceDetail = false
            })
        }.width('100%')
        Text('实际支付金额以下单结算页为准')
          .fontSize(12).fontColor('#999999').margin({ top: 6 }).width('100%')
        this.PriceRow(this.getSkuPriceDetailLabel(), this.ticketAmountText)
        this.PriceRow('快递费', this.deliveryFeeText)
        this.PriceRow('优惠券', '本期暂不支持')
        Divider().color('#EEEEEE').margin({ top: 12, bottom: 4 })
        this.PriceRow('合计', this.payAmountText, true)
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
  private PriceRow(label: string, value: string, strong: boolean = false) {
    Row() {
      Text(label).fontSize(14).fontColor('#333333')
      Blank()
      Text(value)
        .fontSize(strong ? 16 : 14)
        .fontWeight(strong ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(strong ? '#E33B3B' : '#333333')
    }.width('100%').margin({ top: 10 })
  }

  @Builder
  private SelectMark(selected: boolean, disabled: boolean = false) {
    Text(selected ? '✓' : '')
      .fontSize(14).fontColor('#FFFFFF').fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
      .width(22).height(22).backgroundColor(disabled ? '#DDDDDD' : (selected ? '#E33B3B' : '#FFFFFF'))
      .border({ width: 1, color: disabled ? '#DDDDDD' : (selected ? '#E33B3B' : '#CCCCCC') }).borderRadius(11)
  }

  @Builder
  private RadioMark(selected: boolean) {
    Text(selected ? '●' : '')
      .fontSize(13).fontColor(selected ? '#E33B3B' : '#FFFFFF').textAlign(TextAlign.Center)
      .width(22).height(22).backgroundColor('#FFFFFF')
      .border({ width: 1, color: selected ? '#E33B3B' : '#CCCCCC' }).borderRadius(11)
  }

  private async loadPageData(): Promise<void> {
    const params: SubmitOrderRouteParams = this.getRouteParams()
    const userId: string = this.getEffectiveUserId(params.userId ?? '')
    const projectId: string = params.projectId ?? ''
    const sessionId: string = params.sessionId ?? ''
    const skuId: string = params.skuId ?? ''
    const quantity: number = params.quantity ?? 1
    if (projectId.length === 0 || sessionId.length === 0 || skuId.length === 0 || quantity <= 0) {
      this.vm.errorMessage = '订单参数不存在'
      this.syncFromVm()
      return
    }
    await this.vm.loadPage(userId, projectId, sessionId, skuId, quantity)
    this.handledAudienceChangedVersion = this.audienceChangedVersion
    this.handledAddressListVersion = this.addressListVersion
    this.handledLoginVersion = this.loginVersion
    this.syncFromVm()
    if (this.vm.consumeInventoryChangedAfterSubmit()) {
      this.returnToTicketSelectAfterInventoryChange(
        this.errorMessage.length > 0 ? this.errorMessage : '当前票档库存不足，请重新选择')
    }
    this.initialLoadCompleted = true
  }

  private async refreshAfterReturn(): Promise<void> {
    if (this.vm.projectId.length === 0) return
    await this.vm.refreshCurrentPurchase()
    this.handledLoginVersion = this.loginVersion
    this.handledAudienceChangedVersion = this.audienceChangedVersion
    this.handledAddressListVersion = this.addressListVersion
    this.syncFromVm()
    if (this.vm.consumeInventoryChangedAfterSubmit()) {
      this.returnToTicketSelectAfterInventoryChange(
        this.errorMessage.length > 0 ? this.errorMessage : '当前票档库存不足，请重新选择')
    }
  }

  private async manualRefreshPurchase(): Promise<void> {
    if (this.isManualRefreshing || this.vm.projectId.length === 0) return
    this.isManualRefreshing = true
    await this.vm.refreshCurrentPurchase()
    this.handledLoginVersion = this.loginVersion
    this.handledAudienceChangedVersion = this.audienceChangedVersion
    this.handledAddressListVersion = this.addressListVersion
    this.syncFromVm()
    this.isManualRefreshing = false
    if (this.vm.consumeInventoryChangedAfterSubmit()) {
      this.returnToTicketSelectAfterInventoryChange(
        this.errorMessage.length > 0 ? this.errorMessage : '当前票档库存不足，请重新选择')
      return
    }
    promptAction.showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '订单信息已刷新' })
  }

  private getRouteParams(): SubmitOrderRouteParams {
    const raw: SubmitOrderRouteParams | undefined = router.getParams() as SubmitOrderRouteParams | undefined
    if (raw !== undefined) {
      if (raw.userId !== undefined) this.routeUserId = raw.userId
      if (raw.projectId !== undefined && raw.projectId.length > 0) this.routeProjectId = raw.projectId
      if (raw.sessionId !== undefined && raw.sessionId.length > 0) this.routeSessionId = raw.sessionId
      if (raw.skuId !== undefined && raw.skuId.length > 0) this.routeSkuId = raw.skuId
      if (raw.quantity !== undefined && raw.quantity > 0) this.routeQuantity = raw.quantity
    }
    return {
      userId: this.routeUserId,
      projectId: this.routeProjectId,
      sessionId: this.routeSessionId,
      skuId: this.routeSkuId,
      quantity: this.routeQuantity
    }
  }


  private returnToTicketSelectAfterInventoryChange(message: string): void {
    AppStorageVersionUtil.bumpTicketSelectRefreshVersion()
    AppStorageVersionUtil.bumpPerformanceChangedVersion()
    promptAction.showToast({ message: message })
    router.back()
  }

  private async selectFulfillment(item: PurchaseFulfillmentOptionVO): Promise<void> {
    await this.vm.selectFulfillmentOption(item.ticketMode, item.deliveryMode, item.optionCode)
    this.syncFromVm()
    this.showActionToastIfNeeded()
  }

  private toggleAudience(audienceId: string): void {
    this.vm.selectAudience(audienceId)
    this.syncFromVm()
    this.showActionToastIfNeeded()
  }

  private async selectAddress(addressId: string): Promise<void> {
    await this.vm.selectAddress(addressId)
    this.syncFromVm()
    this.showActionToastIfNeeded()
  }

  private async createOrder(): Promise<void> {
    const result: QuotedOrderCreateVO | undefined = await this.vm.createOrder()
    this.syncFromVm()
    if (result === undefined) {
      const returnToTicketSelect: boolean = this.vm.consumeInventoryChangedAfterSubmit()
      this.showActionToastIfNeeded()
      if (returnToTicketSelect) {
        // Provider 实时库存已经变化：通知上一层票档页立即刷新，再返回。
        AppStorageVersionUtil.bumpTicketSelectRefreshVersion()
        AppStorageVersionUtil.bumpPerformanceChangedVersion()
        router.back()
      }
      return
    }
    this.createdOrder = result
    this.selectedPayMethod = PayMethod.WECHAT
    this.startPayCountdown()
    this.showPayDialog = true
  }

  private async confirmPay(): Promise<void> {
    if (this.vm.isPaying) return
    const result: OrderActionVO | undefined = await this.vm.payCreatedOrder(this.selectedPayMethod)
    this.syncFromVm()
    if (result === undefined || result.orderStatus !== 'WAIT_USE') {
      this.showPayDialog = false
      this.stopPayCountdown()
      promptAction.showToast({ message: this.actionErrorMessage.length > 0 ? this.actionErrorMessage : '支付失败，请进入订单详情重新支付' })
      return
    }
    this.showPayDialog = false
    this.stopPayCountdown()
    router.pushUrl({
      url: 'pages/order/PaySuccessPage',
      params: { userId: this.vm.userId, orderId: result.orderId, payMethod: this.selectedPayMethod }
    })
  }

  private cancelPayAndGoOrderDetail(): void {
    this.showPayDialog = false
    this.stopPayCountdown()
    if (this.createdOrder === undefined) return
    router.replaceUrl({
      url: 'pages/order/OrderDetailPage',
      params: { userId: this.vm.userId, orderId: this.createdOrder.orderId }
    })
  }

  private handleBottomAction(): void {
    this.createOrder()
  }

  private getBottomButtonText(): string {
    if (this.isCreating) return '正在提交...'
    if (this.priceChangedAwaitingConfirmValue) return '确认新价格并提交'
    return '提交订单'
  }

  private canUseBottomButton(): boolean {
    return !this.isCreating && this.submitDisabledReason.length === 0
  }

  private openAudienceEditPage(): void {
    router.pushUrl({ url: 'pages/user/AudienceEditPage', params: { userId: this.getEffectiveUserId(), from: 'submitOrder' } })
  }

  private openAddressEditPage(): void {
    router.pushUrl({ url: 'pages/user/AddressEditPage', params: { userId: this.getEffectiveUserId(), from: 'submitOrder' } })
  }

  private startPayCountdown(): void {
    this.stopPayCountdown()
    this.updatePayRemainText()
    this.payTimerId = setInterval(() => this.updatePayRemainText(), 1000)
  }

  private stopPayCountdown(): void {
    if (this.payTimerId >= 0) {
      clearInterval(this.payTimerId)
      this.payTimerId = -1
    }
  }

  private updatePayRemainText(): void {
    if (this.createdOrder === undefined || this.createdOrder.payExpireTime.length === 0) {
      this.payRemainText = '15:00'
      return
    }
    const target: number = Date.parse(this.createdOrder.payExpireTime)
    if (target !== target) {
      this.payRemainText = '15:00'
      return
    }
    let remain: number = Math.floor((target - Date.now()) / 1000)
    if (remain < 0) remain = 0
    const minutes: number = Math.floor(remain / 60)
    const seconds: number = remain % 60
    this.payRemainText = this.pad(minutes) + ':' + this.pad(seconds)
  }

  private pad(value: number): string {
    return value < 10 ? '0' + String(value) : String(value)
  }

  private showActionToastIfNeeded(): void {
    if (this.actionErrorMessage.length > 0) promptAction.showToast({ message: this.actionErrorMessage })
  }

  private getEffectiveUserId(routeUserId: string = ''): string {
    const route: string = routeUserId.trim()
    if (route.length > 0) return route
    const vmUser: string = this.vm.userId.trim()
    if (vmUser.length > 0) return vmUser
    return this.userRepository.getCurrentUserId().trim()
  }

  private isAudienceSelected(audienceId: string): boolean {
    return this.selectedAudienceIds.indexOf(audienceId) >= 0
  }

  private isAudienceDisabled(audienceId: string): boolean {
    return this.vm.isAudienceDisabled(audienceId)
  }

  private getAudienceDisabledReason(audienceId: string): string {
    return this.vm.getAudienceDisabledReason(audienceId)
  }

  private isAddressSelected(addressId: string): boolean {
    return this.selectedAddressId === addressId
  }

  private isFulfillmentSelected(item: PurchaseFulfillmentOptionVO): boolean {
    return this.selectedOptionKey === item.optionCode
  }


  private getSkuPriceDetailLabel(): string {
    if (this.selectedSku === undefined) {
      return '票款'
    }
    return this.selectedSku.skuName + ' x ' + String(this.quantityValue)
  }

  private getFulfillmentHint(item: PurchaseFulfillmentOptionVO): string {
    if (item.deliveryMode === 'EXPRESS') {
      return '快递配送 · 需选择收货地址'
    }
    if (item.deliveryMode === 'SELF_PICKUP') {
      return '现场取票 · 演出当天到演出场馆领取'
    }
    return '无需配送'
  }


  private cloneSku(source: TicketSkuSelectVO | undefined): TicketSkuSelectVO | undefined {
    if (source === undefined) return undefined
    return { skuId: source.skuId, skuName: source.skuName, skuDesc: source.skuDesc, price: source.price, skuStatus: source.skuStatus, stockAvailable: source.stockAvailable }
  }

  private cloneTicketSelectPage(source: TicketSelectPageVO | undefined): TicketSelectPageVO | undefined {
    if (source === undefined) return undefined
    return {
      projectId: source.projectId, projectTitle: source.projectTitle,
      session: { sessionId: source.session.sessionId, cityName: source.session.cityName, stationName: source.session.stationName, venueName: source.session.venueName, venueAddress: source.session.venueAddress, startTime: source.session.startTime, sessionStatus: source.session.sessionStatus },
      skus: source.skus.map((item: TicketSkuSelectVO): TicketSkuSelectVO => {
        const cloned: TicketSkuSelectVO = { skuId: item.skuId, skuName: item.skuName, skuDesc: item.skuDesc, price: item.price, skuStatus: item.skuStatus, stockAvailable: item.stockAvailable }
        return cloned
      }),
      limitPerOrder: source.limitPerOrder
    }
  }

  private syncFromVm(): void {
    this.pageVO = this.cloneTicketSelectPage(this.vm.pageVO)
    this.selectedSku = this.cloneSku(this.vm.selectedSku)
    this.audienceList = this.vm.audienceList.slice()
    this.addressList = this.vm.addressList.slice()
    this.fulfillmentOptions = this.vm.fulfillmentOptions.slice()
    this.selectedAudienceIds = this.vm.selectedAudienceIds.slice()
    this.selectedAddressId = this.vm.selectedAddressId
    this.selectedOptionKey = this.vm.selectedFulfillmentOption === undefined ? '' : this.vm.selectedFulfillmentOption.optionCode
    this.createdOrder = this.vm.createdOrder
    this.audienceSelectText = this.vm.getAudienceSelectText()
    this.payAmountText = this.vm.getPayAmountText()
    this.ticketAmountText = this.vm.getTicketAmountText()
    this.deliveryFeeText = this.vm.getDeliveryFeeText()
    this.referencePriceText = this.vm.getReferencePriceText()
    this.priceTipText = this.vm.getPriceTipText()
    this.errorMessage = this.vm.errorMessage
    this.actionErrorMessage = this.vm.actionErrorMessage
    this.submitDisabledReason = this.vm.getSubmitDisabledReason()
    this.isLoading = this.vm.isLoading
    this.isCreating = this.vm.isCreating
    this.quantityValue = this.vm.quantity
    this.requiresAddressValue = this.vm.requiresAddress()
    this.priceChangedAwaitingConfirmValue = this.vm.priceChangedAwaitingConfirm
    this.pageVersion++
  }
}
