import router from '@ohos.router'
import { AppNavigator } from '../../navigation/AppNavigation'
import { UserViewModel } from '../../viewmodel/UserViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'

const COLOR_ICON = '#666666'
@Entry
@Component
export struct MinePage {
  @Consume('appNavStack') navStack: NavPathStack
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
  @State breakPoint: string = 'sm'

  aboutToAppear(): void {
    WindowImmersiveUtil.applyMine(this)
    this.loadCurrentUserAndRefresh()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyMine(this)
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
        if (this.isTabletLayout()) {
          this.TabletMineBody()
        } else {
          this.PhoneMineBody()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .onBreakpointChange((breakpoint: string) => {
      this.breakPoint = breakpoint
    })
    .opacity(this.pageVersion >= 0 && this.loginVersion >= 0 ? 1 : 1)
  }

  @Builder
  private PhoneMineBody() {
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
        .constraintSize({ minHeight: '100%' })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletMineBody() {
    Scroll() {
      Column() {
        this.TabletUserHeader()

        Row({ space: 18 }) {
          Column({ space: 14 }) {
            this.TabletQuickEntryArea()
            this.TabletSettingEntry()
          }
          .width(ResponsiveLayout.isWideBreakpoint(this.breakPoint) ? 430 : 360)

          this.TabletServiceArea()
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .margin({ top: 18 })

        Blank().height(24)
      }
      .width('100%')
      .constraintSize({ maxWidth: ResponsiveLayout.DETAIL_MAX_WIDTH, minHeight: '100%' })
      .padding({ left: 24, right: 24, top: 20 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletUserHeader() {
    Row() {
      if (this.hasCustomAvatar()) {
        Image(this.getAvatarUrl())
          .width(80)
          .height(80)
          .objectFit(ImageFit.Cover)
          .borderRadius(40)
      } else {
        Text(this.getAvatarText())
          .fontSize(30)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .width(80)
          .height(80)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getAvatarColor())
          .borderRadius(40)
      }

      Column() {
        Text(this.getNickname())
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.isLoggedIn() ? '个人主页 >' : '点击登录后查看个人信息')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })

      if (!this.isLoggedIn()) {
        Text('去登录')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .backgroundColor('#F04444')
          .borderRadius(18)
      }
    }
    .width('100%')
    .height(156)
    .padding({ left: 28, right: 28 })
    .backgroundColor('#FFEDEF')
    .borderRadius(18)
    .onClick(() => {
      if (!this.isLoggedIn()) {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
        return
      }
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/user/UserProfilePage',
        params: { userId: this.getUserId() }
      })
    })
  }

  @Builder
  private TabletQuickEntryArea() {
    Column() {
      Text('我的票务')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Row() {
        this.QuickEntryItem('我的订单', 'pages/order/OrderListPage')
        this.QuickEntryItem('我的票夹', 'pages/ticket/TicketFolderPage')
        this.QuickEntryItem('我的想看', 'pages/want/WantPage')
      }
      .width('100%')
      .height(92)
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private TabletServiceArea() {
    Column() {
      Text('常用服务')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 8 })

      this.MenuItem('观演人', 'pages/user/AudiencePage')
      this.MenuItem('收货地址', 'pages/user/AddressPage')
      this.ContactItem()
      this.AboutItem()
    }
    .layoutWeight(1)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private TabletSettingEntry() {
    Column() {
      Text('应用')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 8 })

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
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/mine/SettingPage',
          params: { userId: this.getUserId() }
        })
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
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
        this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
        return
      }

      this.getUIContext().getRouter().pushUrl({
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
        .width(this.isTabletLayout() ? 32 : 26)
        .height(this.isTabletLayout() ? 32 : 26)
        .margin({ bottom: 6 })
      Text(title)
        .fontSize(this.isTabletLayout() ? 15 : 13)
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
        this.getUIContext().getRouter().pushUrl({
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
        .width(this.isTabletLayout() ? 24 : 20)
        .height(this.isTabletLayout() ? 24 : 20)
        .margin({ right: this.isTabletLayout() ? 12 : 10 })
      Text(title)
        .fontSize(this.isTabletLayout() ? 17 : 15)
        .fontColor('#222222')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .height(this.isTabletLayout() ? 60 : 50)
    .width('100%')
    .padding({ left: this.isTabletLayout() ? 18 : 16, right: this.isTabletLayout() ? 18 : 16 })
    .onClick(() => {
      this.checkLoginAndJump(url)
    })
  }

  @Builder
  private ContactItem() {
    Row() {
      Image($r('app.media.mine_kefu'))
        .width(this.isTabletLayout() ? 24 : 20)
        .height(this.isTabletLayout() ? 24 : 20)
        .margin({ right: this.isTabletLayout() ? 12 : 10 })
      Text('联系客服')
        .fontSize(this.isTabletLayout() ? 17 : 15)
        .fontColor('#222222')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .height(this.isTabletLayout() ? 60 : 50)
    .width('100%')
    .padding({ left: this.isTabletLayout() ? 18 : 16, right: this.isTabletLayout() ? 18 : 16 })
    .onClick(() => {
      this.getUIContext().getPromptAction().showToast({ message: '客服电话：400-000-0000' })
    })
  }

  @Builder
  private AboutItem() {
    Row() {
      Image($r('app.media.mine_guanyuwomen'))
        .width(this.isTabletLayout() ? 24 : 20)
        .height(this.isTabletLayout() ? 24 : 20)
        .margin({ right: this.isTabletLayout() ? 12 : 10 })
      Text('关于我们')
        .fontSize(this.isTabletLayout() ? 17 : 15)
        .fontColor('#222222')
      Blank()
      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .height(this.isTabletLayout() ? 60 : 50)
    .width('100%')
    .padding({ left: this.isTabletLayout() ? 18 : 16, right: this.isTabletLayout() ? 18 : 16 })
    .onClick(() => {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/mine/TextPage', params: { type: 'about' } })
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
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    const userId: string = this.getUserId()
    if (url === 'pages/order/OrderListPage') {
      AppNavigator.openOrderList(this.navStack, { userId: userId })
      return
    }
    if (url === 'pages/ticket/TicketFolderPage') {
      AppNavigator.openTicketFolder(this.navStack, { userId: userId })
      return
    }
    if (url === 'pages/want/WantPage') {
      AppNavigator.openWant(this.navStack, { userId: userId })
      return
    }

    // 观演人、地址等外围辅助页仍由 Router 管理。
    this.getUIContext().getRouter().pushUrl({ url: url, params: { userId: userId } })
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
