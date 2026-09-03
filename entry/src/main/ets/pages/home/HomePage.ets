import { AppNavigator } from '../../navigation/AppNavigation'
import { HomeCategoryVO, HomeBannerVO, HomeRecommendItemVO } from '../../model/vo/home/HomePageVO'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
import { PerformanceDataSource } from '../../common/datasource/PerformanceDataSource'
import { TabletSearchPanel, TabletSearchPopupState } from '../../common/TabletSearchPanel'

@Reusable
@Component
struct HomeRecommendCard {
  @Consume('appNavStack') navStack: NavPathStack
  @State item: HomeRecommendItemVO = new HomeRecommendItemVO()
  isTablet: boolean = false
  isLarge: boolean = false

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as HomeRecommendItemVO
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia(this.item.posterUrl))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .backgroundColor('#F2F2F2')

        Text(this.item.categoryName)
          .fontSize(this.isLarge ? 12 : (this.isTablet ? 11 : 10))
          .fontColor('#FFFFFF')
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .backgroundColor('#E33B3B')
          .borderRadius({ topLeft: 10, bottomRight: 8 })
      }
      .width('100%')
      .aspectRatio(0.75)
      .clip(true)
      .borderRadius({ topLeft: 10, topRight: 10 })
      .backgroundColor('#F2F2F2')

      Column() {
        Text(this.item.title)
          .fontSize(this.isLarge ? 17 : (this.isTablet ? 16 : 14))
          .fontWeight(FontWeight.Medium)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: this.isTablet ? 7 : 4 })

        Text((this.item.cityName.length > 0 ? this.item.cityName + ' · ' : '') + this.item.startTime)
          .fontSize(this.isLarge ? 14 : (this.isTablet ? 13 : 12))
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: this.isTablet ? 8 : 6 })

        if (this.item.minPrice !== undefined) {
          Text('￥' + this.item.minPrice + ' 起')
            .fontSize(this.isLarge ? 17 : (this.isTablet ? 16 : 14))
            .fontColor('#E33B3B')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 6 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(this.isLarge ? 12 : (this.isTablet ? 10 : 8))
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .onClick(() => {
      AppNavigator.openPerformanceDetail(this.navStack, {
        projectId: this.item.projectId,
        sessionId: this.item.sessionId,
        posterUrl: this.item.posterUrl,
        title: this.item.title,
        categoryName: this.item.categoryName,
        startTime: this.item.startTime,
        cityName: this.item.cityName,
        minPrice: this.item.minPrice
      })
    })
  }
}

@Entry
@Component
export struct HomePage {
  @Consume('appNavStack') navStack: NavPathStack
  private vm: HomeViewModel = new HomeViewModel()
  private recommendDataSource: PerformanceDataSource<HomeRecommendItemVO> = new PerformanceDataSource<HomeRecommendItemVO>()

