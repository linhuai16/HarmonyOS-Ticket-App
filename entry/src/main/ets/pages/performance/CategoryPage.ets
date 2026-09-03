import { AppNavigator, CategoryNavParams } from '../../navigation/AppNavigation'

import {
  CategoryPerformanceItemVO,
  PerformanceSortType
} from '../../model/vo/performance/CategoryPageVO'

import { CategoryViewModel } from '../../viewmodel/CategoryViewModel'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
import { PerformanceDataSource } from '../../common/datasource/PerformanceDataSource'
import { TabletSearchPanel, TabletSearchPopupState } from '../../common/TabletSearchPanel'
interface CategoryTabItem {
  categoryId?: string
  categoryName: string
}

@Reusable
@Component
struct CategoryPerformanceCard {
  @Consume('appNavStack') navStack: NavPathStack
  @State item: CategoryPerformanceItemVO = new CategoryPerformanceItemVO()

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as CategoryPerformanceItemVO
  }

  build() {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia(this.item.posterUrl))
          .width(90)
          .height(120)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#F2F2F2')
          .borderRadius(8)

        Text(this.item.categoryName)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .backgroundColor('#E33B3B')
          .borderRadius({ topLeft: 8, bottomRight: 8 })
      }

      Column() {
        Column() {
          Text(this.item.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(this.item.startTime)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')

          Text(this.item.cityName + ' | ' + this.item.venueName)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .width('100%')

          Text(this.getSessionStatusText(this.item.sessionStatus))
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row() {
          Blank()
          if (this.item.minPrice !== undefined) {
            Text('￥' + this.item.minPrice + ' 起')
              .fontSize(14)
              .fontColor('#E33B3B')
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
      }
      .height(120)
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
    }
    .width('calc(100% - 24vp)')
    .padding(10)
    .margin({ left: 12, right: 12, top: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      AppNavigator.openPerformanceDetail(this.navStack, {
        projectId: this.item.projectId,
        sessionId: this.item.sessionId,
        posterUrl: this.item.posterUrl,
        title: this.item.title,
        categoryName: this.item.categoryName,
        startTime: this.item.startTime,
        cityName: this.item.cityName,
        venueName: this.item.venueName,
        minPrice: this.item.minPrice
      })
    })
  }

  private getSessionStatusText(status: SessionStatus): string {
    if (status === SessionStatus.PRESALE) return '预售中'
    if (status === SessionStatus.ON_SALE) return '售卖中'
    if (status === SessionStatus.SOLD_OUT) return '已售罄'
    if (status === SessionStatus.ENDED) return '已结束'
    return ''
  }
}

@Reusable
@Component
struct CategoryPerformanceGridCard {
  @Consume('appNavStack') navStack: NavPathStack
  @State item: CategoryPerformanceItemVO = new CategoryPerformanceItemVO()
  isLarge: boolean = false

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as CategoryPerformanceItemVO
  }

  build() {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia(this.item.posterUrl))
          .width(this.isLarge ? 108 : 94)
          .height(this.isLarge ? 144 : 126)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#F2F2F2')
          .borderRadius(8)

        Text(this.item.categoryName)
          .fontSize(this.isLarge ? 12 : 11)
          .fontColor('#FFFFFF')
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .backgroundColor('#E33B3B')
          .borderRadius({ topLeft: 8, bottomRight: 8 })
      }
      .width(this.isLarge ? 108 : 94)
      .height(this.isLarge ? 144 : 126)

      Column() {
        Text(this.item.title)
          .fontSize(this.isLarge ? 17 : 16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.item.startTime)
          .fontSize(this.isLarge ? 14 : 13)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%')

        Text(this.item.cityName + ' | ' + this.item.venueName)
          .fontSize(this.isLarge ? 13 : 12)
          .fontColor('#777777')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')

        Row() {
          Text(this.getSessionStatusText(this.item.sessionStatus))
            .fontSize(this.isLarge ? 13 : 12)
            .fontColor('#999999')
          Blank()
          if (this.item.minPrice !== undefined) {
            Text('￥' + this.item.minPrice + ' 起')
              .fontSize(this.isLarge ? 16 : 15)
              .fontColor('#E33B3B')
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .height(this.isLarge ? 144 : 126)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ left: this.isLarge ? 14 : 12 })
    }
    .width('100%')
    .padding(this.isLarge ? 16 : 14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      AppNavigator.openPerformanceDetail(this.navStack, {
        projectId: this.item.projectId,
        sessionId: this.item.sessionId,
        posterUrl: this.item.posterUrl,
        title: this.item.title,
        categoryName: this.item.categoryName,
        startTime: this.item.startTime,
        cityName: this.item.cityName,
        venueName: this.item.venueName,
        minPrice: this.item.minPrice
      })
    })
  }

  private getSessionStatusText(status: SessionStatus): string {
    if (status === SessionStatus.PRESALE) return '预售中'
    if (status === SessionStatus.ON_SALE) return '售卖中'
    if (status === SessionStatus.SOLD_OUT) return '已售罄'
    if (status === SessionStatus.ENDED) return '已结束'
    return ''
  }
}

