import {
  SearchPageVO,
  SearchHistoryItemVO
} from '../model/vo/performance/SearchPageVO'

import { SearchRepository } from '../repository/SearchRepository'

const DEFAULT_USER_ID: string = '1'
const COLLAPSED_HISTORY_COUNT: number = 9

/**
 * 搜索页 ViewModel。
 */
export class SearchViewModel {
  userId: string = DEFAULT_USER_ID
  keyword: string = ''
  histories: SearchHistoryItemVO[] = []

  isLoading: boolean = false
  errorMessage: string = ''

  private searchRepository: SearchRepository = new SearchRepository()

  isHistoryExpanded: boolean = false

  async initSearchPage(userId: string = DEFAULT_USER_ID): Promise<void> {
    this.userId = userId
    await this.loadSearchHistory()
  }

  canSearch(): boolean {
    return this.keyword.trim().length > 0
  }

  getVisibleHistories(): SearchHistoryItemVO[] {
    if (this.isHistoryExpanded) {
      return this.histories
    }

    return this.histories.slice(0, COLLAPSED_HISTORY_COUNT)
  }

  hasMoreHistories(): boolean {
    return this.histories.length > COLLAPSED_HISTORY_COUNT
  }

  toggleHistoryExpanded(): void {
    if (!this.hasMoreHistories()) {
      this.isHistoryExpanded = false
      return
    }

    this.isHistoryExpanded = !this.isHistoryExpanded
  }

  async loadSearchHistory(): Promise<void> {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    try {
      const pageVO: SearchPageVO = await this.searchRepository.getSearchPage(this.userId)
      this.histories = pageVO.histories
      if (!this.hasMoreHistories()) {
        this.isHistoryExpanded = false
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '搜索历史加载失败'
    } finally {
      this.isLoading = false
    }
  }

  changeKeyword(keyword: string): void {
    this.keyword = keyword
  }

  async search(): Promise<string> {
    const realKeyword: string = this.keyword.trim()

    if (realKeyword.length === 0) {
      this.errorMessage = '请输入搜索关键词'
      return ''
    }

    await this.searchRepository.saveSearchHistory(realKeyword, this.userId)
    this.keyword = realKeyword
    await this.loadSearchHistory()

    return realKeyword
  }

  async searchByHistory(keyword: string): Promise<string> {
    const realKeyword: string = keyword.trim()

    if (realKeyword.length === 0) {
      return ''
    }

    this.keyword = realKeyword
    await this.searchRepository.saveSearchHistory(realKeyword, this.userId)
    await this.loadSearchHistory()

    return realKeyword
  }

  async deleteHistory(historyId: string): Promise<void> {
    if (historyId.length === 0) {
      return
    }

    await this.searchRepository.deleteSearchHistory(historyId, this.userId)
    await this.loadSearchHistory()
  }

  async clearHistory(): Promise<void> {
    await this.searchRepository.clearSearchHistory(this.userId)
    this.isHistoryExpanded = false
    await this.loadSearchHistory()
  }

  clearKeyword(): void {
    this.keyword = ''
  }

  clearError(): void {
    this.errorMessage = ''
  }
}
