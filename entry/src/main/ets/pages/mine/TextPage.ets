import router from '@ohos.router'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface TextPageRouteParams {
  type?: string
}


@Entry
@Component
struct TextPage {
  @State type: string = 'about'

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    const params = router.getParams() as TextPageRouteParams
    this.type = params.type ?? 'about'
  }

  build() {
    Column() {
      this.TopBar()
      Scroll() {
        Text(this.getContent())
          .fontSize(15)
          .fontColor('#333333')
          .lineHeight(24)
          .width('100%')
          .padding(16)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
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

      Text(this.getTitle())
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

  private getTitle(): string {
    if (this.type === 'privacy') return '隐私保护政策'
    if (this.type === 'agreement') return '用户协议'
    return '关于我们'
  }

  private getContent(): string {
    if (this.type === 'privacy') {
      return '麦麦票务隐私保护政策\n\n本项目为鸿蒙票务客户端一期 Mock 演示项目。应用会在本地模拟保存登录状态、搜索历史、观演人、收货地址、订单与电子票等业务数据，用于完成购票闭环展示。真实线上版本应根据法律法规说明数据收集、使用、保存与删除规则。'
    }

    if (this.type === 'agreement') {
      return '麦麦票务用户协议\n\n欢迎使用麦麦票务。本项目一期仅用于客户端业务流程演示，包含浏览演出、选择票档、提交订单、模拟支付、查看电子票与申请退款等流程。真实支付、真实出票、真实检票与后台管理系统不在一期范围内。'
    }

    return '关于麦麦票务\n\n麦麦票务是一个鸿蒙版卖票 APP 示例，使用 Mock 数据驱动，目标是完成从浏览演出、选票、下单、支付、出票、查看电子票到退款的完整客户端业务闭环。'
  }
}
