import { AppNavigator, PerformanceDetailNavParams } from '../../navigation/AppNavigation'
import { webview } from '@kit.ArkWeb'
import { common } from '@kit.AbilityKit'

import {
  PerformanceDetailVO,
  PerformanceSessionItemVO,
  ServiceTagVO,
  NoticeItemVO,
  VenueDisplayVO
} from '../../model/vo/performance/PerformanceDetailVO'

import { PerformanceDetailViewModel } from '../../viewmodel/PerformanceDetailViewModel'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { CityRepository } from '../../repository/CityRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
import { RichTextHtmlUtil } from '../../common/RichTextHtmlUtil'
import { VenueNavigationUtil } from '../../utils/VenueNavigationUtil'
import {
  PerformanceBottomActionBar,
  PerformanceNoticeGrid,
  PerformanceServiceTagDialog,
  PerformanceSessionSelector,
  PerformanceVenueCard
} from '../../components/performance/PerformanceDetailSections'

@Entry
@Component
export struct PerformanceDetailPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: PerformanceDetailNavParams = {}

  private vm: PerformanceDetailViewModel = new PerformanceDetailViewModel()
  private userRepository: UserRepository = new UserRepository()
  private cityRepository: CityRepository = new CityRepository()
  private detailWebController: webview.WebviewController = new webview.WebviewController()
  private detailScroller: Scroller = new Scroller()
  private serviceTagScroller: Scroller = new Scroller()

  @State detailVO: PerformanceDetailVO | undefined = undefined
  @State pageVersion: number = 0
  @State selectedSessionId: string = ''
  @State selectedStartTime: string = ''
  @State isWanted: boolean = false
  @State canBuy: boolean = false
  @State buyButtonText: string = '不可购票'
  @State selectedMinPrice: number | undefined = undefined
  @State selectedMaxPrice: number | undefined = undefined
  @State selectedVenueName: string = ''
  @State selectedVenueAddress: string = ''
  @State selectedVenueLongitude: number = 0
  @State selectedVenueLatitude: number = 0
  @State hasSelectedVenueCoordinate: boolean = false
  @State selectedDetailContent: string = ''
  @State errorMessage: string = ''
  @State isLoading: boolean = false
  @State isRefreshingPage: boolean = false
  @State serviceTagViewportWidth: number = 0
  @State serviceTagContentWidth: number = 0
  @State showServiceTagMoreArrow: boolean = false
  @State serviceTagDialogVisible: boolean = false
  @State serviceTagDialogTitle: string = ''
  @State serviceTagDialogDescription: string = ''
  @State serviceTagDialogItems: string[] = []
  @State routeProjectId: string = ''
  @State routePosterUrl: string = ''
  @State previewTitle: string = ''
  @State previewCategoryName: string = ''
  @State previewStartTime: string = ''
  @State previewCityName: string = ''
  @State previewVenueName: string = ''
  @State previewMinPrice: number | undefined = undefined
  @State previewMaxPrice: number | undefined = undefined
  @State titleBarProgress: number = 0
  @State statusBarDark: boolean = false
  @State secondaryAnchorVisible: boolean = false
  @State activeSecondaryAnchor: number = 0
  @State breakPoint: string = 'sm'
  @State layoutMeasureVersion: number = 0
  private introAnchorOffset: number = -1
  private noticeAnchorOffset: number = -1
  private topBarHeight: number = 82
  private secondaryAnchorHeight: number = 48
  private detailViewportWidth: number = 0
  private detailViewportHeight: number = 0
  @StorageLink('performance_changed_version') @Watch('onPerformanceDataChanged') performanceChangedVersion: number = 0
  @StorageLink('want_changed_version') @Watch('onPerformanceDataChanged') wantChangedVersion: number = 0
  @StorageLink('login_version') @Watch('onPerformanceDataChanged') loginVersion: number = 0
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false
  private hasShownOnce: boolean = false

  aboutToAppear(): void {
    AppStorage.setOrCreate('performance_video_pause_version', 0)
    AppStorage.setOrCreate('performance_video_resume_version', 0)
    AppStorage.setOrCreate('performance_video_resume_url', '')
    AppStorage.setOrCreate('performance_video_resume_position_ms', 0)
    WindowImmersiveUtil.applyDetail(this, false)
    this.isPageVisible = true
    const params: PerformanceDetailNavParams = this.navParams
    this.routeProjectId = (params.projectId ?? '').trim()
    this.routePosterUrl = (params.posterUrl ?? '').trim()
    this.previewTitle = (params.title ?? '').trim()
    this.previewCategoryName = (params.categoryName ?? '').trim()
    this.previewStartTime = (params.startTime ?? '').trim()
    this.previewCityName = (params.cityName ?? '').trim()
    this.previewVenueName = (params.venueName ?? '').trim()
    this.previewMinPrice = params.minPrice
    this.previewMaxPrice = params.maxPrice
    this.selectedStartTime = this.previewStartTime
    this.selectedMinPrice = this.previewMinPrice
    this.selectedMaxPrice = this.previewMaxPrice
    this.initPage(params)
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyDetail(this, this.statusBarDark)
    this.isPageVisible = true
  }

  onPageHide(): void {
    this.isPageVisible = false
    const pauseVersion: number = AppStorage.get<number>('performance_video_pause_version') ?? 0
    AppStorage.setOrCreate('performance_video_pause_version', pauseVersion + 1)
    WindowImmersiveUtil.exitDetail(this)
  }

  private onPerformanceDataChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadCurrentDetail()
  }

  build() {
    NavDestination() {
      this.DetailPageBody()
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .onBackPressed(() => {
      this.navStack.pop()
      return true
    })
    .onShown(() => {
      this.onPageShow()
      if (this.hasShownOnce && this.pendingExternalRefresh) {
        this.pendingExternalRefresh = false
        this.reloadCurrentDetail()
      }
      this.hasShownOnce = true
    })
    .onHidden(() => { this.onPageHide() })
  }

  @Builder
  private DetailPageBody() {
    GridRow({
        columns: { sm: 4, md: 8, lg: 12, xl: 12 },
      breakpoints: {
          value: ['600vp', '840vp', '1440vp'],
        reference: BreakpointsReference.WindowSize
      }
    }) {
        GridCol({ span: { sm: 4, md: 8, lg: 12, xl: 12 } }) {
        if (this.isTabletLayout()) {
          this.TabletDetailPageBody()
        } else {
          this.PhoneDetailPageBody()
        }
      }
    }
    .width('100%')
    .height('100%')
    .onBreakpointChange((breakpoint: string) => {
      this.handleBreakpointChange(breakpoint)
    })
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.handleViewportAreaChange(Number(newValue.width ?? 0), Number(newValue.height ?? 0))
    })
  }

  @Builder
  private PhoneDetailPageBody() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Scroll(this.detailScroller) {
          Column() {
            this.RefreshMarker()
            this.HeroArea()

            if (this.routeProjectId.length > 0 || this.detailVO !== undefined) {
              Column() {
                if (this.detailVO === undefined) {
                  this.DetailLoadingArea()
                } else {
                  this.SessionArea()
                  this.VenueArea()
                  this.ServiceTagArea()
                  this.DetailContentArea()
                  this.NoticeArea()
                }
              }
              .width('100%')
              .padding({ left: 12, right: 12, bottom: 12 })
              .alignItems(HorizontalAlign.Start)
            } else {
              this.EmptyArea()
            }
          }
          .width('100%')
          .backgroundColor('#F5F5F5')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .onDidScroll(() => {
          this.handleDetailScroll()
        })

        this.BottomActionBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      this.CollapsingTopBar()
      if (this.secondaryAnchorVisible) {
        this.SecondaryAnchorBar()
      }
      if (this.serviceTagDialogVisible) {
        this.ServiceTagDialogOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletDetailPageBody() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.detailScroller) {
        Column() {
          this.RefreshMarker()
          Column() {}
            .height(this.topBarHeight)

          if (this.routeProjectId.length > 0 || this.detailVO !== undefined) {
            this.TabletHeroOverviewArea()

            Column() {
              if (this.detailVO === undefined) {
                this.DetailLoadingArea()
              } else {
                this.SessionArea()
                this.DetailContentArea()
                this.NoticeArea()
              }
            }
            .width('100%')
            .constraintSize({ maxWidth: ResponsiveLayout.DETAIL_MAX_WIDTH })
            .padding({ left: 24, right: 24, bottom: 24 })
            .alignItems(HorizontalAlign.Start)
          } else {
            this.EmptyArea()
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .onDidScroll(() => {
        this.handleDetailScroll()
      })

      this.CollapsingTopBar()
      if (this.secondaryAnchorVisible) {
        this.SecondaryAnchorBar()
      }
      if (this.serviceTagDialogVisible) {
        this.ServiceTagDialogOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletHeroOverviewArea() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.getDisplayPosterUrl().length > 0) {
        Image(MediaResourceUtil.getMedia(this.getDisplayPosterUrl()))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(32)
          .scale({ x: 1.08, y: 1.08 })
          .opacity(0.72)
      } else {
        Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor('#4E535C')
      }

      Column() {}
        .width('100%')
        .height('100%')
        .backgroundColor('#73000000')

      Column() {
        this.TabletOverviewArea()
      }
      .width('100%')
      .constraintSize({ maxWidth: ResponsiveLayout.DETAIL_MAX_WIDTH })
      .padding({
        left: 24,
        right: 24,
        top: ResponsiveLayout.isWideBreakpoint(this.breakPoint) ? 44 : 28,
        bottom: ResponsiveLayout.isWideBreakpoint(this.breakPoint) ? 44 : 28
      })
    }
    .width('100%')
    .backgroundColor('#343941')
    .clip(true)
  }

  @Builder
  private TabletOverviewArea() {
    Row({ space: 24 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia(this.getDisplayPosterUrl()))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(16)
          .backgroundColor('#E7E7E7')

        if (this.getDisplayCategoryName().length > 0) {
          Text(this.getDisplayCategoryName())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor('#E33B3B')
            .borderRadius({ topLeft: 16, bottomRight: 9 })
        }
      }
      .width(ResponsiveLayout.isWideBreakpoint(this.breakPoint) ? 430 : 350)
      .aspectRatio(0.75)
      .borderRadius(16)
      .backgroundColor('#E7E7E7')

      Column() {
        Text(this.getDisplayTitle().length > 0 ? this.getDisplayTitle() : '演出详情')
          .fontSize(ResponsiveLayout.isWideBreakpoint(this.breakPoint) ? 28 : 24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.getDisplayStartTime().length > 0) {
          Text(this.getDisplayStartTime())
            .fontSize(15)
            .fontColor('#555555')
            .margin({ top: 20 })
            .width('100%')
        }

        if (this.getDisplayVenueLine().length > 0) {
          Text(this.getDisplayVenueLine())
            .fontSize(15)
            .fontColor('#555555')
            .margin({ top: 10 })
            .width('100%')
            .onClick(() => {
              if (this.selectedVenueName.length > 0) {
                this.openSelectedVenueNavigation()
              }
            })
        }

        if (this.getSelectedPriceRangeText().length > 0) {
          Text(this.getSelectedPriceRangeText())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E33B3B')
            .margin({ top: 18 })
        }

        if (this.detailVO !== undefined && (this.detailVO as PerformanceDetailVO).serviceTags.length > 0) {
          this.ServiceTagArea()
        }

        Row({ space: 12 }) {
          Row({ space: 6 }) {
            Image($r('app.media.page_xiangkan'))
              .width(20)
              .height(20)
              .fillColor(this.isWanted ? '#E33B3B' : '#666666')

            Text(this.isWanted ? '已想看' : '想看')
              .fontSize(15)
              .fontColor(this.isWanted ? '#E33B3B' : '#555555')
          }
            .height(46)
            .width(120)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isWanted ? '#FFECEC' : '#F3F3F3')
            .borderRadius(23)
            .onClick(() => {
              this.handleWantAction()
            })

          Button(this.buyButtonText)
            .height(46)
            .width(ResponsiveLayout.isWideBreakpoint(this.breakPoint) ? 300 : 250)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.canBuy ? '#E33B3B' : '#CCCCCC')
            .borderRadius(23)
            .enabled(this.canBuy)
            .onClick(() => {
              this.handleBuyAction()
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder
  private HeroArea() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.getDisplayPosterUrl().length > 0) {
        Image(MediaResourceUtil.getMedia(this.getDisplayPosterUrl()))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(24)
          .scale({ x: 1.12, y: 1.12 })
          .opacity(0.76)
      } else {
        Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor('#59606A')
      }

      Column() {}
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')

      Row() {
        Stack({ alignContent: Alignment.TopStart }) {
          if (this.getDisplayPosterUrl().length > 0) {
            Image(MediaResourceUtil.getMedia(this.getDisplayPosterUrl()))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(12)
          } else {
            Column() {}
              .width('100%')
              .height('100%')
              .backgroundColor('#DDDDDD')
              .borderRadius(12)
          }

          if (this.getDisplayCategoryName().length > 0) {
            Text(this.getDisplayCategoryName())
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .backgroundColor('#E33B3B')
              .borderRadius({ topLeft: 12, bottomRight: 8 })
          }
        }
        .width(126)
        .height(168)
        .borderRadius(12)
        .backgroundColor('#E7E7E7')

        Column() {
          Text(this.getDisplayTitle().length > 0 ? this.getDisplayTitle() : '演出详情')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          if (this.getDisplayStartTime().length > 0) {
            Text(this.getDisplayStartTime())
              .fontSize(13)
              .fontColor('#E8FFFFFF')
              .margin({ top: 14 })
              .width('100%')
          }

          if (this.getDisplayVenueLine().length > 0) {
            Text(this.getDisplayVenueLine())
              .fontSize(13)
              .fontColor('#E8FFFFFF')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 8 })
              .width('100%')
          }

          Blank()

          if (this.getSelectedPriceRangeText().length > 0) {
            Text(this.getSelectedPriceRangeText())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width('100%')
          }
        }
        .layoutWeight(1)
        .height(168)
        .margin({ left: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(244)
      .padding({ left: 18, right: 18, top: 58, bottom: 18 })
      .margin({ top: 54 })
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(356)
    .backgroundColor('#343941')
  }

  @Builder
  private CollapsingTopBar() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width('100%')
        .height(82)
        .backgroundColor('#FFFFFF')
        .opacity(this.getTitleBarProgress())

      Row() {
        Row() {
          Image($r('app.media.fanhui'))
            .width(18)
            .height(18)
        }
        .width(34)
        .height(34)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.getTitleBarProgress() > 0.72 ? '#F5F5F5' : '#CCFFFFFF')
        .borderRadius(17)
        .onClick(() => {
          this.navStack.pop()
        })

        Text(this.getDisplayTitle().length > 0 ? this.getDisplayTitle() : '演出详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 10, right: 8 })
          .opacity(this.getTitleBarProgress())

        Button() {
          Image($r('app.media.refrech'))
            .width(18)
            .height(18)
            .fillColor(this.isRefreshingPage ? '#BBBBBB' :
              (this.getTitleBarProgress() > 0.55 ? '#666666' : '#FFFFFF'))
        }
          .width(40)
          .height(40)
          .backgroundColor('#00000000')
          .enabled(!this.isRefreshingPage)
          .onClick(() => {
            if (!this.isRefreshingPage) {
              this.manualRefreshDetail()
            }
          })
      }
      .width('100%')
      .height(82)
      .padding({ left: 10, right: 12, top: 34, bottom: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(82)
    .zIndex(20)
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '演出详情不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height(240)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private DetailLoadingArea() {
    Column() {
      Row() {
        Column() {}
          .width(96)
          .height(14)
          .backgroundColor('#EEEEEE')
          .borderRadius(7)

        Column() {}
          .width(72)
          .height(14)
          .margin({ left: 10 })
          .backgroundColor('#F2F2F2')
          .borderRadius(7)
      }
      .width('100%')

      Column() {}
        .width('100%')
        .height(12)
        .margin({ top: 14 })
        .backgroundColor('#F2F2F2')
        .borderRadius(6)

      Column() {}
        .width('72%')
        .height(12)
        .margin({ top: 10 })
        .backgroundColor('#F2F2F2')
        .borderRadius(6)
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  private handleBreakpointChange(breakpoint: string): void {
    if (this.breakPoint === breakpoint) {
      return
    }
    this.invalidateAnchorMeasurements()
    this.breakPoint = breakpoint
    if (this.isTabletLayout()) {
      this.statusBarDark = true
      WindowImmersiveUtil.updateDetailStatusContent(this, true)
    } else {
      this.handleDetailScroll()
    }
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private handleViewportAreaChange(width: number, height: number): void {
    if (Math.abs(width - this.detailViewportWidth) <= 0.5 && Math.abs(height - this.detailViewportHeight) <= 0.5) {
      return
    }
    this.detailViewportWidth = width
    this.detailViewportHeight = height
    this.invalidateAnchorMeasurements()
  }

  private invalidateAnchorMeasurements(): void {
    this.introAnchorOffset = -1
    this.noticeAnchorOffset = -1
    this.secondaryAnchorVisible = false
    this.activeSecondaryAnchor = 0
    this.layoutMeasureVersion++
  }

  private getTitleBarProgress(): number {
    return this.isTabletLayout() ? 1 : this.titleBarProgress
  }

  private handleDetailScroll(): void {
    const yOffset: number = this.detailScroller.currentOffset().yOffset
    const progress: number = this.isTabletLayout() ? 1 : Math.max(0, Math.min(1, (yOffset - 150) / 150))
    if (Math.abs(progress - this.titleBarProgress) > 0.01) {
      this.titleBarProgress = progress
    }

    const nextStatusBarDark: boolean = progress >= 0.78
    if (nextStatusBarDark !== this.statusBarDark) {
      this.statusBarDark = nextStatusBarDark
      WindowImmersiveUtil.updateDetailStatusContent(this, nextStatusBarDark)
    }

    this.updateSecondaryAnchorState(yOffset)
  }

  private updateSecondaryAnchorState(yOffset: number): void {
    if (this.introAnchorOffset < 0) {
      if (this.secondaryAnchorVisible) {
        this.secondaryAnchorVisible = false
      }
      return
    }

    const stickyBottom: number = this.topBarHeight + this.secondaryAnchorHeight
    const introThreshold: number = Math.max(0, this.introAnchorOffset - stickyBottom)
    const visible: boolean = yOffset >= introThreshold
    if (visible !== this.secondaryAnchorVisible) {
      this.secondaryAnchorVisible = visible
    }

    let nextIndex: number = 0
    if (visible && this.noticeAnchorOffset >= 0) {
      const noticeThreshold: number = Math.max(0, this.noticeAnchorOffset - stickyBottom)
      if (yOffset >= noticeThreshold || this.detailScroller.isAtEnd()) {
        nextIndex = 1
      }
    }
    if (nextIndex !== this.activeSecondaryAnchor) {
      this.activeSecondaryAnchor = nextIndex
    }
  }

  private captureIntroAnchor(area: Area): void {
    const yOffset: number = this.detailScroller.currentOffset().yOffset
    const globalY: number = Number(area.globalPosition?.y ?? 0)
    this.introAnchorOffset = globalY + yOffset
    this.updateSecondaryAnchorState(yOffset)
  }

  private captureNoticeAnchor(area: Area): void {
    const yOffset: number = this.detailScroller.currentOffset().yOffset
    const globalY: number = Number(area.globalPosition?.y ?? 0)
    this.noticeAnchorOffset = globalY + yOffset
    this.updateSecondaryAnchorState(yOffset)
  }

  private scrollToSecondaryAnchor(index: number): void {
    const anchorOffset: number = index === 0 ? this.introAnchorOffset : this.noticeAnchorOffset
    if (anchorOffset < 0) {
      return
    }
    const targetOffset: number = Math.max(0, anchorOffset - this.topBarHeight - this.secondaryAnchorHeight)
    this.detailScroller.scrollTo({
      xOffset: 0,
      yOffset: targetOffset,
      animation: {
        duration: 260,
        curve: Curve.Ease
      }
    })
  }

  private getDisplayPosterUrl(): string {
    if (this.detailVO !== undefined) {
      const detailPoster: string = (this.detailVO as PerformanceDetailVO).posterUrl
      if (detailPoster.length > 0) {
        return detailPoster
      }
    }
    return this.routePosterUrl
  }

  private getDisplayTitle(): string {
    if (this.detailVO !== undefined) {
      return (this.detailVO as PerformanceDetailVO).title
    }
    return this.previewTitle
  }

  private getDisplayCategoryName(): string {
    if (this.detailVO !== undefined) {
      return (this.detailVO as PerformanceDetailVO).categoryName
    }
    return this.previewCategoryName
  }

  private getDisplayStartTime(): string {
    if (this.selectedStartTime.length > 0) {
      return this.selectedStartTime
    }
    return this.previewStartTime
  }

  private getDisplayVenueLine(): string {
    const cityName: string = this.vm.selectedSession?.cityName ?? this.previewCityName
    const venueName: string = this.selectedVenueName.length > 0 ? this.selectedVenueName : this.previewVenueName
    if (cityName.length > 0 && venueName.length > 0) {
      return cityName + ' | ' + venueName
    }
    if (venueName.length > 0) {
      return venueName
    }
    return cityName
  }


  @Builder
  private SessionArea() {
    PerformanceSessionSelector({
      sessions: (this.detailVO as PerformanceDetailVO).sessions,
      selectedSessionId: this.selectedSessionId,
      pageVersion: this.pageVersion,
      tablet: this.isTabletLayout(),
      onSelect: (sessionId: string): void => {
        this.handleChangeSession(sessionId)
      }
    })
  }

  @Builder
  private VenueArea() {
    PerformanceVenueCard({
      venueName: this.selectedVenueName,
      venueAddress: this.selectedVenueAddress,
      tablet: this.isTabletLayout(),
      onNavigate: (): void => {
        this.openSelectedVenueNavigation()
      }
    })
  }

  @Builder
  private ServiceTagArea() {
    Row() {
      Scroll(this.serviceTagScroller) {
        Row() {
          ForEach((this.detailVO as PerformanceDetailVO).serviceTags, (item: ServiceTagVO) => {
            Row() {
              Image(MediaResourceUtil.getMedia(this.isRefundServiceTag(item) ? 'gantanhaozhong' : 'duigouzhong'))
                .width(this.isTabletLayout() ? 19 : 17)
                .height(this.isTabletLayout() ? 19 : 17)
                .fillColor(this.isRefundServiceTag(item) ? '#E5484D' : '#222222')
                .margin({ right: 4 })

              Text(item.tagName)
                .fontSize(this.isTabletLayout() ? 14 : 12)
                .fontColor('#222222')
                .maxLines(1)
            }
            .margin({ right: 14 })
            .onClick(() => {
              this.showServiceTagDialog(item)
            })
          }, (item: ServiceTagVO) => item.tagId + '_' + item.tagName + '_' + String(this.pageVersion))
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .onAreaChange((_oldValue: Area, newValue: Area) => {
          this.serviceTagContentWidth = Number(newValue.width ?? 0)
          this.updateServiceTagOverflow()
        })
      }
      .layoutWeight(1)
      .height('100%')
      .align(Alignment.Start)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.serviceTagViewportWidth = Number(newValue.width ?? 0)
        this.updateServiceTagOverflow()
      })
      .onDidScroll(() => {
        this.updateServiceTagOverflow()
      })

      if (this.showServiceTagMoreArrow) {
        Text('›')
          .fontSize(20)
          .fontColor('#777777')
          .width(24)
          .height(36)
          .textAlign(TextAlign.Center)
          .margin({ left: 4 })
          .backgroundColor('#F5F5F5')
          .borderRadius(12)
      }
    }
    .width('100%')
    .height(this.isTabletLayout() ? 52 : 44)
    .padding({ left: this.isTabletLayout() ? 14 : 12, right: this.isTabletLayout() ? 14 : 10 })
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private DetailContentArea() {
    Column() {
      Text('演出简介')
        .fontSize(this.isTabletLayout() ? 20 : 17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Web({
        src: RichTextHtmlUtil.buildDataUrl(this.selectedDetailContent, this.pageVersion, this.isTabletLayout()),
        controller: this.detailWebController,
        renderMode: RenderMode.SYNC_RENDER
      })
        .width('100%')
        .layoutMode(WebLayoutMode.FIT_CONTENT)
        .overScrollMode(OverScrollMode.NEVER)
        .margin({ top: 8 })
        .javaScriptAccess(false)
        .domStorageAccess(false)
        .zoomAccess(false)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 16 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.captureIntroAnchor(newValue)
    })
  }

  @Builder
  private SecondaryAnchorBar() {
    Row() {
      this.SecondaryAnchorItem('介绍', 0)
      this.SecondaryAnchorItem('观演须知', 1)
    }
    .width('100%')
    .height(this.secondaryAnchorHeight)
    .padding({ left: 24, right: 24 })
    .margin({ top: this.topBarHeight })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
    .zIndex(19)
  }

  @Builder
  private SecondaryAnchorItem(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(15)
        .fontWeight(this.activeSecondaryAnchor === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeSecondaryAnchor === index ? '#222222' : '#777777')

      Column() {}
        .width(this.activeSecondaryAnchor === index ? 24 : 0)
        .height(2)
        .margin({ top: 7 })
        .backgroundColor('#E33B3B')
        .borderRadius(1)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .padding({ bottom: 6 })
    .onClick(() => {
      this.scrollToSecondaryAnchor(index)
    })
  }

  @Builder
  private NoticeArea() {
    PerformanceNoticeGrid({
      items: (this.detailVO as PerformanceDetailVO).noticeItems,
      tablet: this.isTabletLayout(),
      wide: ResponsiveLayout.isWideBreakpoint(this.breakPoint),
      onSelect: (item: NoticeItemVO): void => {
        this.showNoticeDialog(item)
      },
      onMeasured: (area: Area): void => {
        this.captureNoticeAnchor(area)
      }
    })
  }

  @Builder
  private BottomActionBar() {
    PerformanceBottomActionBar({
      wanted: this.isWanted,
      canBuy: this.canBuy,
      buyButtonText: this.buyButtonText,
      onWant: (): void => {
        this.handleWantAction()
      },
      onBuy: (): void => {
        this.handleBuyAction()
      }
    })
  }

  @Builder
  private ServiceTagDialogOverlay() {
    PerformanceServiceTagDialog({
      title: this.serviceTagDialogTitle,
      description: this.serviceTagDialogDescription,
      items: this.serviceTagDialogItems,
      tablet: this.isTabletLayout(),
      onClose: (): void => {
        this.closeServiceTagDialog()
      }
    })
  }

  private handleWantAction(): void {
    const currentUserId: string = this.getCurrentUserId()
    if (currentUserId.length === 0 || !this.userRepository.isLogin()) {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      return
    }
    this.vm.userId = currentUserId
    this.toggleWant()
  }

  private handleBuyAction(): void {
    if (!this.canBuy) {
      return
    }
    AppNavigator.openTicketSelect(this.navStack, {
      projectId: this.vm.projectId,
      selectedSessionId: this.selectedSessionId,
      sessionId: this.selectedSessionId,
      userId: this.getCurrentUserId()
    })
  }

  private updateServiceTagOverflow(): void {
    const overflow: boolean = this.serviceTagContentWidth > this.serviceTagViewportWidth + 2
    const nextVisible: boolean = overflow && !this.serviceTagScroller.isAtEnd()
    if (nextVisible !== this.showServiceTagMoreArrow) {
      this.showServiceTagMoreArrow = nextVisible
    }
  }

  private isRefundServiceTagName(tagName: string): boolean {
    return tagName === '条件退' || tagName === '不可退'
  }

  private closeServiceTagDialog(): void {
    this.serviceTagDialogVisible = false
  }

  private openSelectedVenueNavigation(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    VenueNavigationUtil.open(context, this.getUIContext(), this.selectedVenueName, this.selectedVenueAddress,
      this.hasSelectedVenueCoordinate ? this.selectedVenueLatitude : undefined,
      this.hasSelectedVenueCoordinate ? this.selectedVenueLongitude : undefined)
  }

  private isRefundServiceTag(item: ServiceTagVO): boolean {
    return this.isRefundServiceTagName(item.tagName)
  }

  private showServiceTagDialog(item: ServiceTagVO): void {
    this.serviceTagDialogTitle = item.tagName
    this.serviceTagDialogDescription = item.description ?? ''
    this.serviceTagDialogItems = (item.detailItems ?? []).slice()
    this.serviceTagDialogVisible = true
  }

  private showNoticeDialog(item: NoticeItemVO): void {
    this.getUIContext().showAlertDialog({
      title: item.title,
      message: item.description,
      primaryButton: { value: '知道了', action: () => {} }
    })
  }

  private async initPage(params: PerformanceDetailNavParams): Promise<void> {
    this.isLoading = true
    const projectId: string = params.projectId ?? ''
    const sessionId: string = params.sessionId ?? ''
    const userId: string = params.userId ?? this.getCurrentUserId()
    const cityName: string = this.cityRepository.getCurrentCity()

    if (projectId.length === 0) {
      this.vm.errorMessage = '演出项目不存在'
      this.syncFromVm()
      return
    }

    if (sessionId.length > 0) {
      await this.vm.loadDetail(projectId, cityName, sessionId, userId)
    } else {
      await this.vm.loadDetailByProject(projectId, cityName, userId)
    }

    this.syncFromVm()
  }

  private async reloadCurrentDetail(): Promise<void> {
    const currentUserId: string = this.getCurrentUserId()
    const projectId: string = this.vm.projectId.length > 0 ? this.vm.projectId : this.routeProjectId
    const selectedSessionId: string = this.vm.getSelectedSessionId()
    if (projectId.length === 0) {
      return
    }
    if (selectedSessionId.length > 0) {
      await this.vm.loadDetail(projectId, this.cityRepository.getCurrentCity(), selectedSessionId, currentUserId)
    } else {
      await this.vm.loadDetailByProject(projectId, this.cityRepository.getCurrentCity(), currentUserId)
    }
    this.syncFromVm()
  }

  private async manualRefreshDetail(): Promise<void> {
    if (this.isRefreshingPage) return
    this.isRefreshingPage = true
    try {
      await this.reloadCurrentDetail()
    } finally {
      this.isRefreshingPage = false
    }
  }

  private async handleChangeSession(sessionId: string): Promise<void> {
    await this.vm.changeSession(sessionId, this.cityRepository.getCurrentCity())
    this.syncFromVm()
  }

  private getCurrentUserId(): string {
    const user = this.userRepository.getCurrentUser()
    return user?.userId ?? ''
  }

  private getSelectedPriceRangeText(): string {
    if (this.selectedMinPrice === undefined && this.selectedMaxPrice === undefined) {
      return ''
    }

    if (this.selectedMinPrice !== undefined && this.selectedMaxPrice !== undefined && this.selectedMinPrice !== this.selectedMaxPrice) {
      return '￥' + this.selectedMinPrice + ' - ' + this.selectedMaxPrice
    }

    if (this.selectedMinPrice !== undefined) {
      return '￥' + this.selectedMinPrice + ' 起'
    }

    return '￥' + this.selectedMaxPrice
  }

  private syncFromVm(): void {
    const detail: PerformanceDetailVO | undefined = this.vm.detailVO

    this.detailVO = this.cloneDetailVO(detail)
    this.selectedSessionId = this.vm.getSelectedSessionId()
    this.selectedStartTime = this.vm.selectedSession?.startTime ?? ''
    this.selectedMinPrice = detail?.minPrice
    this.selectedMaxPrice = detail?.maxPrice
    this.selectedVenueName = detail?.venue.venueName ?? ''
    this.selectedVenueAddress = detail?.venue.venueAddress ?? ''
    this.hasSelectedVenueCoordinate = detail?.venue.latitude !== undefined && detail?.venue.longitude !== undefined
    this.selectedVenueLatitude = detail?.venue.latitude ?? 0
    this.selectedVenueLongitude = detail?.venue.longitude ?? 0
    this.selectedDetailContent = detail?.detailContent ?? ''
    this.isWanted = detail?.isWanted ?? false
    this.canBuy = this.vm.canBuyCurrentSession()
    this.buyButtonText = this.buildBuyButtonText()
    this.errorMessage = this.vm.errorMessage
    this.isLoading = this.vm.isLoading
    this.pageVersion++
  }

  private buildBuyButtonText(): string {
    if (this.vm.selectedSession === undefined) {
      return '不可购票'
    }

    if (this.vm.selectedSession.sessionStatus === SessionStatus.PRESALE) {
      return '立即预订'
    }

    if (this.vm.selectedSession.sessionStatus === SessionStatus.ON_SALE) {
      return '立即购票'
    }

    if (this.vm.selectedSession.sessionStatus === SessionStatus.SOLD_OUT) {
      return '已售罄'
    }

    return '不可购票'
  }

  private cloneDetailVO(source: PerformanceDetailVO | undefined): PerformanceDetailVO | undefined {
    if (source === undefined) {
      return undefined
    }

    const sessions: PerformanceSessionItemVO[] = []
    source.sessions.forEach((item: PerformanceSessionItemVO) => {
      sessions.push({
        sessionId: item.sessionId,
        cityName: item.cityName,
        stationName: item.stationName,
        startTime: item.startTime,
        sessionStatus: item.sessionStatus
      })
    })

    const venue: VenueDisplayVO = {
      venueId: source.venue.venueId,
      venueName: source.venue.venueName,
      venueAddress: source.venue.venueAddress,
      longitude: source.venue.longitude,
      latitude: source.venue.latitude
    }

    const serviceTags: ServiceTagVO[] = []
    source.serviceTags.forEach((item: ServiceTagVO) => {
      serviceTags.push({
        tagId: item.tagId,
        tagName: item.tagName,
        description: item.description,
        detailItems: item.detailItems
      })
    })

    const noticeItems: NoticeItemVO[] = []
    source.noticeItems.forEach((item: NoticeItemVO) => {
      noticeItems.push({
        noticeId: item.noticeId,
        title: item.title,
        iconUrl: item.iconUrl,
        description: item.description
      })
    })

    const result: PerformanceDetailVO = {
      projectId: source.projectId,
      selectedSessionId: source.selectedSessionId,
      posterUrl: source.posterUrl,
      title: source.title,
      categoryName: source.categoryName,
      minPrice: source.minPrice,
      maxPrice: source.maxPrice,
      isWanted: source.isWanted,
      sessions: sessions,
      venue: venue,
      serviceTags: serviceTags,
      detailContent: source.detailContent,
      noticeItems: noticeItems
    }

    return result
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString() + '_' + this.layoutMeasureVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
  private async toggleWant(): Promise<void> {
    await this.vm.toggleWant()
    this.syncFromVm()
  }

}
