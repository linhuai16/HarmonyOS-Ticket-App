import { AppNavigator, TicketSelectNavParams } from '../../navigation/AppNavigation'

import {
  TicketSelectPageVO,
  TicketSkuSelectVO
} from '../../model/vo/performance/TicketSelectPageVO'

import {
  TicketSelectViewModel,
  TicketSelectConfirmParams
} from '../../viewmodel/TicketSelectViewModel'

import { SkuStatus } from '../../model/enums/SkuStatus'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'

@Entry
@Component
export struct TicketSelectPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: TicketSelectNavParams = {}

  private vm: TicketSelectViewModel = new TicketSelectViewModel()

  @State pageVersion: number = 0
  @State showPriceDetail: boolean = false
  @State pageVO: TicketSelectPageVO | undefined = undefined
  @State selectedSkuId: string = ''
  @State quantity: number = 1
  @State totalAmount: number = 0
  @State selectedSkuName: string = ''
  @State canConfirmValue: boolean = false
  @State canIncreaseQuantityValue: boolean = false
  @State canDecreaseQuantityValue: boolean = false
  @State errorMessage: string = ''
  @State isRefreshing: boolean = false
  @State isLoading: boolean = false
  @State breakPoint: string = 'sm'
  @State skuGridWidth: number = 0
  @StorageLink('ticket_select_refresh_version') @Watch('onTicketSelectRefreshRequested') ticketSelectRefreshVersion: number = 0
  @StorageLink('performance_changed_version') @Watch('onPerformanceChanged') performanceChangedVersion: number = 0

  private initialLoadCompleted: boolean = false
  private isRefreshingAfterReturn: boolean = false
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false
  private hasShownOnce: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    const params: TicketSelectNavParams = this.navParams
    this.initPage(params)
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    if (this.hasShownOnce && this.initialLoadCompleted) {
      this.pendingExternalRefresh = false
      this.refreshAfterReturn()
    }
    this.hasShownOnce = true
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  build() {
    NavDestination() {
      GridRow({
        columns: { sm: 4, md: 8, lg: 12, xl: 12 },
        breakpoints: {
          value: ['600vp', '840vp', '1440vp'],
          reference: BreakpointsReference.WindowSize
        }
      }) {
        GridCol({ span: { sm: 4, md: 8, lg: 12, xl: 12 } }) {
          Stack({ alignContent: Alignment.Bottom }) {
            Column() {
              this.RefreshMarker()
              this.TopBar()

              if (this.pageVO === undefined) {
                this.EmptyArea()
              } else {
                Scroll() {
                  Column() {
                    this.ProjectTitle()
                    if (this.isTabletLayout()) {
                      this.TabletTicketSelectionContent()
                    } else {
                      this.SessionArea()
                      this.SkuArea()
                      this.QuantityArea()
                    }
                    Blank().height(88)
                  }
                  .width('100%')
                  .constraintSize({ maxWidth: ResponsiveLayout.WORKFLOW_MAX_WIDTH })
                  .padding({
                    left: this.isTabletLayout() ? 0 : 12,
                    right: this.isTabletLayout() ? 0 : 12,
                    bottom: 12
                  })
                }
                .width('100%')
                .layoutWeight(1)
                .align(Alignment.Top)
              }
            }
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#F5F5F5')

            this.BottomBar()

            if (this.showPriceDetail) {
              this.PriceDetailPanel()
            }
          }
          .width('100%')
          .height('100%')
        }
      }
      .width('100%')
      .height('100%')
      .onBreakpointChange((breakpoint: string) => {
        this.breakPoint = breakpoint
      })
    }
    .hideTitleBar(true)
    .onShown(() => {
      this.onPageShow()
    })
    .onHidden(() => { this.onPageHide() })
  }

  @Builder
  private TopBar() {
    Row() {
      Row() {
        Image($r('app.media.fanhui'))
          .width(22)
          .height(22)
      }
      .width(36)
      .height(44)
      .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.navStack.pop()
        })

      Text('选择票档')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4 })

      Blank()

      Button() {
        Image($r('app.media.refrech'))
          .width(18)
          .height(18)
          .fillColor(this.isRefreshing ? '#BBBBBB' : '#666666')
      }
        .width(40)
        .height(40)
        .backgroundColor('#00000000')
        .enabled(!this.isRefreshing && !this.isLoading)
        .onClick(() => {
          if (!this.isRefreshing && !this.isLoading) {
            this.refreshTicketSelect(true)
          }
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
        LoadingProgress()
          .width(32)
          .height(32)
          .color('#E33B3B')
        Text('正在加载票档...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 10 })
      } else {
        Text(this.errorMessage.length > 0 ? '票档加载失败，请点击右上角重试' : '票档数据不存在')
          .fontSize(15)
          .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
          .textAlign(TextAlign.Center)
          .padding({ left: 24, right: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private TabletTicketSelectionContent() {
    Row({ space: 16 }) {
      Column() {
        this.SessionArea()
        this.QuantityArea()
      }
      .width(300)

      Column() {
        this.SkuArea()
      }
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private ProjectTitle() {
    Column() {
      Text((this.pageVO as TicketSelectPageVO).projectTitle)
        .fontSize(this.isTabletLayout() ? 20 : 17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text((this.pageVO as TicketSelectPageVO).session.stationName + ' · ' + (this.pageVO as TicketSelectPageVO).session.venueName)
        .fontSize(this.isTabletLayout() ? 15 : 13)
        .fontColor('#666666')
        .margin({ top: 8 })
        .width('100%')

      Text((this.pageVO as TicketSelectPageVO).session.startTime)
        .fontSize(this.isTabletLayout() ? 15 : 13)
        .fontColor('#666666')
        .margin({ top: 6 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 8 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private SessionArea() {
    Column() {
      Text('当前场次')
        .fontSize(this.isTabletLayout() ? 19 : 16)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Column() {
        Text((this.pageVO as TicketSelectPageVO).session.stationName)
          .fontSize(this.isTabletLayout() ? 16 : 14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E33B3B')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text((this.pageVO as TicketSelectPageVO).session.startTime)
          .fontSize(this.isTabletLayout() ? 14 : 12)
          .fontColor('#666666')
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text((this.pageVO as TicketSelectPageVO).session.venueName)
          .fontSize(this.isTabletLayout() ? 14 : 12)
          .fontColor('#666666')
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .width(this.isTabletLayout() ? 220 : 150)
      .padding(this.isTabletLayout() ? 16 : 12)
      .margin({ top: 10 })
      .backgroundColor('#FFECEC')
      .borderRadius(10)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 16 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private SkuArea() {
    Column() {
      Text('选择票档')
        .fontSize(this.isTabletLayout() ? 20 : 17)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Grid() {
        ForEach((this.pageVO as TicketSelectPageVO).skus, (item: TicketSkuSelectVO) => {
          GridItem() {
            Column() {
              Text(item.skuName)
                .fontSize(this.isTabletLayout() ? 17 : 15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.canChooseSku(item) ? '#222222' : '#999999')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (item.skuDesc !== undefined) {
                Text(item.skuDesc)
                  .fontSize(12)
                  .fontColor('#888888')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
              }

              Text('￥' + item.price)
                .fontSize(this.isTabletLayout() ? 18 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.canChooseSku(item) ? '#E33B3B' : '#999999')
                .margin({ top: 6 })

              Text(this.getSkuStatusText(item))
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .width('100%')
            .height(this.isTabletLayout() ? 116 : 94)
            .padding(this.isTabletLayout() ? 14 : 10)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.getSkuCardBackground(item))
            .borderRadius(10)
            .opacity(1)
            .onClick(() => {
              if (this.canChooseSku(item)) {
                this.vm.selectSku(item.skuId)
                this.syncFromVm()
              }
            })
          }
        }, (item: TicketSkuSelectVO) => item.skuId + '_' + item.skuStatus + '_' + String(item.stockAvailable ?? 'UNKNOWN') + '_' + String(item.price) + '_' + String(this.pageVersion))
      }
      .columnsTemplate(ResponsiveLayout.getGridTemplate(this.getSkuGridColumnCount()))
      .columnsGap(this.isTabletLayout() ? 14 : 8)
      .rowsGap(this.isTabletLayout() ? 14 : 8)
      .margin({ top: 10 })
      .width('100%')
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const nextWidth: number = Number(newValue.width ?? 0)
        if (Math.abs(nextWidth - this.skuGridWidth) > 0.5) {
          this.skuGridWidth = nextWidth
        }
      })
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 16 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private QuantityArea() {
    Column() {
      Text('购买数量')
        .fontSize(this.isTabletLayout() ? 20 : 17)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Row() {
        Text('每单限购 ' + (this.pageVO as TicketSelectPageVO).limitPerOrder + ' 张')
          .fontSize(13)
          .fontColor('#666666')

        Blank()

        this.CountButton('-', false)

        Text(this.quantity.toString())
          .fontSize(15)
          .fontColor('#222222')
          .width(40)
          .textAlign(TextAlign.Center)

        this.CountButton('+', true)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 16 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private CountButton(text: string, isIncrease: boolean) {
    Row() {
      Text(text)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isCountButtonEnabled(isIncrease) ? '#333333' : '#CCCCCC')
        .width('100%')
        .height('100%')
        .textAlign(TextAlign.Center)
    }
    .width(32)
    .height(32)
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.isCountButtonEnabled(isIncrease) ? '#F0F0F0' : '#F7F7F7')
    .onClick(() => {
      this.handleCountClick(isIncrease)
    })
  }

  @Builder
  private BottomBar() {
    Column() {
      Row() {
        Column() {
          Text(this.getTotalAmountText())
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.canConfirmValue ? '#E33B3B' : '#CCCCCC')

          Row() {
            Text('价格明细')
              .fontSize(12)
              .fontColor('#666666')
            Image($r('app.media.page_xiala_shang'))
              .width(12)
              .height(12)
              .margin({ left: 4 })
          }
          .margin({ top: 2 })
          .onClick(() => {
            this.showPriceDetail = true
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('确认')
          .height(this.isTabletLayout() ? 50 : 44)
          .width(this.isTabletLayout() ? 180 : 130)
          .fontSize(this.isTabletLayout() ? 17 : 16)
          .backgroundColor(this.canConfirmValue ? '#E33B3B' : '#CCCCCC')
          .fontColor('#FFFFFF')
          .borderRadius(22)
          .enabled(this.canConfirmValue)
          .onClick(() => {
            this.confirmTicket()
          })
      }
      .width('100%')
      .constraintSize({ maxWidth: ResponsiveLayout.WORKFLOW_MAX_WIDTH })
      .height(this.isTabletLayout() ? 76 : 68)
      .padding({ left: this.isTabletLayout() ? 20 : 12, right: this.isTabletLayout() ? 20 : 12, top: 8, bottom: 8 })
    }
    .width('100%')
    .height(this.isTabletLayout() ? 76 : 68)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private PriceDetailPanel() {
    Stack({ alignContent: this.isTabletLayout() ? Alignment.Center : Alignment.Bottom }) {
      Column() {}
        .width('100%')
        .height('100%')
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

        if (this.selectedSkuId.length > 0) {
          Row() {
            Text(this.selectedSkuName + ' x ' + this.quantity)
              .fontSize(14)
              .fontColor('#333333')

            Blank()

            Text('￥' + this.totalAmount)
              .fontSize(14)
              .fontColor('#333333')
          }
          .width('100%')
          .margin({ top: 16 })

          Row() {
            Text('票面参考')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)

            Blank()

            Text('￥' + this.totalAmount)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E33B3B')
          }
          .width('100%')
          .margin({ top: 16 })
        } else {
          Text('请选择票档')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 16 })
            .width('100%')
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: ResponsiveLayout.DIALOG_MAX_WIDTH })
      .padding(this.isTabletLayout() ? 28 : 20)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }


  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private getSkuGridColumnCount(): number {
    if (!this.isTabletLayout()) {
      return 2
    }
    return Math.min(3, ResponsiveLayout.getTabletGridColumnCount(this.skuGridWidth))
  }

  private async initPage(params: TicketSelectNavParams): Promise<void> {
    const projectId: string = params.projectId ?? ''
    const selectedSessionId: string = params.selectedSessionId ?? params.sessionId ?? ''

    if (projectId.length === 0 || selectedSessionId.length === 0) {
      this.vm.errorMessage = '票档参数不存在'
      this.syncFromVm()
      return
    }

    this.isLoading = true
    await this.vm.loadPage(projectId, selectedSessionId)
    this.syncFromVm()
    this.initialLoadCompleted = true
  }

  private async refreshAfterReturn(): Promise<void> {
    await this.refreshTicketSelect(false)
  }

  private onTicketSelectRefreshRequested(): void {
    if (!this.initialLoadCompleted) return
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.refreshTicketSelect(false)
  }

  private onPerformanceChanged(): void {
    if (!this.initialLoadCompleted) return
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.refreshTicketSelect(false)
  }

  private async refreshTicketSelect(showToast: boolean): Promise<void> {
    if (this.isRefreshingAfterReturn || this.vm.projectId.length === 0 || this.vm.selectedSessionId.length === 0) {
      return
    }
    this.isRefreshingAfterReturn = true
    this.isRefreshing = true
    try {
      await this.vm.loadPage(this.vm.projectId, this.vm.selectedSessionId)
      this.syncFromVm()
      if (showToast) {
        this.getUIContext().getPromptAction().showToast({
          message: this.errorMessage.length > 0 ? this.errorMessage : '票档已刷新'
        })
      }
    } finally {
      this.isRefreshing = false
      this.isRefreshingAfterReturn = false
    }
  }

  private handleCountClick(isIncrease: boolean): void {
    if (!this.isCountButtonEnabled(isIncrease)) {
      return
    }

    if (isIncrease) {
      this.vm.increaseQuantity()
    } else {
      this.vm.decreaseQuantity()
    }

    this.syncFromVm()
  }

  private isCountButtonEnabled(isIncrease: boolean): boolean {
    if (isIncrease) {
      return this.canIncreaseQuantityValue
    }

    return this.canDecreaseQuantityValue
  }

  private confirmTicket(): void {
    const params: TicketSelectConfirmParams | undefined = this.vm.buildConfirmParams()

    if (params === undefined) {
      this.getUIContext().getPromptAction().showToast({ message: '请选择票档和数量' })
      return
    }

    AppNavigator.openSubmitOrder(this.navStack, {
      projectId: params.projectId,
      sessionId: params.sessionId,
      skuId: params.skuId,
      quantity: params.quantity,
      userId: this.navParams.userId
    })
  }

  private getTotalAmountText(): string {
    if (this.selectedSkuId.length === 0) {
      return '￥0'
    }

    return '参考 ￥' + this.totalAmount
  }

  private getSkuStatusText(item: TicketSkuSelectVO): string {
    // 显式库存 0 优先于旧的 skuStatus 快照。这样“不可点击”和卡片文案/置灰始终一致。
    if (this.isExplicitlySoldOut(item)) return '已售罄'
    if ((item.skuStatus === SkuStatus.ON_SALE || item.skuStatus === SkuStatus.PRESALE) &&
      item.stockAvailable === undefined) {
      return '库存待实时确认'
    }
    if (item.skuStatus === SkuStatus.PRESALE) return '预售中'
    if (item.skuStatus === SkuStatus.ON_SALE) return '可购买'
    return '不可购买'
  }

  private canChooseSku(item: TicketSkuSelectVO): boolean {
    if (this.isExplicitlySoldOut(item)) {
      return false
    }
    if (item.skuStatus !== SkuStatus.ON_SALE && item.skuStatus !== SkuStatus.PRESALE) {
      return false
    }

    // undefined 是第三方未提供精确库存，不等于0/售罄。
    return true
  }

  private isExplicitlySoldOut(item: TicketSkuSelectVO): boolean {
    return item.skuStatus === SkuStatus.SOLD_OUT ||
      (item.stockAvailable !== undefined && item.stockAvailable <= 0)
  }

  private getSkuCardBackground(item: TicketSkuSelectVO): string {
    if (!this.canChooseSku(item)) return '#EFEFEF'
    if (this.selectedSkuId === item.skuId) return '#FFECEC'
    return '#F7F7F7'
  }

  private syncFromVm(): void {
    this.pageVO = this.clonePageVO(this.vm.pageVO)
    this.selectedSkuId = this.vm.selectedSkuId
    this.quantity = this.vm.quantity
    this.totalAmount = this.vm.getTotalAmount()
    this.selectedSkuName = this.vm.getSelectedSkuName()
    this.canConfirmValue = this.vm.canConfirm()
    this.canIncreaseQuantityValue = this.vm.canIncreaseQuantity()
    this.canDecreaseQuantityValue = this.vm.canDecreaseQuantity()
    this.errorMessage = this.vm.errorMessage
    this.isLoading = this.vm.isLoading
    this.refreshPage()
  }


  private clonePageVO(source: TicketSelectPageVO | undefined): TicketSelectPageVO | undefined {
    if (source === undefined) return undefined
    const skus: TicketSkuSelectVO[] = source.skus.map((item: TicketSkuSelectVO): TicketSkuSelectVO => {
      return {
        skuId: item.skuId,
        skuName: item.skuName,
        skuDesc: item.skuDesc,
        price: item.price,
        skuStatus: item.skuStatus,
        stockAvailable: item.stockAvailable
      }
    })
    return {
      projectId: source.projectId,
      projectTitle: source.projectTitle,
      session: {
        sessionId: source.session.sessionId,
        cityName: source.session.cityName,
        stationName: source.session.stationName,
        venueName: source.session.venueName,
        venueAddress: source.session.venueAddress,
        startTime: source.session.startTime,
        sessionStatus: source.session.sessionStatus
      },
      skus: skus,
      limitPerOrder: source.limitPerOrder
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
