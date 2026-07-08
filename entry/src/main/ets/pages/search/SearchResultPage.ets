import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { SearchResultItemVO } from '../../model/vo/performance/SearchPageVO'
import { SearchResultViewModel } from '../../viewmodel/SearchResultViewModel'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface SearchResultRouteParams {
  keyword?: string
  userId?: string
}


@Entry
@Component
struct SearchResultPage {
  private vm: SearchResultViewModel = new SearchResultViewModel()

  @State inputKeyword: string = ''
  @State resultList: SearchResultItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    const params = router.getParams() as SearchResultRouteParams
    const keyword: string = params.keyword ?? ''
    const userId: string = params.userId ?? 'user_001'

    if (keyword.trim().length === 0) {
      this.vm.errorMessage = '请输入搜索关键词'
      this.syncFromVm()
      return
    }

    this.vm.initPage(keyword, userId)
    this.syncFromVm()
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    // 页面交互文档要求来源页返回时刷新。城市入口已从搜索结果页移除，
    // 但如果全局城市在别处变化，仍按当前关键词重新加载搜索结果。
    this.vm.reloadIfCityChanged()
    this.syncFromVm()
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.ResultList()
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

      Row() {
        TextInput({
          placeholder: '搜索演出、分类、城市、场馆',
          text: this.inputKeyword
        })
          .height(36)
          .layoutWeight(1)
          .fontSize(14)
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
            .width(28)
            .height(36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.vm.clearInputKeyword()
              this.syncFromVm()
            })
        }
      }
      .height(36)
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .margin({ left: 8, right: 8 })

      Text('搜索')
        .fontSize(14)
        .fontColor(this.inputKeyword.trim().length > 0 ? '#E33B3B' : '#CCCCCC')
        .onClick(() => {
          this.searchAgain()
        })
    }
    .width('100%')
    .height(54)
    .padding({ left: 12, right: 12, top: 9, bottom: 9 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private ResultList() {
    List() {
      if (this.resultList.length === 0) {
        ListItem() {
          Text(this.errorMessage.length > 0 ? this.errorMessage : '没有搜索到近期相关的演出')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 80 })
        }
      } else {
        ForEach(this.resultList, (item: SearchResultItemVO) => {
          ListItem() {
            this.ResultCard(item)
          }
        }, (item: SearchResultItemVO) => item.projectId + item.sessionId)

        ListItem() {
          this.LoadMoreArea()
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private ResultCard(item: SearchResultItemVO) {
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
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(item.startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })
          .width('100%')

        Text(item.cityName + ' | ' + item.venueName)
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')

        Row() {
          Blank()
          Text(this.getPriceText(item))
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
      const params: Record<string, string> = this.vm.buildDetailJumpParams(item)
      router.pushUrl({
        url: 'pages/performance/PerformanceDetailPage',
        params: params
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
            this.vm.loadMore()
            this.syncFromVm()
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

  private searchAgain(): void {
    const keyword: string = this.inputKeyword.trim()

    if (keyword.length === 0) {
      promptAction.showToast({ message: '请输入搜索关键词' })
      return
    }

    this.vm.changeInputKeyword(keyword)
    this.vm.searchAgain()
    this.syncFromVm()

    if (this.errorMessage.length > 0) {
      promptAction.showToast({ message: this.errorMessage })
    }
  }

  private getPriceText(item: SearchResultItemVO): string {
    if (item.minPrice === undefined) {
      return ''
    }

    if (item.maxPrice !== undefined) {
      return '￥' + item.minPrice + ' - ' + item.maxPrice
    }

    return '￥' + item.minPrice + ' 起'
  }

  private syncFromVm(): void {
    this.inputKeyword = this.vm.inputKeyword
    this.resultList = this.vm.resultList
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
