import { PayMethod } from "../model/enums/PayMethod"

@Component
export struct PayOrderDialog {
  @Prop payAmount: number
  @Prop payExpireText: string
  @Prop selectedPayMethod: PayMethod

  onPayMethodChange: (payMethod: PayMethod) => void = (payMethod: PayMethod): void => {}
  onConfirmPay: () => void = (): void => {}
  onCancelPay: () => void = (): void => {}

  build() {
    Column() {
      Blank()
        .layoutWeight(1)
        .onClick(() => {
          this.onCancelPay()
        })

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
            .onClick(() => {
              this.onCancelPay()
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
            .onClick(() => {
              this.onCancelPay()
            })

          Button('立即支付')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#E33B3B')
            .borderRadius(24)
            .margin({ left: 12 })
            .onClick(() => {
              this.onConfirmPay()
            })
        }
        .width('100%')
        .margin({ top: 22 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 20, bottom: 28 })
      .backgroundColor('#F7F7F7')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
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
    .onClick(() => {
      this.onPayMethodChange(payMethod)
    })
  }
}
