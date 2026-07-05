import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

@Entry
@Component
struct SettingPage {
  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F04444', '#F5F5F5')
  }

  build() {
    Column() {
      this.TopBar()
      Column() {
        this.MenuItem('账号与安全', '账号资料已移至个人主页管理', 'account')
        this.MenuItem('关于', '麦麦票务演示项目', 'about')
        this.MenuItem('麦麦隐私政策', '隐私政策说明', 'privacy')
        this.MenuItem('麦麦用户协议', '用户协议说明', 'agreement')
      }
      .width('100%')
      .margin({ top: 10 })
      .backgroundColor('#FFFFFF')
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

      Text('设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ left: 8 })

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#F04444')
  }

  @Builder
  private MenuItem(title: string, desc: string, type: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#222222')
          .width('100%')
          .textAlign(TextAlign.Start)
        Text(desc)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(58)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.clickMenu(type)
    })
  }

  private clickMenu(type: string): void {
    if (type === 'account') {
      promptAction.showToast({ message: '请在我的页点击个人主页管理账号资料' })
      return
    }

    router.pushUrl({
      url: 'pages/mine/TextPage',
      params: {
        type: type
      }
    })
  }
}
