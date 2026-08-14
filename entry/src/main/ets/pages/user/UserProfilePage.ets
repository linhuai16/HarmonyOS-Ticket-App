import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { photoAccessHelper } from '@kit.MediaLibraryKit'

import { UserViewModel } from '../../viewmodel/UserViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface UserProfileRouteParams {
  userId?: string
}


@Entry
@Component
struct UserProfilePage {
  private vm: UserViewModel = new UserViewModel()
  private userRepository: UserRepository = new UserRepository()

  private routeUserId: string = ''
  private isWaitingLoginBack: boolean = false

  @StorageLink('login_version') @Watch('onLoginStateChanged') loginVersion: number = 0
  @State pageVersion: number = 0
  @State inputRefreshVersion: number = 0
  @State userId: string = ''
  @State nickname: string = ''
  @State phone: string = ''
  @State avatarUrl: string = 'default_avatar'
  @State errorMessage: string = ''

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData(true)
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData(false)
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()

      Scroll() {
        Column() {
          this.ProfileCard()
          this.FormCard()
          this.SaveButton()
          this.LogoutButton()
          Blank().height(40)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 20 })
      }
      .layoutWeight(1)
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

      Text('个人主页')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4 })

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private ProfileCard() {
    Column() {
      if (this.hasCustomAvatar(this.avatarUrl)) {
        Image(this.avatarUrl)
          .width(76)
          .height(76)
          .objectFit(ImageFit.Cover)
          .borderRadius(38)
          .margin({ top: 18 })
          .onClick(() => {
            this.selectAvatarFromAlbum()
          })
      } else {
        Text(this.getAvatarText(this.avatarUrl))
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width(76)
          .height(76)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getAvatarColor(this.avatarUrl))
          .borderRadius(38)
          .margin({ top: 18 })
          .onClick(() => {
            this.selectAvatarFromAlbum()
          })
      }

      Text('点击头像或下方按钮，从系统相册选择图片')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ top: 10 })

      Button('从相册选择头像')
        .fontSize(14)
        .fontColor('#F04444')
        .backgroundColor('#FFF2F2')
        .borderRadius(18)
        .height(36)
        .margin({ top: 14, bottom: 4 })
        .onClick(() => {
          this.selectAvatarFromAlbum()
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 18 })
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  private FormCard() {
    Column() {
      this.NicknameInputRow()

      Divider()
        .color('#F2F2F2')

      this.PhoneInputRow()
    }
    .width('100%')
    .padding({ left: 14, right: 14 })
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  private NicknameInputRow() {
    Row() {
      Text('用户昵称')
        .fontSize(15)
        .fontColor('#222222')
        .width(86)

      ForEach(['nickname_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入用户昵称', text: this.nickname })
          .height(48)
          .fontSize(15)
          .fontColor('#222222')
          .placeholderColor('#BBBBBB')
          .backgroundColor('#FFFFFF')
          .layoutWeight(1)
          .onChange((inputValue: string) => {
            this.nickname = inputValue
            this.refreshPage()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .height(58)
  }

  @Builder
  private PhoneInputRow() {
    Row() {
      Text('手机号')
        .fontSize(15)
        .fontColor('#222222')
        .width(86)

      ForEach(['phone_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入手机号', text: this.phone })
          .height(48)
          .fontSize(15)
          .fontColor('#222222')
          .placeholderColor('#BBBBBB')
          .backgroundColor('#FFFFFF')
          .layoutWeight(1)
          .onChange((inputValue: string) => {
            this.phone = inputValue
            this.refreshPage()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .height(58)
  }

  @Builder
  private SaveButton() {
    Button('保存资料')
      .height(44)
      .width('100%')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor(this.canSave() ? '#F04444' : '#FFD6C2')
      .borderRadius(22)
      .margin({ top: 22 })
      .enabled(this.canSave())
      .onClick(() => {
        this.saveProfile()
      })
  }

  @Builder
  private LogoutButton() {
    Button('退出登录')
      .height(44)
      .width('100%')
      .fontSize(16)
      .fontColor('#F04444')
      .backgroundColor('#FFFFFF')
      .borderRadius(22)
      .margin({ top: 12 })
      .onClick(() => {
        this.showLogoutDialog()
      })
  }

  private async loadPageData(allowLoginRedirect: boolean): Promise<void> {
    const params: UserProfileRouteParams = this.getRouteParams()
    const routeUserId: string = params.userId ?? ''
    const effectiveUserId: string = this.getEffectiveUserId(routeUserId)

    if (effectiveUserId.length === 0 || !this.userRepository.isLogin()) {
      if (allowLoginRedirect && !this.isWaitingLoginBack) {
        this.isWaitingLoginBack = true
        router.pushUrl({ url: 'pages/user/LoginPage' })
      }
      return
    }

    await this.vm.loadMinePage(effectiveUserId)
    if (this.vm.user === undefined) {
      this.errorMessage = this.vm.errorMessage
      promptAction.showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '用户信息不存在' })
      return
    }

    this.userId = this.vm.user.userId
    this.nickname = this.vm.user.nickname ?? ''
    this.phone = this.vm.user.phone ?? ''
    this.avatarUrl = this.normalizeAvatarUrl(this.vm.user.avatarUrl ?? '')
    this.errorMessage = ''
    this.isWaitingLoginBack = false
    this.refreshInputText()
    this.refreshPage()
  }

  private getRouteParams(): UserProfileRouteParams {
    const rawParams: UserProfileRouteParams | undefined = router.getParams() as UserProfileRouteParams | undefined

    if (rawParams !== undefined && rawParams !== null) {
      if (rawParams.userId !== undefined) {
        this.routeUserId = rawParams.userId
      }
    }

    const params: UserProfileRouteParams = {
      userId: this.routeUserId
    }
    return params
  }

  private getEffectiveUserId(routeUserId: string = ''): string {
    const normalizedRouteUserId: string = routeUserId.trim()
    if (normalizedRouteUserId.length > 0) {
      return normalizedRouteUserId
    }

    const normalizedStateUserId: string = this.userId.trim()
    if (normalizedStateUserId.length > 0) {
      return normalizedStateUserId
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  private async saveProfile(): Promise<void> {
    const success: boolean = await this.vm.updateUserProfile(this.userId, this.nickname, this.phone, this.avatarUrl)
    if (!success) {
      promptAction.showToast({ message: this.vm.errorMessage })
      this.refreshPage()
      return
    }

    if (this.vm.user !== undefined) {
      this.userId = this.vm.user.userId
      this.nickname = this.vm.user.nickname ?? ''
      this.phone = this.vm.user.phone ?? ''
      this.avatarUrl = this.normalizeAvatarUrl(this.vm.user.avatarUrl ?? '')
    }

    promptAction.showToast({ message: '保存成功' })
    this.refreshInputText()
    this.refreshPage()
  }

  private refreshInputText(): void {
    this.inputRefreshVersion++
  }

  private showLogoutDialog(): void {
    AlertDialog.show({
      title: '退出登录',
      message: '确认退出当前账号吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '退出',
        action: () => {
          this.vm.logout()
          promptAction.showToast({ message: '已退出登录' })
          router.back()
        }
      }
    })
  }

  private canSave(): boolean {
    const regExp: RegExp = /^1[3-9]\d{9}$/
    return this.nickname.trim().length > 0 && this.nickname.trim().length <= 12 && regExp.test(this.phone.trim())
  }

  private onLoginStateChanged(): void {
    this.loadPageData(false)
  }

  private normalizeAvatarUrl(avatarUrl: string): string {
    const normalizedAvatarUrl: string = avatarUrl.trim()
    if (normalizedAvatarUrl === 'mock_avatar_ticket' || normalizedAvatarUrl === 'mock_avatar_star' ||
      normalizedAvatarUrl === 'mock_avatar_me' || normalizedAvatarUrl === 'default_avatar') {
      return normalizedAvatarUrl
    }

    if (normalizedAvatarUrl.indexOf('female') >= 0) {
      return 'mock_avatar_me'
    }

    if (normalizedAvatarUrl.indexOf('male') >= 0) {
      return 'mock_avatar_ticket'
    }

    return normalizedAvatarUrl.length > 0 ? normalizedAvatarUrl : 'default_avatar'
  }

  private hasCustomAvatar(avatarUrl: string): boolean {
    return avatarUrl !== 'default_avatar' && avatarUrl !== 'mock_avatar_ticket' &&
      avatarUrl !== 'mock_avatar_star' && avatarUrl !== 'mock_avatar_me'
  }

  private async selectAvatarFromAlbum(): Promise<void> {
    try {
      const pickerOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      pickerOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      pickerOptions.maxSelectNumber = 1
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker()
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(pickerOptions)
      if (result.photoUris.length > 0) {
        this.avatarUrl = result.photoUris[0]
        this.refreshPage()
      }
    } catch (error) {
      promptAction.showToast({ message: '未选择头像图片' })
    }
  }

  private getAvatarText(avatarUrl: string): string {
    if (avatarUrl === 'mock_avatar_ticket') {
      return '票'
    }
    if (avatarUrl === 'mock_avatar_star') {
      return '星'
    }
    if (avatarUrl === 'mock_avatar_me') {
      return '我'
    }
    return '麦'
  }

  private getAvatarColor(avatarUrl: string): string {
    if (avatarUrl === 'mock_avatar_ticket') {
      return '#FF8A00'
    }
    if (avatarUrl === 'mock_avatar_star') {
      return '#8B5CF6'
    }
    if (avatarUrl === 'mock_avatar_me') {
      return '#2F80ED'
    }
    return '#F04444'
  }

  private refreshPage(): void {
    this.pageVersion++
  }

  @Builder
  private RefreshMarker() {
    Text(`${this.pageVersion}-${this.loginVersion}`)
      .width(0)
      .height(0)
      .opacity(0)
  }
}
