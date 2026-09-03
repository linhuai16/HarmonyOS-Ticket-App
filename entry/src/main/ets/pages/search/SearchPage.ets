import { AppNavigator, SearchNavParams } from '../../navigation/AppNavigation'

import { SearchHistoryItemVO } from '../../model/vo/performance/SearchPageVO'
import { SearchViewModel } from '../../viewmodel/SearchViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
@Entry
@Component
export struct SearchPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: SearchNavParams = {}

  private vm: SearchViewModel = new SearchViewModel()

  @State keyword: string = ''
  @State histories: SearchHistoryItemVO[] = []
  @State isHistoryExpanded: boolean = false
  @State hasMoreHistory: boolean = false
  @State pageVersion: number = 0
  @State breakPoint: string = 'sm'
  @State isSearching: boolean = false
  private hasShownOnce: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    this.initSearchPage()
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#F5F5F5')
    if (!this.hasShownOnce) {
      this.hasShownOnce = true
      return
    }
    this.reloadSearchHistory()
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
            Column() {
              this.RefreshMarker()
              this.SearchTopBar()
              this.HistoryArea()
            }
            .width('100%')
            .constraintSize({ maxWidth: ResponsiveLayout.READABLE_MAX_WIDTH })
            .height('100%')
            .alignItems(HorizontalAlign.Center)
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
          this.navStack.pop()
        })

      Row() {
        TextInput({
          placeholder: '搜索演出、分类、城市、场馆',
          text: this.keyword
        })
          .height(this.isTabletLayout() ? 44 : 36)
          .layoutWeight(1)
          .fontSize(this.isTabletLayout() ? 16 : 14)
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
            .width(this.isTabletLayout() ? 34 : 28)
            .height(this.isTabletLayout() ? 44 : 36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.vm.clearKeyword()
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
        .fontSize(this.isTabletLayout() ? 17 : 15)
        .fontColor(this.keyword.trim().length > 0 && !this.isSearching ? '#E33B3B' : '#CCCCCC')
        .width(this.isTabletLayout() ? 52 : 44)
        .height(this.isTabletLayout() ? 44 : 36)
        .textAlign(TextAlign.Center)
        .enabled(this.keyword.trim().length > 0 && !this.isSearching)
        .onClick(() => {
          this.doSearch()
        })
    }
    .width('100%')
    .constraintSize({ maxWidth: ResponsiveLayout.READABLE_MAX_WIDTH })
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private HistoryArea() {
    Column() {
      Row() {
        Text('历史记录')
          .fontSize(this.isTabletLayout() ? 19 : 16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Blank()

        if (this.histories.length > 0) {
          Text('清空')
            .fontSize(13)
            .fontColor('#999999')
            .height(36)
            .padding({ left: 10, right: 4 })
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.clearHistory()
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
    .borderRadius(this.isTabletLayout() ? 16 : 0)
    .margin({ top: this.isTabletLayout() ? 12 : 0 })
  }

  @Builder
  private HistoryKeywordItem(item: SearchHistoryItemVO) {
    Row() {
      Text(item.keyword)
        .fontSize(this.isTabletLayout() ? 15 : 13)
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
        .width(this.isTabletLayout() ? 30 : 24)
        .height(this.isTabletLayout() ? 38 : 30)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.deleteHistory(item.historyId)
        })
    }
    .width(this.isTabletLayout() ? '23%' : '30%')
    .height(this.isTabletLayout() ? 38 : 30)
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

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private getHistoryToggleIcon(): Resource {
    if (this.isHistoryExpanded) {
      return $r('app.media.shangla')
    }

    return $r('app.media.xiala')
  }

  private async searchByHistory(keyword: string): Promise<void> {
    if (this.isSearching) {
      return
    }
    this.isSearching = true
    try {
      const result: string = await this.vm.searchByHistory(keyword)
      this.syncFromVm()
      this.jumpToSearchResult(result)
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: '搜索失败，请稍后重试' })
    } finally {
      this.isSearching = false
    }
  }

  private async doSearch(): Promise<void> {
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
      this.jumpToSearchResult(result)
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: '搜索失败，请稍后重试'
      })
    } finally {
      this.isSearching = false
    }
  }

  private jumpToSearchResult(keyword: string): void {
    if (keyword.trim().length === 0) {
      return
    }

    AppNavigator.openSearchResult(this.navStack, {
      keyword: keyword.trim(),
      userId: this.vm.userId
    })
  }

  private async initSearchPage(): Promise<void> {
    await this.vm.initSearchPage()
    this.syncFromVm()
  }

  private async reloadSearchHistory(): Promise<void> {
    await this.vm.loadSearchHistory()
    this.syncFromVm()
  }

  private async clearHistory(): Promise<void> {
    await this.vm.clearHistory()
    this.syncFromVm()
  }

  private async deleteHistory(historyId: string): Promise<void> {
    await this.vm.deleteHistory(historyId)
    this.syncFromVm()
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
