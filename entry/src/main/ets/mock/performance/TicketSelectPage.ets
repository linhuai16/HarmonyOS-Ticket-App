import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  TicketSelectPageVO,
  TicketSkuSelectVO
} from '../../model/vo/performance/TicketSelectPageVO'

import {
  TicketSelectViewModel,
  TicketSelectConfirmParams
} from '../../viewmodel/TicketSelectViewModel'

import { SkuStatus } from '../../model/enums/SkuStatus'

interface TicketSelectRouteParams {
  projectId?: string
  selectedSessionId?: string
  sessionId?: string
  userId?: string
}

@Entry
@Component
export struct TicketSelectPage {
  private vm: TicketSelectViewModel = new TicketSelectViewModel()

  @State pageVO: TicketSelectPageVO | undefined = undefined
  @State selectedSkuId: string = ''
  @State quantity: number = 1
  @State totalAmount: number = 0
  @State selectedSkuName: string = ''
  @State canConfirmOrder: boolean = false
  @State canAddQuantity: boolean = false
  @State canMinusQuantity: boolean = false
  @State errorMessage: string = ''
  @State showPriceDetail: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as TicketSelectRouteParams

    const projectId: string = params.projectId ?? ''
    const selectedSessionId: string = params.selectedSessionId ?? params.sessionId ?? ''

    if (projectId.length === 0 || selectedSessionId.length === 0) {
      this.errorMessage = '票档参数不存在'
      return
    }

    this.vm.loadPage(projectId, selectedSessionId)
    this.syncFromVm()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.TopBar()

        if (this.pageVO === undefined) {
          this.EmptyArea()
        } else {
          Scroll() {
            Column() {
              this.ProjectTitle(this.pageVO)
              this.SessionArea(this.pageVO)
              this.SkuArea(this.pageVO)
              this.QuantityArea(this.pageVO)
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

      Text('选择票档')
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
      Text(this.errorMessage.length > 0 ? this.errorMessage : '票档数据不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private ProjectTitle(pageVO: TicketSelectPageVO) {
    Column() {
      Text(pageVO.projectTitle)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(pageVO.session.stationName + ' · ' + pageVO.session.venueName)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 8 })
        .width('100%')

      Text(pageVO.session.startTime)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 6 })
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
  private SessionArea(pageVO: TicketSelectPageVO) {
    Column() {
      Text('当前场次')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Column() {
        Text(pageVO.session.stationName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E33B3B')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(pageVO.session.startTime)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(pageVO.session.venueName)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .width(150)
      .padding(12)
      .margin({ top: 10 })
      .backgroundColor('#FFECEC')
      .borderRadius(10)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private SkuArea(pageVO: TicketSelectPageVO) {
    Column() {
      Text('选择票档')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Grid() {
        ForEach(pageVO.skus, (item: TicketSkuSelectVO) => {
          GridItem() {
            Column() {
              Text(item.skuName)
                .fontSize(15)
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
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.canChooseSku(item) ? '#E33B3B' : '#999999')
                .margin({ top: 6 })

              Text(this.getSkuStatusText(item))
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .width('100%')
            .height(94)
            .padding(10)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.selectedSkuId === item.skuId ? '#FFECEC' : '#F7F7F7')
            .borderRadius(10)
            .border({
              width: this.selectedSkuId === item.skuId ? 1 : 0,
              color: this.selectedSkuId === item.skuId ? '#E33B3B' : '#00000000'
            })
            .opacity(this.canChooseSku(item) ? 1 : 0.5)
            .onClick(() => {
              if (!this.canChooseSku(item)) {
                return
              }

              this.vm.selectSku(item.skuId)
              this.syncFromVm()
            })
          }
        }, (item: TicketSkuSelectVO) => item.skuId)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
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
  private QuantityArea(pageVO: TicketSelectPageVO) {
    Column() {
      Text('购买数量')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Row() {
        Text('每单限购 ' + pageVO.limitPerOrder + ' 张')
          .fontSize(13)
          .fontColor('#666666')

        Blank()

        this.CountButton('-', this.canMinusQuantity, false)

        Text(this.quantity.toString())
          .fontSize(15)
          .fontColor('#222222')
          .width(40)
          .textAlign(TextAlign.Center)

        this.CountButton('+', this.canAddQuantity, true)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private CountButton(text: string, enabled: boolean, isIncrease: boolean) {
    Text(text)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(enabled ? '#333333' : '#CCCCCC')
      .width(28)
      .height(28)
      .textAlign(TextAlign.Center)
      .backgroundColor(enabled ? '#F0F0F0' : '#F7F7F7')
      .borderRadius(14)
      .onClick(() => {
        if (!enabled) {
          return
        }

        if (isIncrease) {
          this.vm.increaseQuantity()
        } else {
          this.vm.decreaseQuantity()
        }

        this.syncFromVm()
      })
  }

  @Builder
  private BottomBar() {
    Row() {
      Column() {
        Text(this.getTotalAmountText())
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.canConfirmOrder ? '#E33B3B' : '#CCCCCC')

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
        .height(44)
        .width(130)
        .fontSize(16)
        .backgroundColor(this.canConfirmOrder ? '#E33B3B' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .borderRadius(22)
        .enabled(this.canConfirmOrder)
        .onClick(() => {
          this.confirmTicket()
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
            Text('合计')
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
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 18, topRight: 18 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }

  private confirmTicket(): void {
    const params: TicketSelectConfirmParams | undefined = this.vm.buildConfirmParams()

    if (params === undefined) {
      promptAction.showToast({ message: '请选择票档和数量' })
      this.syncFromVm()
      return
    }

    router.pushUrl({
      url: 'pages/order/SubmitOrderPage',
      params: {
        projectId: params.projectId,
        sessionId: params.sessionId,
        skuId: params.skuId,
        quantity: params.quantity
      }
    })
  }

  private getTotalAmountText(): string {
    if (this.selectedSkuId.length === 0) {
      return '￥0'
    }

    return '￥' + this.totalAmount
  }

  private getSkuStatusText(item: TicketSkuSelectVO): string {
    if (item.skuStatus === SkuStatus.PRESALE) return '预售中'
    if (item.skuStatus === SkuStatus.ON_SALE) return '可购买'
    if (item.skuStatus === SkuStatus.SOLD_OUT) return '已售罄'
    return '不可购买'
  }

  private canChooseSku(item: TicketSkuSelectVO): boolean {
    if (item.skuStatus !== SkuStatus.ON_SALE && item.skuStatus !== SkuStatus.PRESALE) {
      return false
    }

    return (item.stockAvailable ?? 0) > 0
  }

  private syncFromVm(): void {
    this.pageVO = this.vm.pageVO
    this.selectedSkuId = this.vm.selectedSkuId
    this.quantity = this.vm.quantity
    this.totalAmount = this.vm.getTotalAmount()
    this.selectedSkuName = this.vm.getSelectedSkuName()
    this.canConfirmOrder = this.vm.canConfirm()
    this.canAddQuantity = this.vm.canIncreaseQuantity()
    this.canMinusQuantity = this.vm.canDecreaseQuantity()
    this.errorMessage = this.vm.errorMessage
  }
}
