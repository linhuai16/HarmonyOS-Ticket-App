import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'

@Entry
@Component
struct SettingPage {
  @State breakPoint: string = 'sm'
  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F04444', '#F5F5F5')
  }

  build() {
    GridRow({
        columns: { sm: 4, md: 8, lg: 12, xl: 12 },
      breakpoints: {
          value: ['600vp', '840vp', '1440vp'],
        reference: BreakpointsReference.WindowSize
      }
    }) {
        GridCol({ span: { sm: 4, md: 8, lg: 12, xl: 12 } }) {
        Column() {
          this.TopBar()
          Column() {
            this.MenuItem('账号与安全', '账号资料已移至个人主页管理', 'account')
            this.MenuItem('关于', '麦麦票务演示项目', 'about')
            this.MenuItem('麦麦隐私政策', '隐私政策说明', 'privacy')
            this.MenuItem('麦麦用户协议', '用户协议说明', 'agreement')
          }
          .width(this.isTabletLayout() ? '72%' : '100%')
          .constraintSize({ maxWidth: ResponsiveLayout.FORM_MAX_WIDTH })
          .margin({ top: this.isTabletLayout() ? 10 : 10 })
          .backgroundColor('#FFFFFF')
          .borderRadius(this.isTabletLayout() ? 14 : 0)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('100%')
    .onBreakpointChange((breakpoint: string) => {
      this.breakPoint = breakpoint
    })
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
          this.getUIContext().getRouter().back()
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
          .fontSize(this.isTabletLayout() ? 17 : 15)
          .fontColor('#222222')
          .width('100%')
          .textAlign(TextAlign.Start)
        Text(desc)
          .fontSize(this.isTabletLayout() ? 14 : 12)
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
    .height(this.isTabletLayout() ? 72 : 58)
    .padding({ left: this.isTabletLayout() ? 22 : 16, right: this.isTabletLayout() ? 22 : 16 })
    .onClick(() => {
      this.clickMenu(type)
    })
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private clickMenu(type: string): void {
    if (type === 'account') {
      this.getUIContext().getPromptAction().showToast({ message: '请在我的页点击个人主页管理账号资料' })
      return
    }

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/mine/TextPage',
      params: {
        type: type
      }
    })
  }
}
