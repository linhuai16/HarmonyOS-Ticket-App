import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { UserViewModel } from '../../viewmodel/UserViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

const COLOR_ICON = '#666666'

@Entry
@Component
export struct MinePage {
  private vm: UserViewModel = new UserViewModel()

  @StorageLink('login_status') @Watch('onLoginStateChanged') storageLoginStatus: boolean = false
  @StorageLink('login_user_id') @Watch('onLoginStateChanged') storageUserId: string = ''
  @StorageLink('login_nickname') @Watch('onLoginStateChanged') storageNickname: string = ''
  @StorageLink('login_avatar_url') @Watch('onLoginStateChanged') storageAvatarUrl: string = ''
  @StorageLink('login_version') @Watch('onLoginStateChanged') loginVersion: number = 0
  @StorageLink('user_center_changed_version') @Watch('onUserCenterChanged') userCenterChangedVersion: number = 0

  @State pageVersion: number = 0
  @State loadedNickname: string = ''
  @State loadedAvatarUrl: string = ''

  aboutToAppear(): void {
    WindowImmersiveUtil.applyMine(this)
    this.loadCurrentUserAndRefresh()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyMine(this)
    this.loadCurrentUserAndRefresh()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.UserHeader()
          this.QuickEntryArea()
          this.ServiceArea()
          this.SettingEntry()
          Blank().height(20)
        }
        .width('100%')
        // Scroll 内容高度小于可视区域时，ArkUI 会把内容放在可视区域中间，
        // 导致 MinePage 顶部出现一大块灰色空白。
        // 设置最小高度为 100%，并让子项从顶部排列，既能消除顶部空白，
        // 又不会影响小屏幕内容超出时继续滚动。
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .opacity(this.pageVersion >= 0 && this.loginVersion >= 0 ? 1 : 1)
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio > 0) {
        this.loadCurrentUserAndRefresh()
      }
    })
  }

  @Builder
  private UserHeader() {
    Row() {
      if (this.hasCustomAvatar()) {
        Image(this.getAvatarUrl())
          .width(54)
          .height(54)
          .objectFit(ImageFit.Cover)
          .borderRadius(27)
      } else {
        Text(this.getAvatarText())
          .fontSize(22)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .width(54)
          .height(54)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getAvatarColor())
          .borderRadius(27)
      }

      Column() {
        Text(this.getNickname())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.isLoggedIn() ? '个人主页 >' : '点击登录后查看个人信息')
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 6 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })

      if (!this.isLoggedIn()) {
        Text('去登录')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#F04444')
          .borderRadius(16)
      }
    }
    .width('100%')
    .height(120)
    .padding({ left: 18, right: 18, top: 16, bottom: 24 })
    .backgroundColor('#FFEDEF')
    .onClick(() => {
      if (!this.isLoggedIn()) {
        router.pushUrl({ url: 'pages/user/LoginPage' })
        return
      }

      router.pushUrl({
        url: 'pages/user/UserProfilePage',
        params: { userId: this.getUserId() }
      })
    })
  }

  @Builder
  private QuickEntryArea() {
    Row() {
      this.QuickEntryItem('我的订单', 'pages/order/OrderListPage')
      this.QuickEntryItem('我的票夹', 'pages/ticket/TicketFolderPage')
      this.QuickEntryItem('我的想看', 'pages/want/WantPage')
    }
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ left: 12, right: 12, top: -14 })
  }

  @Builder
  private QuickEntryItem(title: string, url: string) {
    Column() {
      Image(this.getQuickIcon(title))
        .width(26)
        .height(26)
        .margin({ bottom: 6 })
      Text(title)
        .fontSize(13)
        .fontColor('#222222')
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.checkLoginAndJump(url)
    })
  }

  @Builder
  private ServiceArea() {
    Column() {
      this.MenuItem('观演人', 'pages/user/AudiencePage')
      this.MenuItem('收货地址', 'pages/user/AddressPage')
      this.ContactItem()
      this.AboutItem()
    }
    .width('100%')
    .margin({ left: 12, right: 12, top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  private SettingEntry() {
    Column() {
      Row() {
        Image($r('app.media.mine_shezhi'))
          .width(20)
          .height(20)
          .margin({ right: 10 })
        Text('设置')
          .fontSize(15)
          .fontColor('#222222')
        Blank()
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
      }
      .height(50)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/mine/SettingPage',
          params: { userId: this.getUserId() }
        })
      })
    }
    .width('100%')
    .margin({ left: 12, right: 12, top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  private MenuItem(title: string, url: string) {
    Row() {
      Image(this.getMenuIcon(title))
        .width(20)
        .height(20)
        .margin({ right: 10 })
      Text(title)
        .fontSize(15)
        .fontColor('#222222')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .height(50)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.checkLoginAndJump(url)
    })
  }

  @Builder
  private ContactItem() {
    Row() {
      Image($r('app.media.mine_kefu'))
        .width(20)
        .height(20)
        .margin({ right: 10 })
      Text('联系客服')
        .fontSize(15)
        .fontColor('#222222')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .height(50)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      promptAction.showToast({ message: '客服电话：400-000-0000' })
    })
  }

  @Builder
  private AboutItem() {
    Row() {
      Image($r('app.media.mine_guanyuwomen'))
        .width(20)
        .height(20)
        .margin({ right: 10 })
      Text('关于我们')
        .fontSize(15)
        .fontColor('#222222')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .height(50)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      router.pushUrl({ url: 'pages/mine/TextPage', params: { type: 'about' } })
    })
  }

  private async loadCurrentUserAndRefresh(): Promise<void> {
    await this.vm.loadCurrentUser()
    this.loadedNickname = this.vm.user?.nickname ?? ''
    this.loadedAvatarUrl = this.vm.user?.avatarUrl ?? ''
    this.refreshPage()
  }

  private onLoginStateChanged(): void {
    this.loadCurrentUserAndRefresh()
  }

  private onUserCenterChanged(): void {
    this.loadCurrentUserAndRefresh()
  }

  private checkLoginAndJump(url: string): void {
    if (!this.isLoggedIn()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }
    router.pushUrl({ url: url, params: { userId: this.getUserId() } })
  }

  private isLoggedIn(): boolean {
    // 登录状态以 AppStorage 为准，避免退出登录后 MinePage 内旧 VM 状态继续让页面展示旧用户。
    return this.storageLoginStatus && this.storageUserId.length > 0
  }

  private getNickname(): string {
    if (!this.isLoggedIn()) {
      return '未登录'
    }

    if (this.storageNickname.length > 0) {
      return this.storageNickname
    }

    if (this.loadedNickname.length > 0) {
      return this.loadedNickname
    }

    return '麦麦用户'
  }

  private getAvatarText(): string {
    if (!this.isLoggedIn()) {
      return '未'
    }

    const avatarUrl: string = this.getAvatarUrl()
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

  private getAvatarUrl(): string {
    if (this.storageAvatarUrl.length > 0) {
      return this.normalizeAvatarUrl(this.storageAvatarUrl)
    }

    if (this.loadedAvatarUrl.length > 0) {
      return this.normalizeAvatarUrl(this.loadedAvatarUrl)
    }

    return 'default_avatar'
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

  private hasCustomAvatar(): boolean {
    const avatarUrl: string = this.getAvatarUrl()
    return avatarUrl !== 'default_avatar' && avatarUrl !== 'mock_avatar_ticket' &&
      avatarUrl !== 'mock_avatar_star' && avatarUrl !== 'mock_avatar_me'
  }

  private getAvatarColor(): string {
    const avatarUrl: string = this.getAvatarUrl()
    if (avatarUrl === 'mock_avatar_ticket') {
      return '#FF8A00'
    }
    if (avatarUrl === 'mock_avatar_star') {
      return '#8B5CF6'
    }
    if (avatarUrl === 'mock_avatar_me') {
      return '#2F80ED'
    }
    return this.isLoggedIn() ? '#F04444' : '#999999'
  }

  private getUserId(): string {
    if (!this.isLoggedIn()) {
      return ''
    }

    return this.storageUserId
  }

  private getQuickIcon(title: string) {
    if (title === '我的订单') {
      return $r('app.media.mine_dingdan')
    }
    if (title === '我的票夹') {
      return $r('app.media.mine_piaojia')
    }
    return $r('app.media.page_xiangkan')
  }

  private getMenuIcon(title: string) {
    if (title === '观演人') {
      return $r('app.media.mine_guanyanren')
    }
    return $r('app.media.mine_shouhuodizhi')
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