@Entry
@Component
export struct CategoryPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: CategoryNavParams = {}

  private vm: CategoryViewModel = new CategoryViewModel()
  private performanceDataSource: PerformanceDataSource<CategoryPerformanceItemVO> = new PerformanceDataSource<CategoryPerformanceItemVO>()

  @State pageVersion: number = 0
  @State currentCityName: string = '北京'
  @State selectedCategoryId: string = ''
  @State selectedSortType: PerformanceSortType = PerformanceSortType.HOT
  @State selectedFilterTime: string = ''
  @State performanceList: CategoryPerformanceItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State isRefreshing: boolean = false
  @State errorMessage: string = ''
  @State breakPoint: string = 'sm'
  @State contentWidth: number = 0
  @State tabletResultWidth: number = 0
  @State tabletSearchVisible: boolean = false
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  @StorageLink('current_city')
  @Watch('onStorageCityChanged')
  storageCityName: string = '北京'

  @StorageLink('performance_changed_version')
  @Watch('onPerformanceDataChanged')
  performanceChangedVersion: number = 0

  private categoryTabs: CategoryTabItem[] = [
    { categoryId: undefined, categoryName: '全部' },
    { categoryId: '1', categoryName: '演唱会' },
    { categoryId: '2', categoryName: '话剧' },
    { categoryId: '3', categoryName: '音乐节' },
    { categoryId: '4', categoryName: '脱口秀' },
    { categoryId: '5', categoryName: '沉浸剧场' },
    { categoryId: '6', categoryName: '相声' },
    { categoryId: '7', categoryName: '戏曲艺术' },
    { categoryId: '8', categoryName: '舞蹈舞剧' }
  ]

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.isPageVisible = true
    const params: CategoryNavParams = this.navParams
    if (this.vm.restoreCache(params.categoryId)) {
      this.syncFromVm(true)
    }
    this.initPage(params.categoryId)
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.isPageVisible = true
    if (this.pendingExternalRefresh) {
      this.pendingExternalRefresh = false
      setTimeout(() => {
        if (this.isPageVisible) {
          this.reloadIfNeeded()
        }
      }, 700)
    }
  }

  onPageHide(): void {
    this.isPageVisible = false
    this.tabletSearchVisible = false
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
          if (this.isTabletLayout()) {
            this.TabletCategoryBody()
          } else {
            this.PhoneCategoryBody()
          }
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
    .hideTitleBar(true)
    .onShown(() => {
      this.onPageShow()
    })
    .onHidden(() => { this.onPageHide() })
  }

  @Builder
  private PhoneCategoryBody() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.ErrorBanner()
      this.CategoryTabs()
      this.SortBar()

      Refresh({ refreshing: $$this.isRefreshing }) {
        this.ListArea()
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.handleRefresh()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletCategoryBody() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.ErrorBanner()
      if (!this.isWideLayout()) {
        this.CategoryTabs()
        this.SortBar()
      }

      Row({ space: this.isWideLayout() ? 16 : 0 }) {
        if (this.isWideLayout()) {
          this.TabletFilterPane()
        }

        Refresh({ refreshing: $$this.isRefreshing }) {
          this.TabletResultGrid()
        }
        .layoutWeight(1)
        .height('100%')
        .onRefreshing(() => {
          this.handleRefresh()
        })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TabletFilterPane() {
    Scroll() {
      Column() {
        Text('演出分类')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .width('100%')

        ForEach(this.categoryTabs, (item: CategoryTabItem) => {
          Row() {
            Text(item.categoryName)
              .fontSize(16)
              .fontColor(this.isCategorySelected(item.categoryId) ? '#E33B3B' : '#444444')
              .fontWeight(this.isCategorySelected(item.categoryId) ? FontWeight.Bold : FontWeight.Normal)
          }
          .width('100%')
          .height(46)
          .padding({ left: 14, right: 14 })
          .margin({ top: 6 })
          .backgroundColor(this.isCategorySelected(item.categoryId) ? '#FFECEC' : '#F8F8F8')
          .borderRadius(8)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.handleChangeCategory(item.categoryId)
          })
        }, (item: CategoryTabItem) => item.categoryId === undefined ? 'all' : item.categoryId)

        Text('排序')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .width('100%')
          .margin({ top: 20 })

        this.TabletFilterAction('热度排序', this.selectedSortType === PerformanceSortType.HOT, 'HOT')
        this.TabletFilterAction('最新排序', this.selectedSortType === PerformanceSortType.NEW, 'NEW')
        this.TabletFilterAction(this.getFilterTimeText(), this.selectedFilterTime.length > 0, 'TIME')
      }
      .width('100%')
      .padding({ left: 14, right: 14, bottom: 14 })
      .alignItems(HorizontalAlign.Start)
      .align(Alignment.TopStart)
    }
    .width(ResponsiveLayout.getTabletSidePaneWidth(this.contentWidth))
    .height('100%')
    .align(Alignment.TopStart)
    .scrollBar(BarState.Off)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  private TabletFilterAction(label: string, selected: boolean, actionType: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(selected ? '#E33B3B' : '#555555')
        .fontWeight(selected ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height(44)
    .padding({ left: 14, right: 14 })
    .margin({ top: 6 })
    .backgroundColor(selected ? '#FFF2F2' : '#F8F8F8')
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (actionType === 'HOT') {
        this.handleChangeSort(PerformanceSortType.HOT)
      } else if (actionType === 'NEW') {
        this.handleChangeSort(PerformanceSortType.NEW)
      } else {
        this.toggleFilterTime()
      }
    })
  }

  @Builder
  private TabletResultGrid() {
    Grid() {
      if (this.performanceList.length === 0) {
        GridItem() {
          Column() {
            if (this.isLoading) {
              LoadingProgress()
                .width(32)
                .height(32)
                .color('#E33B3B')
              Text('正在加载演出...')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 10 })
            } else {
              Text(this.errorMessage.length > 0 ? '演出加载失败，请下拉重试' : '暂无演出')
                .fontSize(15)
                .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
              Text('当前城市：' + this.currentCityName)
                .fontSize(12)
                .fontColor('#BBBBBB')
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .height(220)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .columnStart(0)
        .columnEnd(this.getTabletGridColumnCount() - 1)
      } else {
        LazyForEach(this.performanceDataSource, (item: CategoryPerformanceItemVO) => {
          GridItem() {
            CategoryPerformanceGridCard({ item: item, isLarge: this.getTabletGridColumnCount() >= 4 })
          }
        }, (item: CategoryPerformanceItemVO) => item.projectId + '_' + item.sessionId)

        GridItem() {
          this.LoadMoreArea()
        }
        .columnStart(0)
        .columnEnd(this.getTabletGridColumnCount() - 1)
      }
    }
    .columnsTemplate(this.getTabletGridTemplate())
    .columnsGap(18)
    .rowsGap(18)
    .cachedCount(8)
    .width('100%')
    .height('100%')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const nextWidth: number = Number(newValue.width ?? 0)
      if (Math.abs(nextWidth - this.tabletResultWidth) > 0.5) {
        this.tabletResultWidth = nextWidth
      }
    })
    .onReachEnd(() => {
      this.handleLoadMore()
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
      .width(36)
      .height(44)
      .justifyContent(FlexAlign.Start)
      .onClick(() => {
        this.navStack.pop()
      })

      Text(this.currentCityName.length > 0 ? this.currentCityName : this.storageCityName)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4, right: 12 })
        .height(36)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/city/CitySelectPage' })
        })

      if (this.isTabletLayout()) {
        Blank()

        Row() {
          Text('搜索演出、艺人、场馆')
            .fontSize(15)
            .fontColor('#999999')
        }
        .width(ResponsiveLayout.getTabletTopSearchWidth(this.contentWidth, this.breakPoint))
        .height(44)
        .padding({ left: 14, right: 14 })
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .onClick(() => {
          this.tabletSearchVisible = !this.tabletSearchVisible
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
          Text('搜索演出')
            .fontSize(14)
            .fontColor('#999999')
        }
        .height(36)
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .padding({ left: 12 })
        .onClick(() => {
          AppNavigator.openSearch(this.navStack, {})
        })
      }
    }
    .width('100%')
    .height(this.isTabletLayout() ? 62 : 54)
    .padding({
      left: this.isTabletLayout() ? 20 : 12,
      right: this.isTabletLayout() ? 20 : 12,
      top: 9,
      bottom: 9
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
    if (this.errorMessage.length > 0 && this.performanceList.length > 0) {
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
  private CategoryTabs() {
    Scroll() {
      Row() {
        ForEach(this.categoryTabs, (item: CategoryTabItem) => {
          Row() {
            Text(item.categoryName)
              .fontSize(14)
              .fontColor(this.isCategorySelected(item.categoryId) ? '#E33B3B' : '#333333')
              .fontWeight(this.isCategorySelected(item.categoryId) ? FontWeight.Bold : FontWeight.Normal)
          }
          .height(32)
          .padding({ left: 12, right: 12 })
          .backgroundColor(this.isCategorySelected(item.categoryId) ? '#FFECEC' : '#FFFFFF')
          .borderRadius(16)
          .margin({ right: 8 })
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.handleChangeCategory(item.categoryId)
          })
        }, (item: CategoryTabItem) => item.categoryId === undefined ? 'all' : item.categoryId)
      }
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(46)
  }

  @Builder
  private SortBar() {
    Row() {
      Row() {
        Text('热度排序')
          .fontSize(13)
          .fontColor(this.selectedSortType === PerformanceSortType.HOT ? '#E33B3B' : '#666666')
          .fontWeight(this.selectedSortType === PerformanceSortType.HOT ? FontWeight.Bold : FontWeight.Normal)
      }
      .height(34)
      .padding({ left: 4, right: 14 })
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.handleChangeSort(PerformanceSortType.HOT)
      })

      Row() {
        Text('最新排序')
          .fontSize(13)
          .fontColor(this.selectedSortType === PerformanceSortType.NEW ? '#E33B3B' : '#666666')
          .fontWeight(this.selectedSortType === PerformanceSortType.NEW ? FontWeight.Bold : FontWeight.Normal)
      }
      .height(34)
      .padding({ left: 4, right: 14 })
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.handleChangeSort(PerformanceSortType.NEW)
      })

      Blank()

      Row() {
        Text(this.getFilterTimeText())
          .fontSize(13)
          .fontColor(this.selectedFilterTime.length > 0 ? '#E33B3B' : '#666666')
      }
      .height(34)
      .padding({ left: 12, right: 4 })
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.toggleFilterTime()
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private ListArea() {
    List() {
      if (this.performanceList.length === 0) {
        ListItem() {
          Column() {
            if (this.isLoading) {
              LoadingProgress()
                .width(32)
                .height(32)
                .color('#E33B3B')
              Text('正在加载演出...')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 10 })
            } else {
              Text(this.errorMessage.length > 0 ? '演出加载失败，请下拉重试' : '暂无演出')
                .fontSize(15)
                .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
                .textAlign(TextAlign.Center)

              Text('当前城市：' + this.currentCityName)
                .fontSize(12)
                .fontColor('#BBBBBB')
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .margin({ top: 80 })
          .alignItems(HorizontalAlign.Center)
        }
      } else {
        LazyForEach(this.performanceDataSource, (item: CategoryPerformanceItemVO) => {
          ListItem() {
            CategoryPerformanceCard({ item: item })
          }
        }, (item: CategoryPerformanceItemVO) => item.projectId + '_' + item.sessionId)

        ListItem() {
          this.LoadMoreArea()
        }
      }
    }
    .width('100%')
    .height('100%')
    .cachedCount(4)
    .onReachEnd(() => {
      this.handleLoadMore()
    })
  }

  @Builder
  private LoadMoreArea() {
    Column() {
      if (this.hasMore) {
        Text(this.isLoading ? '加载中...' : '继续下滑加载更多')
          .fontSize(13)
          .fontColor('#999999')
          .padding(16)
      } else {
        Text('已经到底了')
          .fontSize(13)
          .fontColor('#999999')
          .padding(16)
      }
    }
    .width('100%')
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private isWideLayout(): boolean {
    return ResponsiveLayout.isWideWidth(this.contentWidth)
  }

  private getTabletGridColumnCount(): number {
    return ResponsiveLayout.getTabletGridColumnCount(this.tabletResultWidth)
  }

  private getTabletGridTemplate(): string {
    const count: number = this.getTabletGridColumnCount()
    if (count === 4) {
      return '1fr 1fr 1fr 1fr'
    }
    if (count === 3) {
      return '1fr 1fr 1fr'
    }
    return '1fr 1fr'
  }

  private getTabletSearchRecommendations(): string[] {
    const result: string[] = []
    for (let index: number = 0; index < this.categoryTabs.length && result.length < 8; index++) {
      const keyword: string = this.categoryTabs[index].categoryName.trim()
      if (keyword !== '全部' && keyword.length > 0 && !result.includes(keyword)) {
        result.push(keyword)
      }
    }
    return result
  }

  private async handleRefresh(): Promise<void> {
    this.isRefreshing = true
    await this.vm.refresh()
    this.syncFromVm()
    this.isRefreshing = false
  }

  private async handleLoadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return
    }

    const previousCount: number = this.performanceDataSource.totalCount()
    this.isLoading = true
    await this.vm.loadMore()
    this.syncFromVm(false)
    this.appendPerformanceData(previousCount)
  }

  private onStorageCityChanged(): void {
    const cityName: string = this.storageCityName.trim()

    if (cityName.length === 0 || cityName === this.currentCityName) {
      return
    }
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.handleChangeCity(cityName)
  }

  private onPerformanceDataChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.handleRefresh()
  }

  private async handleChangeCity(cityName: string): Promise<void> {
    const pending: Promise<void> = this.vm.changeCity(cityName)
    this.syncFromVm()
    await pending
    this.syncFromVm()
  }

  private async initPage(categoryId: string | undefined): Promise<void> {
    this.isLoading = true
    await this.vm.initCategoryPage(categoryId)
    this.syncFromVm()
  }

  private async reloadIfNeeded(): Promise<void> {
    const beforeCity: string = this.vm.currentCityName
    await this.vm.reloadIfCityChanged()
    if (beforeCity === this.vm.currentCityName) {
      await this.vm.refresh()
    }
    this.syncFromVm()
  }

  private async handleChangeCategory(categoryId: string | undefined): Promise<void> {
    await this.vm.changeCategory(categoryId)
    this.syncFromVm()
  }

  private async handleChangeSort(sortType: PerformanceSortType): Promise<void> {
    await this.vm.changeSort(sortType)
    this.syncFromVm()
  }

  private appendPerformanceData(previousCount: number): void {
    if (this.performanceList.length < previousCount) {
      this.performanceDataSource.setData(this.performanceList)
      return
    }
    if (this.performanceList.length > previousCount) {
      this.performanceDataSource.appendData(this.performanceList.slice(previousCount))
    }
  }

  private syncFromVm(reloadData: boolean = true): void {
    this.currentCityName = this.vm.currentCityName
    this.selectedCategoryId = this.vm.categoryId ?? ''
    this.selectedSortType = this.vm.sortType
    this.selectedFilterTime = this.vm.filterTime ?? ''
    this.performanceList = this.vm.categoryList.slice()
    this.hasMore = this.vm.hasMore
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    if (reloadData) {
      this.performanceDataSource.setData(this.performanceList)
    }
    this.pageVersion++
  }

  private isCategorySelected(categoryId: string | undefined): boolean {
    return this.selectedCategoryId === (categoryId ?? '')
  }

  private async toggleFilterTime(): Promise<void> {
    if (this.selectedFilterTime.length === 0) {
      await this.vm.changeFilterTime('THIS_MONTH')
    } else {
      await this.vm.clearFilterTime()
    }
    this.syncFromVm()
  }

  private getFilterTimeText(): string {
    if (this.selectedFilterTime === 'THIS_MONTH') {
      return '近一月  ×'
    }
    return '时间筛选'
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
}