  @State pageVersion: number = 0
  @State bannerRefreshVersion: number = 0
  @State isPullRefreshing: boolean = false
  @State currentCityName: string = '北京'
  @State categories: HomeCategoryVO[] = []
  @State banners: HomeBannerVO[] = []
  @State recommendList: HomeRecommendItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State breakPoint: string = 'sm'
  @State contentWidth: number = 0
  @State tabletSearchVisible: boolean = false
  @StorageLink('current_city') @Watch('onStorageCityChanged') storageCityName: string = '北京'
  @StorageLink('performance_changed_version') @Watch('onPerformanceDataChanged') performanceChangedVersion: number = 0
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false
  private initializationStarted: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
    this.isPageVisible = true
    if (this.initializationStarted) {
      return
    }
    this.initializationStarted = true
    const cacheRestored: boolean = this.vm.restoreCache()
    if (cacheRestored) {
      this.syncFromVm(true)
    }
    this.loadHomePage()
  }

  onStorageCityChanged(): void {
    if (this.storageCityName.trim().length === 0 || this.storageCityName === this.vm.currentCityName) {
      return
    }
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.changeHomeCity(this.storageCityName)
  }

  onPerformanceDataChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.refreshHomePage()
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
    this.isPageVisible = true
    this.flushPendingExternalRefresh()
  }

  onPageHide(): void {
    this.isPageVisible = false
    this.tabletSearchVisible = false
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
          this.ErrorBanner()

          Refresh({ refreshing: $$this.isPullRefreshing }) {
            Grid() {
              GridItem() {
                this.CategoryGrid()
              }
              .columnStart(0)
              .columnEnd(this.getRecommendColumnCount() - 1)

              if (this.banners.length > 0) {
                GridItem() {
                  this.BannerSwiper()
                }
                .columnStart(0)
                .columnEnd(this.getRecommendColumnCount() - 1)
              }

              GridItem() {
                this.RecommendTitle()
              }
              .columnStart(0)
              .columnEnd(this.getRecommendColumnCount() - 1)

              LazyForEach(this.recommendDataSource, (item: HomeRecommendItemVO) => {
                GridItem() {
                  HomeRecommendCard({ item: item, isTablet: this.isTabletLayout(), isLarge: this.isLargeTabletLayout() })
                }
              }, (item: HomeRecommendItemVO) => item.projectId + '_' + item.sessionId)

              GridItem() {
                this.LoadMoreArea()
              }
              .columnStart(0)
              .columnEnd(this.getRecommendColumnCount() - 1)
            }
            .columnsTemplate(this.getRecommendColumnsTemplate())
            .columnsGap(this.isLargeTabletLayout() ? 18 : (this.isMediumTabletLayout() ? 16 : 10))
            .rowsGap(this.isLargeTabletLayout() ? 18 : (this.isMediumTabletLayout() ? 16 : 10))
            .cachedCount(this.isTabletLayout() ? 8 : 4)
            .padding({
              left: ResponsiveLayout.getPageHorizontalPadding(this.contentWidth),
              right: ResponsiveLayout.getPageHorizontalPadding(this.contentWidth),
              bottom: 16
            })
            .width('100%')
            .constraintSize({ maxWidth: ResponsiveLayout.CONTENT_MAX_WIDTH })
            .height('100%')
            .onReachEnd(() => {
              this.handleLoadMore()
            })
          }
          .layoutWeight(1)
          .onRefreshing(() => {
            this.handleRefreshHome()
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
          const nowVisible: boolean = isVisible && currentRatio > 0
          this.isPageVisible = nowVisible
          if (nowVisible) {
            WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
          }
          if (!nowVisible || !this.pendingExternalRefresh) {
            return
          }
          this.flushPendingExternalRefresh()
        })
      }
    }
    .width('100%')
    .height('100%')
    .onBreakpointChange((breakpoint: string) => {
      this.breakPoint = breakpoint
      if (!this.isTabletLayout()) {
        this.tabletSearchVisible = false
      }
    })
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const nextWidth: number = Number(newValue.width ?? 0)
      if (Math.abs(nextWidth - this.contentWidth) > 0.5) {
        this.contentWidth = nextWidth
      }
    })
  }

  @Builder
  private TopBar() {
    Row() {
      Row() {
        Text(this.currentCityName.length > 0 ? this.currentCityName : '北京')
          .fontSize(this.isLargeTabletLayout() ? 18 : (this.isMediumTabletLayout() ? 17 : 16))
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('⌄')
          .fontSize(14)
          .fontColor('#222222')
          .margin({ left: 2 })
      }
      .height(this.isTabletLayout() ? 42 : 36)
      .padding({ left: 2, right: 4 })
      .onClick(() => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/city/CitySelectPage'
        })
      })

      if (this.isTabletLayout()) {
        Blank()

        Row() {
          Text('搜索演出、艺人、场馆')
            .fontSize(this.isLargeTabletLayout() ? 16 : 15)
            .fontColor('#999999')
        }
        .width(ResponsiveLayout.getTabletTopSearchWidth(this.contentWidth, this.breakPoint))
        .height(44)
        .padding({ left: 14, right: 14 })
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .opacity(this.tabletSearchVisible ? 0 : 1)
        .enabled(!this.tabletSearchVisible)
        .onClick(() => {
          this.tabletSearchVisible = true
        })
        .bindPopup(this.tabletSearchVisible, {
          builder: this.TabletSearchPopup,
          placement: Placement.BottomRight,
          popupColor: '#00000000',
          enableArrow: false,
          autoCancel: true,
          mask: false,
          onStateChange: (event: TabletSearchPopupState): void => {
            this.tabletSearchVisible = event.isVisible
          }
        })
      } else {
        Row() {
          Text('搜索演出、艺人、场馆')
            .fontSize(14)
            .fontColor('#999999')
        }
        .height(36)
        .layoutWeight(1)
        .padding({ left: 12 })
        .margin({ left: 10 })
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .onClick(() => {
          AppNavigator.openSearch(this.navStack, {})
        })
      }
    }
    .width('100%')
    .padding({
      left: this.isLargeTabletLayout() ? 28 : (this.isMediumTabletLayout() ? 20 : 12),
      right: this.isLargeTabletLayout() ? 28 : (this.isMediumTabletLayout() ? 20 : 12),
      top: 12,
      bottom: 8
    })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletSearchPopup() {
    TabletSearchPanel({
      panelWidth: ResponsiveLayout.getTabletTopSearchWidth(this.contentWidth, this.breakPoint),
      recommendedKeywords: this.getTabletSearchRecommendations(),
      onClose: (): void => {
        this.tabletSearchVisible = false
      }
    })
  }

  @Builder
  private ErrorBanner() {
    if (this.errorMessage.length > 0) {
      Row() {
        Text('网络开小差了，下拉刷新重试')
          .fontSize(12)
          .fontColor('#E33B3B')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('calc(100% - 24vp)')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .margin({ left: 12, right: 12, bottom: 8 })
      .backgroundColor('#FFF0F0')
      .borderRadius(8)
    }
  }

  @Builder
  private CategoryGrid() {
    if (this.isTabletLayout()) {
      List({ space: 12 }) {
        ForEach(this.categories, (item: HomeCategoryVO) => {
          ListItem() {
            this.CategoryEntry(item)
          }
          .width(this.getTabletCategoryItemWidth())
        }, (item: HomeCategoryVO) => item.categoryId)
      }
      .width('100%')
      .height(this.isLargeTabletLayout() ? 122 : 112)
      .padding(12)
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    } else {
      Grid() {
        ForEach(this.categories, (item: HomeCategoryVO) => {
          GridItem() {
            this.CategoryEntry(item)
          }
        }, (item: HomeCategoryVO) => item.categoryId)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(8)
      .height(150)
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
  }

  @Builder
  private CategoryEntry(item: HomeCategoryVO) {
    Column() {
      Image(MediaResourceUtil.getMedia(item.iconUrl))
        .width(this.isLargeTabletLayout() ? 52 : (this.isMediumTabletLayout() ? 48 : 40))
        .height(this.isLargeTabletLayout() ? 52 : (this.isMediumTabletLayout() ? 48 : 40))
        .objectFit(ImageFit.Contain)

      Text(item.categoryName)
        .fontSize(this.isLargeTabletLayout() ? 16 : (this.isMediumTabletLayout() ? 15 : 13))
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      AppNavigator.openCategory(this.navStack, { categoryId: item.categoryId })
    })
  }

  @Builder
  private BannerSwiper() {
    Swiper() {
      ForEach(this.banners, (item: HomeBannerVO) => {
        Image(this.getBannerImageSource(item.imageUrl))
          .width('100%')
          .height(this.getBannerHeight())
          .objectFit(ImageFit.Cover)
          .backgroundColor('#ECEFF3')
          .borderRadius(12)
          .onClick(() => {
            AppNavigator.openPerformanceDetail(this.navStack, {
              projectId: item.projectId
            })
          })
      }, (item: HomeBannerVO) => item.bannerId + '_' + item.imageUrl + '_' + String(this.bannerRefreshVersion))
    }
    .autoPlay(this.banners.length > 1)
    .interval(3000)
    .indicator(this.banners.length > 1)
    .height(this.getBannerHeight())
    .constraintSize({ maxWidth: ResponsiveLayout.BANNER_MAX_WIDTH })
    .margin({ top: 2 })
  }

  @Builder
  private RecommendTitle() {
    Row() {
      Text('推荐')
        .fontSize(this.isLargeTabletLayout() ? 24 : (this.isMediumTabletLayout() ? 22 : 20))
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
    }
    .width('100%')
    .margin({ top: 6 })
  }

  @Builder
  private LoadMoreArea() {
    Column() {
      if (this.hasMore) {
        Text(this.isLoading ? '加载中...' : '继续下滑加载更多')
          .fontSize(13)
          .fontColor('#999999')
      } else {
        Text('已经到底了')
          .fontSize(13)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(16)
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private isLargeTabletLayout(): boolean {
    return this.isTabletLayout() && ResponsiveLayout.isLargeTabletWidth(this.contentWidth)
  }

  private isMediumTabletLayout(): boolean {
    return this.isTabletLayout() && !this.isLargeTabletLayout()
  }

  private getRecommendColumnCount(): number {
    if (this.contentWidth <= 0) {
      return 2
    }
    const padding: number = ResponsiveLayout.getPageHorizontalPadding(this.contentWidth) * 2
    return ResponsiveLayout.getResponsiveGridColumnCount(Math.max(0, this.contentWidth - padding),
      ResponsiveLayout.CARD_MIN_WIDTH, 6, 16)
  }

  private getRecommendColumnsTemplate(): string {
    return ResponsiveLayout.getGridTemplate(this.getRecommendColumnCount())
  }

  private getBannerHeight(): number {
    return ResponsiveLayout.getBannerHeight(this.contentWidth)
  }

  private getTabletCategoryItemWidth(): number {
    const visibleCount: number = this.isLargeTabletLayout() ? 8 : 6
    const pagePadding: number = this.isLargeTabletLayout() ? 56 : 40
    const contentPadding: number = 24
    const gapWidth: number = (visibleCount - 1) * 12
    return Math.max(76, (this.contentWidth - pagePadding - contentPadding - gapWidth) / visibleCount)
  }

  private getTabletSearchRecommendations(): string[] {
    const result: string[] = []
    for (let index: number = 0; index < this.categories.length && result.length < 8; index++) {
      const keyword: string = this.categories[index].categoryName.trim()
      if (keyword.length > 0 && !result.includes(keyword)) {
        result.push(keyword)
      }
    }
    return result
  }

  private async handleRefreshHome(): Promise<void> {
    this.isPullRefreshing = true
    await this.vm.refreshHome()
    this.syncFromVm(true, true)
    this.isPullRefreshing = false
  }

  private async handleLoadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return
    }

    const previousCount: number = this.recommendDataSource.totalCount()
    this.isLoading = true
    await this.vm.loadMore()
    this.syncFromVm(false)
    this.appendRecommendData(previousCount)
  }

  private async loadHomePage(): Promise<void> {
    this.isLoading = true
    const changed: boolean = await this.vm.loadHome()
    if (changed) {
      this.syncFromVm(true)
    } else {
      this.isLoading = false
    }
  }

  private async refreshHomePage(): Promise<void> {
    this.isLoading = true
    await this.vm.refreshHome()
    this.syncFromVm(true, true)
  }

  private flushPendingExternalRefresh(): void {
    if (!this.isPageVisible || !this.pendingExternalRefresh) {
      return
    }
    this.pendingExternalRefresh = false
    this.refreshHomePage()
  }

  private async changeHomeCity(cityName: string): Promise<void> {
    const pending: Promise<void> = this.vm.changeCity(cityName)
    this.syncFromVm(true)
    await pending
    this.syncFromVm(true, true)
  }

  private appendRecommendData(previousCount: number): void {
    if (this.recommendList.length < previousCount) {
      this.recommendDataSource.setData(this.recommendList)
      return
    }
    if (this.recommendList.length > previousCount) {
      this.recommendDataSource.appendData(this.recommendList.slice(previousCount))
    }
  }

  private syncFromVm(reloadData: boolean, forceBannerReload: boolean = false): void {
    const previousBannerSignature: string = this.bannerSignature(this.banners)
    this.currentCityName = this.vm.currentCityName
    this.categories = this.vm.categories.slice()
    this.banners = this.vm.banners.slice()
    this.recommendList = this.vm.recommendList.slice()
    this.hasMore = this.vm.hasMore
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    if (reloadData) {
      this.recommendDataSource.setData(this.recommendList)
      if (forceBannerReload || previousBannerSignature !== this.bannerSignature(this.banners)) {
        this.bannerRefreshVersion++
      }
    }
    this.pageVersion++
  }

  private bannerSignature(items: HomeBannerVO[]): string {
    return items.map((item: HomeBannerVO): string => item.bannerId + '|' + item.imageUrl + '|' + item.projectId).join(';')
  }

  private buildBannerImageUrl(imageUrl: string): string {
    const value: string = imageUrl.trim()
    if (value.length === 0 || (!value.startsWith('http://') && !value.startsWith('https://') && !value.startsWith('/'))) {
      return value
    }
    return value + (value.includes('?') ? '&' : '?') + 'refreshVersion=' + this.bannerRefreshVersion
  }

  private getBannerImageSource(imageUrl: string): ResourceStr {
    return MediaResourceUtil.getMedia(this.buildBannerImageUrl(imageUrl))
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
}
