import router from '@ohos.router'

import {
  HomeCategoryVO,
  HomeBannerVO,
  HomeRecommendItemVO
} from '../../model/vo/home/HomePageVO'

import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

@Entry
@Component
export struct HomePage {
  private vm: HomeViewModel = new HomeViewModel()

  @State pageVersion: number = 0
  @State isPullRefreshing: boolean = false
  @State currentCityName: string = '北京'
  @State categories: HomeCategoryVO[] = []
  @State banners: HomeBannerVO[] = []
  @State recommendList: HomeRecommendItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @StorageLink('current_city') @Watch('onStorageCityChanged') storageCityName: string = '北京'
  @StorageLink('performance_changed_version') @Watch('onPerformanceDataChanged') performanceChangedVersion: number = 0
  private lastVisibleRefreshTime: number = 0
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
    this.isPageVisible = true
    this.loadHomePage()
  }

  /**
   * 首页作为 Index 的 TabContent 使用时，页面级 onPageShow 不一定会落到 HomePage。
   * 因此同时监听 AppStorage 中的 current_city，城市选择页保存城市后这里直接刷新首页数据。
   */
  onStorageCityChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.refreshHomePage()
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
    this.pendingExternalRefresh = false
    this.refreshHomePage()
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.ErrorBanner()

      Refresh({ refreshing: $$this.isPullRefreshing }) {
        Scroll() {
          Column() {
            this.CategoryGrid()
            this.BannerSwiper()
            this.RecommendTitle()
            this.RecommendGrid()
            this.LoadMoreArea()
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .layoutWeight(1)
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
      if (!isVisible || currentRatio <= 0) return
      const now: number = Date.now()
      if (now - this.lastVisibleRefreshTime < 1500) return
      this.lastVisibleRefreshTime = now
      this.refreshHomePage()
    })
  }

  @Builder
  private TopBar() {
    Row() {
      Row() {
        Text(this.currentCityName.length > 0 ? this.currentCityName : '北京')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('⌄')
          .fontSize(14)
          .fontColor('#222222')
          .margin({ left: 2 })
      }
      .height(36)
      .padding({ left: 2, right: 4 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/city/CitySelectPage'
        })
      })

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
        router.pushUrl({
          url: 'pages/search/SearchPage'
        })
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private ErrorBanner() {
    if (this.errorMessage.length > 0) {
      Row() {
        Text('接口加载失败：' + this.errorMessage)
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
    Grid() {
      ForEach(this.categories, (item: HomeCategoryVO) => {
        GridItem() {
          Column() {
            Image(MediaResourceUtil.getMedia(item.iconUrl))
              .width(40)
              .height(40)
              .objectFit(ImageFit.Contain)

            Text(item.categoryName)
              .fontSize(13)
              .fontColor('#333333')
              .margin({ top: 6 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/performance/CategoryPage',
              params: {
                categoryId: item.categoryId
              }
            })
          })
        }
      }, (item: HomeCategoryVO) => item.categoryId + '_' + String(this.pageVersion))
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

  @Builder
  private BannerSwiper() {
    if (this.banners.length > 0) {
      Swiper() {
        ForEach(this.banners, (item: HomeBannerVO) => {
          Image(MediaResourceUtil.getMedia(item.imageUrl))
            .width('100%')
            .height(130)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/performance/PerformanceDetailPage',
                params: {
                  projectId: item.projectId
                }
              })
            })
        }, (item: HomeBannerVO) => item.bannerId + '_' + String(this.pageVersion))
      }
      .autoPlay(this.banners.length > 1)
      .interval(3000)
      .indicator(this.banners.length > 1)
      .height(130)
      .margin({ top: 12 })
    }
  }

  @Builder
  private RecommendTitle() {
    Row() {
      Text('推荐')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
    }
    .width('100%')
    .margin({ top: 16, bottom: 8 })
  }

  @Builder
  private RecommendGrid() {
    Grid() {
      ForEach(this.recommendList, (item: HomeRecommendItemVO) => {
        GridItem() {
          Column() {
            Image(MediaResourceUtil.getMedia(item.posterUrl))
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Cover)
              .borderRadius({ topLeft: 10, topRight: 10 })

            Column() {
              Text(item.categoryName)
                .fontSize(11)
                .fontColor('#E33B3B')

              Text(item.title)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#222222')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })

              Text((item.cityName.length > 0 ? item.cityName + ' · ' : '') + item.startTime)
                .fontSize(12)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 6 })

              if (item.minPrice !== undefined) {
                Text('￥' + item.minPrice + ' 起')
                  .fontSize(14)
                  .fontColor('#E33B3B')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 6 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(8)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
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
      }, (item: HomeRecommendItemVO) => item.projectId + '_' + item.sessionId + '_' + String(item.minPrice) + '_' + String(this.pageVersion))
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
  }

  @Builder
  private LoadMoreArea() {
    Column() {
      if (this.hasMore) {
        Text(this.isLoading ? '加载中...' : '上拉加载更多')
          .fontSize(13)
          .fontColor('#999999')
          .onClick(() => {
            this.handleLoadMore()
          })
      } else {
        Text('已经到底了')
          .fontSize(13)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(16)
  }

  private async handleRefreshHome(): Promise<void> {
    this.isPullRefreshing = true
    await this.vm.refreshHome()
    this.syncFromVm()
    this.isPullRefreshing = false
  }

  private async handleLoadMore(): Promise<void> {
    if (!this.hasMore || this.isLoading) {
      return
    }

    await this.vm.loadMore()
    this.syncFromVm()
  }

  private async loadHomePage(): Promise<void> {
    await this.vm.loadHome()
    this.syncFromVm()
  }

  private async refreshHomePage(): Promise<void> {
    await this.vm.refreshHome()
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.currentCityName = this.vm.currentCityName
    this.categories = this.vm.categories.slice()
    this.banners = this.vm.banners.slice()
    this.recommendList = this.vm.recommendList.slice()
    this.hasMore = this.vm.hasMore
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
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
