import { AppNavigator } from '../navigation/AppNavigation'
import { SearchHistoryItemVO } from '../model/vo/performance/SearchPageVO'
import { SearchViewModel } from '../viewmodel/SearchViewModel'

export interface TabletSearchPopupState {
  isVisible: boolean
}

@Component
export struct TabletSearchPanel {
  @Consume('appNavStack') navStack: NavPathStack
  private vm: SearchViewModel = new SearchViewModel()

  @Prop panelWidth: number = 480
  @Prop recommendedKeywords: string[] = []
  @State keyword: string = ''
  @State histories: SearchHistoryItemVO[] = []
  @State isLoading: boolean = false
  @State isSearching: boolean = false

  onClose: () => void = (): void => {}

  aboutToAppear(): void {
    this.initPanel()
  }

  build() {
    Column() {
      Row() {
        TextInput({
          placeholder: '搜索演出、艺人、场馆',
          text: this.keyword
        })
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .padding({ left: 14, right: 8 })
          .onChange((value: string) => {
            this.keyword = value
            this.vm.changeKeyword(value)
          })

        if (this.keyword.trim().length > 0) {
          Text('×')
            .width(36)
            .height(44)
            .fontSize(20)
            .fontColor('#888888')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.vm.clearKeyword()
              this.keyword = ''
            })
        }

        Text(this.isSearching ? '搜索中' : '搜索')
          .width(64)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.keyword.trim().length > 0 && !this.isSearching ? '#E33B3B' : '#BBBBBB')
          .textAlign(TextAlign.Center)
          .enabled(this.keyword.trim().length > 0 && !this.isSearching)
          .onClick(() => {
            this.searchCurrentKeyword()
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor('#F5F5F5')
      .borderRadius(22)

      Scroll() {
        Column() {
          this.RecentSearchArea()
          this.RecommendSearchArea()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width(this.panelWidth)
    .height(360)
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .shadow({ radius: 24, color: '#26000000', offsetY: 8 })
  }

  @Builder
  private RecentSearchArea() {
    Column() {
      Row() {
        Text('最近搜索')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Blank()

        if (this.histories.length > 0) {
          Text('清空')
            .height(40)
            .padding({ left: 12, right: 4 })
            .fontSize(14)
            .fontColor('#888888')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.clearHistory()
            })
        }
      }
      .width('100%')
      .height(48)

      if (this.isLoading) {
        Text('正在加载搜索记录...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 12 })
      } else if (this.histories.length === 0) {
        Text('暂无搜索记录')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 12 })
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.histories, (item: SearchHistoryItemVO) => {
            this.KeywordTag(item.keyword)
          }, (item: SearchHistoryItemVO) => item.historyId)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private RecommendSearchArea() {
    if (this.recommendedKeywords.length > 0) {
      Column() {
        Text('推荐搜索')
          .width('100%')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .margin({ top: 12, bottom: 12 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.recommendedKeywords, (keyword: string) => {
            this.KeywordTag(keyword)
          }, (keyword: string) => keyword)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  private KeywordTag(keyword: string) {
    Row() {
      Text(keyword)
        .fontSize(14)
        .fontColor('#444444')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(36)
    .padding({ left: 14, right: 14 })
    .margin({ right: 10, bottom: 10 })
    .backgroundColor('#F3F3F3')
    .borderRadius(18)
    .onClick(() => {
      this.searchKeyword(keyword)
    })
  }

  private async initPanel(): Promise<void> {
    this.isLoading = true
    await this.vm.initSearchPage()
    this.syncFromVm()
  }

  private async searchCurrentKeyword(): Promise<void> {
    if (this.isSearching || this.keyword.trim().length === 0) {
      return
    }
    this.isSearching = true
    this.vm.changeKeyword(this.keyword)
    try {
      const result: string = await this.vm.search()
      this.syncFromVm()
      if (result.length === 0) {
        this.getUIContext().getPromptAction().showToast({
          message: this.vm.errorMessage.length > 0 ? this.vm.errorMessage : '请输入搜索关键词'
        })
        return
      }
      this.openSearchResult(result)
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: '搜索失败，请稍后重试'
      })
    } finally {
      this.isSearching = false
    }
  }

  private async searchKeyword(keyword: string): Promise<void> {
    if (this.isSearching) {
      return
    }
    this.isSearching = true
    try {
      const result: string = await this.vm.searchByHistory(keyword)
      this.syncFromVm()
      this.openSearchResult(result)
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: '搜索失败，请稍后重试' })
    } finally {
      this.isSearching = false
    }
  }

  private async clearHistory(): Promise<void> {
    await this.vm.clearHistory()
    this.syncFromVm()
  }

  private openSearchResult(keyword: string): void {
    const realKeyword: string = keyword.trim()
    if (realKeyword.length === 0) {
      return
    }
    this.onClose()
    AppNavigator.openSearchResult(this.navStack, {
      keyword: realKeyword,
      userId: this.vm.userId
    })
  }

  private syncFromVm(): void {
    this.keyword = this.vm.keyword
    this.histories = this.vm.getVisibleHistories()
    this.isLoading = this.vm.isLoading
  }
}
