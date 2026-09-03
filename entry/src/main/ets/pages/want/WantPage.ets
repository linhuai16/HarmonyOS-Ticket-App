import { AppNavigator, WantNavParams } from '../../navigation/AppNavigation'

import {
  WantPerformanceItemVO
} from '../../model/vo/want/WantListPageVO'

import {
  WantViewModel,
  WantDetailJumpParams
} from '../../viewmodel/WantViewModel'

import { ProjectStatus } from '../../model/enums/ProjectStatus'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
import { UserRepository } from '../../repository/UserRepository'

interface WantRouteParams {
  userId?: string
}

@Entry
@Component
export struct WantPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: WantNavParams = {}

  private vm: WantViewModel = new WantViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State userId: string = ''
  @State items: WantPerformanceItemVO[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0
  @State isRefreshingPage: boolean = false
  @State breakPoint: string = 'sm'
  @State tabletListWidth: number = 0
  @StorageLink('want_changed_version') @Watch('onWantDataChanged') wantChangedVersion: number = 0
  @StorageLink('performance_changed_version') @Watch('onWantDataChanged') performanceChangedVersion: number = 0
  @StorageLink('login_version') @Watch('onLoginChanged') loginVersion: number = 0
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    if (this.pendingExternalRefresh) {
      this.pendingExternalRefresh = false
      setTimeout(() => {
        if (this.isPageVisible) {
          this.reloadCurrentWantList()
        }
      }, 700)
    }
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  private onWantDataChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadCurrentWantList()
  }

  private onLoginChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadForLoginChange()
  }

  private async reloadForLoginChange(): Promise<void> {
    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    if (currentUserId.length === 0 || !this.userRepository.isLogin()) {
      this.userId = ''
      this.items = []
      this.errorMessage = ''
      this.pageVersion++
      return
    }
    await this.vm.loadPage(currentUserId)
    this.syncFromVm()
  }

  private async loadPageData(): Promise<void> {
    const params: WantNavParams | undefined = this.navParams
    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    const userId: string = currentUserId.length > 0 ? currentUserId : (params?.userId ?? '')

    this.isLoading = true
    await this.vm.loadPage(userId)
    this.syncFromVm()
  }

  private async reloadCurrentWantList(): Promise<void> {
    if (this.userId.length === 0) {
      return
    }

    await this.vm.loadPage(this.userId)
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.items = [...this.vm.items]
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.pageVersion++
  }

  build() {
    NavDestination() {
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

            Column() {
              if (this.isLoading && this.items.length === 0) {
                this.LoadingArea('正在加载想看列表...')
              } else if (this.items.length === 0) {
                this.EmptyArea()
              } else {
                this.WantListArea()
              }
            }
            .width('100%')
            .constraintSize({ maxWidth: ResponsiveLayout.COLLECTION_MAX_WIDTH })
            .layoutWeight(1)
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
    .hideTitleBar(true)
    .onShown(() => {
      this.onPageShow()
    })
    .onHidden(() => { this.onPageHide() })
  }

  @Builder
  private WantListArea() {
    if (this.isTabletLayout()) {
      Grid() {
        ForEach(this.items, (item: WantPerformanceItemVO) => {
          GridItem() {
            this.WantCard(item)
          }
        }, (item: WantPerformanceItemVO) => item.wantId + '_' + item.projectId)
      }
      .columnsTemplate(ResponsiveLayout.getGridTemplate(this.getTabletGridColumnCount()))
      .columnsGap(18)
      .rowsGap(18)
      .width('100%')
      .height('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const nextWidth: number = Number(newValue.width ?? 0)
        if (Math.abs(nextWidth - this.tabletListWidth) > 0.5) {
          this.tabletListWidth = nextWidth
        }
      })
    } else {
      List() {
        ForEach(this.items, (item: WantPerformanceItemVO) => {
          ListItem() {
            this.WantCard(item)
          }
        }, (item: WantPerformanceItemVO) => item.wantId + '_' + item.projectId)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12 })
      .clip(true)
    }
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
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
          this.navStack.pop()
        })

      Text('我的想看')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 8 })

      Blank()
      Button() {
        Image($r('app.media.refrech'))
          .width(18)
          .height(18)
          .fillColor(this.isRefreshingPage ? '#BBBBBB' : '#666666')
      }
        .width(40)
        .height(40)
        .backgroundColor('#00000000')
        .enabled(!this.isRefreshingPage)
        .onClick(() => {
          if (!this.isRefreshingPage) this.manualRefreshWant()
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '暂无想看的演出')
        .fontSize(15)
        .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })

      if (this.errorMessage.length > 0) {
        Text('点击重试')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .margin({ top: 14 })
          .backgroundColor('#E33B3B')
          .borderRadius(18)
          .onClick(() => {
            this.reloadCurrentWantList()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private LoadingArea(message: string) {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color('#E33B3B')

      Text(message)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private WantCard(item: WantPerformanceItemVO) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(MediaResourceUtil.getMedia(item.posterUrl))
            .width(this.isTabletLayout() ? 112 : 90)
            .height(this.isTabletLayout() ? 150 : 120)
            .objectFit(ImageFit.Cover)
            .backgroundColor('#F2F2F2')
            .borderRadius(8)

          Text(item.categoryName)
            .fontSize(this.isTabletLayout() ? 11 : 10)
            .fontColor('#FFFFFF')
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .backgroundColor('#E33B3B')
            .borderRadius({ topLeft: 8, bottomRight: 8 })
        }

        Column() {
          Text(item.title)
            .fontSize(this.isTabletLayout() ? 18 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textAlign(TextAlign.Start)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.startTime)
            .fontSize(this.isTabletLayout() ? 14 : 13)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
            .margin({ top: 8 })

          Text(item.venueName)
            .fontSize(this.isTabletLayout() ? 14 : 13)
            .fontColor('#666666')
            .maxLines(1)
            .textAlign(TextAlign.Start)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })

          Text(this.getPriceText(item))
            .fontSize(this.isTabletLayout() ? 17 : 15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E33B3B')
            .textAlign(TextAlign.Start)
            .margin({ top: 8 })

          Text(this.getStatusText(item))
            .fontSize(12)
            .fontColor('#999999')
            .textAlign(TextAlign.Start)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .onClick(() => {
        this.jumpDetail(item)
      })

      Row() {
        Text('取消想看')
          .fontSize(13)
          .fontColor('#999999')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#F1F1F1')
          .borderRadius(14)
          .onClick(() => {
            this.cancelWant(item.projectId)
          })

        Blank()

        Button(this.getActionButtonText(item))
          .height(this.isTabletLayout() ? 40 : 34)
          .fontSize(this.isTabletLayout() ? 14 : 13)
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16 })
          .backgroundColor(this.canBuyOrReserve(item) ? '#E33B3B' : '#CCCCCC')
          .enabled(this.canBuyOrReserve(item))
          .onClick(() => {
            this.jumpDetail(item)
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 0 : 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private getTabletGridColumnCount(): number {
    return ResponsiveLayout.getTabletGridColumnCount(this.tabletListWidth)
  }

  private async manualRefreshWant(): Promise<void> {
    if (this.isRefreshingPage) return
    this.isRefreshingPage = true
    try {
      await this.reloadCurrentWantList()
    } finally {
      this.isRefreshingPage = false
    }
    this.getUIContext().getPromptAction().showToast({ message: this.errorMessage.length > 0 ? this.errorMessage : '想看列表已刷新' })
  }

  private jumpDetail(item: WantPerformanceItemVO): void {
    const params: WantDetailJumpParams = this.vm.buildDetailJumpParams(item)
    AppNavigator.openPerformanceDetail(this.navStack, {
      projectId: params.projectId,
      sessionId: params.sessionId,
      posterUrl: item.posterUrl,
      title: item.title,
      categoryName: item.categoryName,
      startTime: item.startTime,
      venueName: item.venueName,
      minPrice: item.minPrice
    })
  }

  private async cancelWant(projectId: string): Promise<void> {
    const success: boolean = await this.vm.cancelWant(projectId)
    this.syncFromVm()

    this.getUIContext().getPromptAction().showToast({
      message: success ? '取消想看成功' : this.errorMessage
    })
  }

  private getPriceText(item: WantPerformanceItemVO): string {
    if (item.minPrice === undefined) {
      return ''
    }

    return '￥' + item.minPrice + ' 起'
  }

  private getActionButtonText(item: WantPerformanceItemVO): string {
    if (item.sessionStatus === SessionStatus.PRESALE) {
      return '预订'
    }

    if (item.sessionStatus === SessionStatus.ON_SALE) {
      return '购票'
    }

    if (item.sessionStatus === SessionStatus.SOLD_OUT) {
      return '已售罄'
    }

    return '不可购票'
  }

  private getStatusText(item: WantPerformanceItemVO): string {
    if (item.projectStatus === ProjectStatus.ENDED) {
      return '项目已结束'
    }

    if (item.sessionStatus === SessionStatus.PRESALE) {
      return '预售中'
    }

    if (item.sessionStatus === SessionStatus.ON_SALE) {
      return '售卖中'
    }

    if (item.sessionStatus === SessionStatus.SOLD_OUT) {
      return '已售罄'
    }

    if (item.sessionStatus === SessionStatus.ENDED) {
      return '已结束'
    }

    return ''
  }

  private canBuyOrReserve(item: WantPerformanceItemVO): boolean {
    return item.sessionStatus === SessionStatus.PRESALE ||
      item.sessionStatus === SessionStatus.ON_SALE
  }
}
