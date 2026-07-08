import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { SearchHistoryItemVO } from '../../model/vo/performance/SearchPageVO'
import { SearchViewModel } from '../../viewmodel/SearchViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

@Entry
@Component
export struct SearchPage {
  private vm: SearchViewModel = new SearchViewModel()

  @State keyword: string = ''
  @State histories: SearchHistoryItemVO[] = []
  @State isHistoryExpanded: boolean = false
  @State hasMoreHistory: boolean = false
  @State pageVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.vm.initSearchPage()
    this.syncFromVm()
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    // 从搜索结果页返回时，重新读取搜索历史，保证历史排行按照最近搜索时间刷新。
    this.vm.loadSearchHistory()
    this.syncFromVm()
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.SearchTopBar()
      this.HistoryArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private SearchTopBar() {
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
          text: this.keyword
        })
          .height(36)
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor('#FFFFFF')
          .padding({ left: 12, right: 6 })
          .onChange((value: string) => {
            this.keyword = value
            this.vm.changeKeyword(value)
          })

        if (this.keyword.trim().length > 0) {
          Text('×')
            .fontSize(18)
            .fontColor('#999999')
            .width(28)
            .height(36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.vm.clearKeyword()
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
        .fontSize(15)
        .fontColor(this.keyword.trim().length > 0 ? '#E33B3B' : '#CCCCCC')
        .onClick(() => {
          this.doSearch()
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private HistoryArea() {
    Column() {
      Row() {
        Text('历史记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Blank()

        if (this.histories.length > 0) {
          Text('清空')
            .fontSize(13)
            .fontColor('#999999')
            .onClick(() => {
              this.vm.clearHistory()
              this.syncFromVm()
            })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.histories.length === 0) {
        Text('暂无搜索历史')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 40 })
      } else {
        Column() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.histories, (item: SearchHistoryItemVO) => {
              this.HistoryKeywordItem(item)
            }, (item: SearchHistoryItemVO) => item.historyId)
          }
          .width('100%')

          if (this.hasMoreHistory) {
            this.HistoryExpandToggle()
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .layoutWeight(1)
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private HistoryKeywordItem(item: SearchHistoryItemVO) {
    Row() {
      Text(item.keyword)
        .fontSize(13)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .onClick(() => {
          this.searchByHistory(item.keyword)
        })

      Text('×')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ left: 4 })
        .onClick(() => {
          this.vm.deleteHistory(item.historyId)
          this.syncFromVm()
        })
    }
    .width('30%')
    .height(30)
    .padding({ left: 8, right: 8 })
    .margin({ right: 8, bottom: 8 })
    .backgroundColor('#EEEEEE')
    .borderRadius(15)
  }

  @Builder
  private HistoryExpandToggle() {
    Row() {
      Image(this.getHistoryToggleIcon())
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 2, bottom: 6 })
    .onClick(() => {
      this.vm.toggleHistoryExpanded()
      this.syncFromVm()
    })
  }

  private getHistoryToggleIcon(): Resource {
    if (this.isHistoryExpanded) {
      return $r('app.media.shangla')
    }

    return $r('app.media.xiala')
  }

  private searchByHistory(keyword: string): void {
    const result: string = this.vm.searchByHistory(keyword)
    this.syncFromVm()
    this.jumpToSearchResult(result)
  }

  private doSearch(): void {
    this.vm.changeKeyword(this.keyword)
    const result: string = this.vm.search()
    this.syncFromVm()

    if (result.length === 0) {
      promptAction.showToast({
        message: this.vm.errorMessage.length > 0 ? this.vm.errorMessage : '请输入搜索关键词'
      })
      return
    }

    this.jumpToSearchResult(result)
  }

  private jumpToSearchResult(keyword: string): void {
    if (keyword.trim().length === 0) {
      return
    }

    router.pushUrl({
      url: 'pages/search/SearchResultPage',
      params: {
        keyword: keyword.trim(),
        userId: this.vm.userId
      }
    })
  }

  private syncFromVm(): void {
    this.keyword = this.vm.keyword
    this.histories = this.vm.getVisibleHistories()
    this.isHistoryExpanded = this.vm.isHistoryExpanded
    this.hasMoreHistory = this.vm.hasMoreHistories()
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
