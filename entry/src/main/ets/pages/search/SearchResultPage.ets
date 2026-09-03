import { AppNavigator, SearchResultNavParams } from '../../navigation/AppNavigation'

import { SearchResultItemVO } from '../../model/vo/performance/SearchPageVO'
import { SearchResultViewModel } from '../../viewmodel/SearchResultViewModel'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
import { PerformanceDataSource } from '../../common/datasource/PerformanceDataSource'
@Reusable
@Component
struct SearchPerformanceCard {
  @Consume('appNavStack') navStack: NavPathStack
  @State item: SearchResultItemVO = new SearchResultItemVO()

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as SearchResultItemVO
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
        Text(this.item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.item.startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })
          .width('100%')

        Text(this.item.cityName + ' | ' + this.item.venueName)
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')

        Row() {
          Blank()
          Text(this.getPriceText())
            .fontSize(15)
            .fontColor('#E33B3B')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
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
        minPrice: this.item.minPrice,
        maxPrice: this.item.maxPrice
      })
    })
  }

  private getPriceText(): string {
    if (this.item.minPrice === undefined) {
      return ''
    }
    if (this.item.maxPrice !== undefined) {
      return '￥' + this.item.minPrice + ' - ' + this.item.maxPrice
    }
    return '￥' + this.item.minPrice + ' 起'
  }
}


@Reusable
@Component
struct SearchPerformanceGridCard {
  @Consume('appNavStack') navStack: NavPathStack
  @State item: SearchResultItemVO = new SearchResultItemVO()
  isLarge: boolean = false

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as SearchResultItemVO
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

        if (this.item.minPrice !== undefined) {
          Text(this.getPriceText())
            .fontSize(this.isLarge ? 16 : 15)
            .fontColor('#E33B3B')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .height(this.isLarge ? 144 : 126)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
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
        minPrice: this.item.minPrice,
        maxPrice: this.item.maxPrice
      })
    })
  }

  private getPriceText(): string {
    if (this.item.minPrice === undefined) {
      return ''
    }
    if (this.item.maxPrice !== undefined) {
      return '￥' + this.item.minPrice + ' - ' + this.item.maxPrice
    }
    return '￥' + this.item.minPrice + ' 起'
  }
}

