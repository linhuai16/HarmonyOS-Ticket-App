import { UserViewModel } from '../../viewmodel/UserViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'

@Entry
@Component
struct LoginPage {
  private vm: UserViewModel = new UserViewModel()

  @State pageVersion: number = 0
  @State phone: string = ''
  @State smsCode: string = ''
  @State breakPoint: string = 'sm'
  @State isSendingCode: boolean = false
  @State isLoggingIn: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.phone = ''
    this.smsCode = ''
    this.vm.phone = ''
    this.vm.smsCode = ''
    this.refreshPage()
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
          this.RefreshMarker()
          this.TopBar()

          Scroll() {
            Column() {
              Text('手机号登录')
                .fontSize(this.isTabletLayout() ? 30 : 24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#222222')
                .width('100%')
                .margin({ top: this.isTabletLayout() ? 28 : 44 })

              Text('未注册手机号验证后自动注册')
                .fontSize(this.isTabletLayout() ? 15 : 13)
                .fontColor('#999999')
                .width('100%')
                .margin({ top: 10 })

              this.LoginCard()
            }
            .width(this.isTabletLayout() ? '72%' : '100%')
            .constraintSize({ maxWidth: ResponsiveLayout.FORM_MAX_WIDTH })
            .padding({
              left: this.isTabletLayout() ? 0 : 24,
              right: this.isTabletLayout() ? 0 : 24,
              bottom: 32
            })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .layoutWeight(1)
          .align(Alignment.Top)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFFFF')
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
      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 12 })
  }

  @Builder
  private LoginCard() {
    Column() {
      TextInput({ placeholder: '请输入手机号', text: this.phone })
        .height(this.isTabletLayout() ? 52 : 44)
        .fontSize(this.isTabletLayout() ? 17 : 15)
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .onChange((value: string) => {
          this.phone = value
          this.vm.phone = value
          this.refreshPage()
        })

      Row() {
        TextInput({ placeholder: '请输入验证码', text: this.smsCode })
          .height(this.isTabletLayout() ? 52 : 44)
          .fontSize(this.isTabletLayout() ? 17 : 15)
          .layoutWeight(1)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .onChange((value: string) => {
            this.smsCode = value
            this.vm.smsCode = value
            this.refreshPage()
          })

        Button(this.isSendingCode ? '发送中...' : '获取验证码')
          .height(this.isTabletLayout() ? 42 : 36)
          .fontSize(this.isTabletLayout() ? 15 : 13)
          .fontColor('#FFFFFF')
          .backgroundColor(this.canSendCode() ? '#F04444' : '#CCCCCC')
          .borderRadius(18)
          .margin({ left: 10 })
          .enabled(this.canSendCode())
          .onClick(() => {
            this.sendCode()
          })
      }
      .width('100%')
      .margin({ top: 14 })

      Button(this.isLoggingIn ? '登录中...' : '登录')
        .height(this.isTabletLayout() ? 52 : 44)
        .width('100%')
        .fontSize(this.isTabletLayout() ? 17 : 16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.canClickLogin() ? '#E33B3B' : '#FFD6C2')
        .borderRadius(22)
        .margin({ top: 26 })
        .enabled(this.canClickLogin())
        .onClick(() => {
          this.login()
        })

      Text('测试验证码：123456')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 12 })

      Text('登录即表示同意《用户协议》和《隐私政策》')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 24 : 18)
    .margin({ top: this.isTabletLayout() ? 28 : 34 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 18, color: '#22000000', offsetX: 0, offsetY: 6 })
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private canClickLogin(): boolean {
    const regExp: RegExp = /^1[3-9]\d{9}$/
    return !this.isLoggingIn && regExp.test(this.phone) && this.smsCode.length > 0
  }

  private canSendCode(): boolean {
    const regExp: RegExp = /^1[3-9]\d{9}$/
    return !this.isSendingCode && regExp.test(this.phone)
  }

  private async sendCode(): Promise<void> {
    if (!this.canSendCode()) {
      return
    }
    this.isSendingCode = true
    const success: boolean = await this.vm.sendSmsCode(this.phone)
    this.isSendingCode = false
    this.getUIContext().getPromptAction().showToast({ message: success ? '验证码已发送：123456' : this.vm.errorMessage })
    this.refreshPage()
  }

  private async login(): Promise<void> {
    if (!this.canClickLogin()) {
      return
    }
    this.isLoggingIn = true
    const success: boolean = await this.vm.login(this.phone, this.smsCode)
    this.isLoggingIn = false
    if (!success) {
      this.getUIContext().getPromptAction().showToast({ message: this.vm.errorMessage })
      this.refreshPage()
      return
    }

    this.getUIContext().getPromptAction().showToast({ message: '登录成功' })
    this.refreshPage()
    this.getUIContext().getRouter().back()
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
