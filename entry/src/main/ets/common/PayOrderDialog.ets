import { PayMethod } from "../model/enums/PayMethod"
import { ResponsiveLayout } from './ResponsiveLayout'

@Component
export struct PayOrderDialog {
  @Prop payAmount: number
  @Prop payExpireText: string
  @Prop selectedPayMethod: PayMethod
  @Prop isTablet: boolean = false
  @Prop isPaying: boolean = false

  onPayMethodChange: (payMethod: PayMethod) => void = (payMethod: PayMethod): void => {}
  onConfirmPay: () => void = (): void => {}
  onCancelPay: () => void = (): void => {}

  build() {
    if (this.isTablet) {
      Stack({ alignContent: Alignment.Center }) {
        Row() {
        }
          .width('100%')
          .height('100%')
          .enabled(!this.isPaying)
          .onClick(() => {
            if (!this.isPaying) this.onCancelPay()
          })

        this.PaymentPanel(true)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
    } else {
      Column() {
        Blank()
          .layoutWeight(1)
          .enabled(!this.isPaying)
          .onClick(() => {
            if (!this.isPaying) this.onCancelPay()
          })

        this.PaymentPanel(false)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
    }
  }

  @Builder
  private PaymentPanel(isTablet: boolean) {
    Column() {
        Row() {
          Blank().width(24)

          Text('支付订单')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Text('×')
            .fontSize(28)
            .fontColor('#666666')
            .width(24)
            .textAlign(TextAlign.Center)
            .enabled(!this.isPaying)
            .onClick(() => {
              if (!this.isPaying) this.onCancelPay()
            })
        }
        .width('100%')

        Text('支付剩余时间 ' + this.payExpireText)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 18 })

        Text('￥' + this.payAmount)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 12, bottom: 22 })

        Text('支付方式')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })

        Column() {
          this.PayMethodRow('微信支付', PayMethod.WECHAT, '#22C55E')
          Divider().color('#EEEEEE').margin({ left: 44 })
          this.PayMethodRow('支付宝', PayMethod.ALIPAY, '#1677FF')
          Divider().color('#EEEEEE').margin({ left: 44 })
          this.PayMethodRow('云闪付', PayMethod.OTHER, '#E33B3B')
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)

        Row() {
          Button('取消支付')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .border({ width: 1, color: '#DDDDDD' })
            .enabled(!this.isPaying)
            .onClick(() => {
              this.onCancelPay()
            })

          Button(this.isPaying ? '支付中...' : '立即支付')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isPaying ? '#CCCCCC' : '#E33B3B')
            .borderRadius(24)
            .margin({ left: 12 })
            .enabled(!this.isPaying)
            .onClick(() => {
              this.onConfirmPay()
            })
        }
        .width('100%')
        .margin({ top: 22 })
    }
    .width('100%')
    .constraintSize({ maxWidth: ResponsiveLayout.DIALOG_MAX_WIDTH })
    .padding({ left: isTablet ? 32 : 24, right: isTablet ? 32 : 24, top: isTablet ? 28 : 20, bottom: isTablet ? 30 : 28 })
    .backgroundColor('#F7F7F7')
    .borderRadius(isTablet ? 20 : { topLeft: 20, topRight: 20 })
  }

  @Builder
  private PayMethodRow(title: string, payMethod: PayMethod, color: string) {
    Row() {
      Text('')
        .width(18)
        .height(18)
        .backgroundColor(color)
        .borderRadius(9)

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .margin({ left: 12 })
        .layoutWeight(1)

      Radio({ value: payMethod, group: 'pay_method' })
        .checked(this.selectedPayMethod === payMethod)
    }
    .width('100%')
    .height(54)
    .padding({ left: 12, right: 12 })
    .enabled(!this.isPaying)
    .onClick(() => {
      this.onPayMethodChange(payMethod)
    })
  }
}
