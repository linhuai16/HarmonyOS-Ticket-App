import router from '@ohos.router'

import {
  CategoryPerformanceItemVO,
  PerformanceSortType
} from '../../model/vo/performance/CategoryPageVO'

import { CategoryViewModel } from '../../viewmodel/CategoryViewModel'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface CategoryRouteParams {
  categoryId?: string
}

interface CategoryTabItem {
  categoryId?: string
  categoryName: string
}


@Entry
@Component
export struct CategoryPage {
  private vm: CategoryViewModel = new CategoryViewModel()

  @State pageVersion: number = 0
  @State currentCityName: string = '北京'
  @State selectedCategoryId: string = ''
  @State selectedSortType: PerformanceSortType = PerformanceSortType.HOT
  @State selectedFilterTime: string = ''
  @State performanceList: CategoryPerformanceItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State isRefreshing: boolean = false

  @StorageLink('current_city')
  @Watch('onStorageCityChanged')
  storageCityName: string = '北京'

  private categoryTabs: CategoryTabItem[] = [
    { categoryId: undefined, categoryName: '全部' },
    { categoryId: 'cat_concert', categoryName: '演唱会' },
    { categoryId: 'cat_drama', categoryName: '话剧' },
    { categoryId: 'cat_music_festival', categoryName: '音乐节' },
    { categoryId: 'cat_talkshow', categoryName: '脱口秀' },
    { categoryId: 'cat_immersive', categoryName: '沉浸剧场' },
    { categoryId: 'cat_crosstalk', categoryName: '相声' },
    { categoryId: 'cat_opera', categoryName: '戏曲艺术' },
    { categoryId: 'cat_dance', categoryName: '舞蹈舞剧' }
  ]

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    const params = router.getParams() as CategoryRouteParams
    this.vm.initCategoryPage(params.categoryId)
    this.syncFromVm()
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.vm.reloadIfCityChanged()
    this.syncFromVm()
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
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
        router.back()
      })

      Text(this.currentCityName.length > 0 ? this.currentCityName : this.storageCityName)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4, right: 12 })
        .height(36)
        .onClick(() => {
          router.pushUrl({ url: 'pages/city/CitySelectPage' })
        })

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
        router.pushUrl({ url: 'pages/search/SearchPage' })
      })
    }
    .width('100%')
    .height(54)
    .padding({ left: 12, right: 12, top: 9, bottom: 9 })
    .backgroundColor('#F5F5F5')
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
            this.vm.changeCategory(item.categoryId)
            this.syncFromVm()
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
        this.vm.changeSort(PerformanceSortType.HOT)
        this.syncFromVm()
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
        this.vm.changeSort(PerformanceSortType.NEW)
        this.syncFromVm()
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
            Text('暂无演出')
              .fontSize(15)
              .fontColor('#999999')
              .textAlign(TextAlign.Center)

            Text('当前城市：' + this.currentCityName)
              .fontSize(12)
              .fontColor('#BBBBBB')
              .margin({ top: 8 })
          }
          .width('100%')
          .margin({ top: 80 })
          .alignItems(HorizontalAlign.Center)
        }
      } else {
        ForEach(this.performanceList, (item: CategoryPerformanceItemVO) => {
          ListItem() {
            this.PerformanceCard(item)
          }
        }, (item: CategoryPerformanceItemVO) => item.projectId + '_' + item.sessionId)

        ListItem() {
          this.LoadMoreArea()
        }
      }
    }
    .width('100%')
    .height('100%')
    .onReachEnd(() => {
      this.handleLoadMore()
    })
  }

  @Builder
  private PerformanceCard(item: CategoryPerformanceItemVO) {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia(item.posterUrl))
          .width(92)
          .height(124)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)

        Text(item.categoryName)
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .backgroundColor('#E33B3B')
          .borderRadius({ topLeft: 8, bottomRight: 8 })
      }

      Column() {
        Column() {
          Text(item.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(item.startTime)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 8 })
            .width('100%')

          Text(item.cityName + ' | ' + item.venueName)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .width('100%')

          Text(this.getSessionStatusText(item.sessionStatus))
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row() {
          Blank()
          if (item.minPrice !== undefined) {
            Text('￥' + item.minPrice + ' 起')
              .fontSize(14)
              .fontColor('#E33B3B')
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
      }
      .height(124)
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
      router.pushUrl({
        url: 'pages/performance/PerformanceDetailPage',
        params: {
          projectId: item.projectId,
          sessionId: item.sessionId
        }
      })
    })
  }

  @Builder
  private LoadMoreArea() {
    Column() {
      if (this.hasMore) {
        Text(this.isLoading ? '加载中...' : '加载更多')
          .fontSize(13)
          .fontColor('#999999')
          .padding(16)
          .onClick(() => {
            this.handleLoadMore()
          })
      } else {
        Text('已经到底了')
          .fontSize(13)
          .fontColor('#999999')
          .padding(16)
      }
    }
    .width('100%')
  }

  private handleRefresh(): void {
    this.isRefreshing = true
    this.vm.refresh()
    this.syncFromVm()
    this.isRefreshing = false
  }

  private handleLoadMore(): void {
    if (!this.hasMore || this.isLoading) {
      return
    }

    this.vm.loadMore()
    this.syncFromVm()
  }

  private onStorageCityChanged(): void {
    const cityName: string = this.storageCityName.trim()

    if (cityName.length === 0 || cityName === this.currentCityName) {
      return
    }

    this.vm.changeCity(cityName)
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.currentCityName = this.vm.currentCityName
    this.selectedCategoryId = this.vm.categoryId ?? ''
    this.selectedSortType = this.vm.sortType
    this.selectedFilterTime = this.vm.filterTime ?? ''
    this.performanceList = this.vm.categoryList.slice()
    this.hasMore = this.vm.hasMore
    this.isLoading = this.vm.isLoading
    this.pageVersion++
  }

  private isCategorySelected(categoryId: string | undefined): boolean {
    return this.selectedCategoryId === (categoryId ?? '')
  }

  private toggleFilterTime(): void {
    if (this.selectedFilterTime.length === 0) {
      this.vm.changeFilterTime('NEXT_30_DAYS')
    } else {
      this.vm.clearFilterTime()
    }
    this.syncFromVm()
  }

  private getFilterTimeText(): string {
    if (this.selectedFilterTime === 'NEXT_30_DAYS') {
      return '近一月  ×'
    }
    return '时间筛选'
  }

  private getSessionStatusText(status: SessionStatus): string {
    if (status === SessionStatus.PRESALE) return '预售中'
    if (status === SessionStatus.ON_SALE) return '售卖中'
    if (status === SessionStatus.SOLD_OUT) return '已售罄'
    if (status === SessionStatus.ENDED) return '已结束'
    return ''
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
}
