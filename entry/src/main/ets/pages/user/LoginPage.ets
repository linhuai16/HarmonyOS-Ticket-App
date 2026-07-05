import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { UserViewModel } from '../../viewmodel/UserViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

@Entry
@Component
struct LoginPage {
  private vm: UserViewModel = new UserViewModel()

  @State pageVersion: number = 0
  @State phone: string = ''
  @State smsCode: string = ''

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.phone = ''
    this.smsCode = ''
    this.vm.phone = ''
    this.vm.smsCode = ''
    this.refreshPage()
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()

      Column() {
        Text('手机号登录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .width('100%')
          .margin({ top: 44 })

        Text('未注册手机号验证后自动注册')
          .fontSize(13)
          .fontColor('#999999')
          .width('100%')
          .margin({ top: 8 })

        this.LoginCard()
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 24, right: 24 })
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
        .height(44)
        .fontSize(15)
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .onChange((value: string) => {
          this.phone = value
          this.vm.phone = value
          this.refreshPage()
        })

      Row() {
        TextInput({ placeholder: '请输入验证码', text: this.smsCode })
          .height(44)
          .fontSize(15)
          .layoutWeight(1)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .onChange((value: string) => {
            this.smsCode = value
            this.vm.smsCode = value
            this.refreshPage()
          })

        Button('获取验证码')
          .height(36)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#F04444')
          .borderRadius(18)
          .margin({ left: 10 })
          .onClick(() => {
            this.sendCode()
          })
      }
      .width('100%')
      .margin({ top: 14 })

      Button('登录')
        .height(44)
        .width('100%')
        .fontSize(16)
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
    .padding(18)
    .margin({ top: 34 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 18, color: '#22000000', offsetX: 0, offsetY: 6 })
  }

  private canClickLogin(): boolean {
    const regExp: RegExp = /^1[3-9]\d{9}$/
    return regExp.test(this.phone) && this.smsCode.length > 0
  }

  private sendCode(): void {
    const success: boolean = this.vm.sendSmsCode(this.phone)
    promptAction.showToast({ message: success ? '验证码已发送：123456' : this.vm.errorMessage })
    this.refreshPage()
  }

  private login(): void {
    const success: boolean = this.vm.login(this.phone, this.smsCode)
    if (!success) {
      promptAction.showToast({ message: this.vm.errorMessage })
      this.refreshPage()
      return
    }

    promptAction.showToast({ message: '登录成功' })
    this.refreshPage()
    router.back()
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