@Entry
@Component
export struct SearchResultPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: SearchResultNavParams = {}

  private vm: SearchResultViewModel = new SearchResultViewModel()
  private resultDataSource: PerformanceDataSource<SearchResultItemVO> = new PerformanceDataSource<SearchResultItemVO>()

  @State inputKeyword: string = ''
  @State resultList: SearchResultItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0
  @State breakPoint: string = 'sm'
  @State tabletResultWidth: number = 0
  @State isSearching: boolean = false
  @StorageLink('performance_changed_version') @Watch('onPerformanceDataChanged') performanceChangedVersion: number = 0
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.isPageVisible = true
    const params: SearchResultNavParams = this.navParams
    const keyword: string = params.keyword ?? ''
    const userId: string = params.userId ?? '1'

    if (keyword.trim().length === 0) {
      this.vm.errorMessage = '请输入搜索关键词'
      this.syncFromVm()
      return
    }

    if (this.vm.restoreCache(keyword, userId)) {
      this.syncFromVm(true)
    }
    this.initPage(keyword, userId)
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.isPageVisible = true
    if (this.pendingExternalRefresh) {
      this.pendingExternalRefresh = false
      setTimeout(() => {
        if (this.isPageVisible) {
          this.refreshCurrentSearch()
        }
      }, 700)
    }
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  private onPerformanceDataChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.refreshCurrentSearch()
  }

  private async refreshCurrentSearch(): Promise<void> {
    if (this.vm.keyword.length === 0) return
    await this.vm.refresh()
    this.syncFromVm()
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
            if (this.isTabletLayout()) {
              this.TabletResultGrid()
            } else {
              this.ResultList()
            }
          }
          .width('100%')
          .height('100%')
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

      Row() {
        TextInput({
          placeholder: '搜索演出、分类、城市、场馆',
          text: this.inputKeyword
        })
          .height(this.isTabletLayout() ? 44 : 36)
          .layoutWeight(1)
          .fontSize(this.isTabletLayout() ? 16 : 14)
          .backgroundColor('#FFFFFF')
          .padding({ left: 12, right: 6 })
          .onChange((value: string) => {
            this.inputKeyword = value
            this.vm.changeInputKeyword(value)
          })

        if (this.inputKeyword.trim().length > 0) {
          Text('×')
            .fontSize(18)
            .fontColor('#999999')
            .width(this.isTabletLayout() ? 34 : 28)
            .height(this.isTabletLayout() ? 44 : 36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.vm.clearInputKeyword()
              this.syncFromVm()
            })
        }
      }
      .height(this.isTabletLayout() ? 44 : 36)
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .margin({ left: 8, right: 8 })

      Text(this.isSearching ? '搜索中' : '搜索')
        .fontSize(14)
        .fontColor(this.inputKeyword.trim().length > 0 && !this.isSearching ? '#E33B3B' : '#CCCCCC')
        .enabled(this.inputKeyword.trim().length > 0 && !this.isSearching)
        .onClick(() => {
          this.searchAgain()
        })
    }
    .width('100%')
    .constraintSize({ maxWidth: ResponsiveLayout.READABLE_MAX_WIDTH })
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
  private ResultList() {
    List() {
      if (this.resultList.length === 0) {
        ListItem() {
          this.ResultEmptyArea()
        }
      } else {
        LazyForEach(this.resultDataSource, (item: SearchResultItemVO) => {
          ListItem() {
            SearchPerformanceCard({ item: item })
          }
        }, (item: SearchResultItemVO) => item.projectId + '_' + item.sessionId)

        ListItem() {
          this.LoadMoreArea()
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .cachedCount(4)
    .onReachEnd(() => {
      this.handleLoadMore()
    })
  }

  @Builder
  private TabletResultGrid() {
    Grid() {
      if (this.resultList.length === 0) {
        GridItem() {
          this.ResultEmptyArea()
        }
        .columnStart(0)
        .columnEnd(this.getTabletGridColumnCount() - 1)
      } else {
        LazyForEach(this.resultDataSource, (item: SearchResultItemVO) => {
          GridItem() {
            SearchPerformanceGridCard({ item: item, isLarge: this.getTabletGridColumnCount() >= 4 })
          }
        }, (item: SearchResultItemVO) => item.projectId + '_' + item.sessionId)

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
    .constraintSize({ maxWidth: ResponsiveLayout.COLLECTION_MAX_WIDTH })
    .layoutWeight(1)
    .padding({ left: this.getTabletGridColumnCount() >= 4 ? 28 : 20, right: this.getTabletGridColumnCount() >= 4 ? 28 : 20, bottom: 24 })
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
  private ResultEmptyArea() {
    Column({ space: 14 }) {
      if (this.isLoading || this.isSearching) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color('#E33B3B')
        Text('正在搜索相关演出...')
          .fontSize(14)
          .fontColor('#999999')
      } else {
        Text(this.errorMessage.length > 0 ? '网络开小差了，请重试搜索' : '没有搜索到近期相关的演出')
          .fontSize(14)
          .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
          .textAlign(TextAlign.Center)
        if (this.errorMessage.length > 0) {
          Button('重试')
            .height(38)
            .width(104)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#E33B3B')
            .enabled(!this.isSearching)
            .onClick(() => {
              this.searchAgain()
            })
        }
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 220 })
    .justifyContent(FlexAlign.Center)
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

  private async searchAgain(): Promise<void> {
    const keyword: string = this.inputKeyword.trim()

    if (this.isSearching) {
      return
    }
    if (keyword.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入搜索关键词' })
      return
    }

    this.isSearching = true
    this.vm.changeInputKeyword(keyword)
    try {
      await this.vm.searchAgain()
      this.syncFromVm()
      if (this.errorMessage.length > 0) {
        this.getUIContext().getPromptAction().showToast({ message: '搜索失败，请稍后重试' })
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: '搜索失败，请稍后重试' })
    } finally {
      this.isSearching = false
    }
  }

  private async initPage(keyword: string, userId: string): Promise<void> {
    this.isLoading = true
    await this.vm.initPage(keyword, userId)
    this.syncFromVm()
  }

  private async handleLoadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return
    }

    const previousCount: number = this.resultDataSource.totalCount()
    this.isLoading = true
    await this.vm.loadMore()
    this.syncFromVm(false)
    this.appendResultData(previousCount)
  }

  private appendResultData(previousCount: number): void {
    if (this.resultList.length < previousCount) {
      this.resultDataSource.setData(this.resultList)
      return
    }
    if (this.resultList.length > previousCount) {
      this.resultDataSource.appendData(this.resultList.slice(previousCount))
    }
  }

  private syncFromVm(reloadData: boolean = true): void {
    this.inputKeyword = this.vm.inputKeyword
    this.resultList = this.vm.resultList.slice()
    this.hasMore = this.vm.hasMore
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    if (reloadData) {
      this.resultDataSource.setData(this.resultList)
    }
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
