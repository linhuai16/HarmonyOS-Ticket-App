import {
  SearchPageVO,
  SearchHistoryItemVO
} from '../model/vo/performance/SearchPageVO'

import { SearchRepository } from '../repository/SearchRepository'

const MOCK_USER_ID: string = 'user_001'
const COLLAPSED_HISTORY_COUNT: number = 9
/**
    搜索历史
    关键词输入
    搜索跳转
 */
export class SearchViewModel {
  userId: string = MOCK_USER_ID
  keyword: string = ''
  histories: SearchHistoryItemVO[] = []

  isLoading: boolean = false
  errorMessage: string = ''

  private searchRepository: SearchRepository = new SearchRepository()

  isHistoryExpanded: boolean = false


  initSearchPage(userId: string = MOCK_USER_ID): void {
    this.userId = userId
    this.loadSearchHistory()
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

  loadSearchHistory(): void {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    const pageVO: SearchPageVO = this.searchRepository.getSearchPage(this.userId)

    this.histories = pageVO.histories
    if (!this.hasMoreHistories()) {
      this.isHistoryExpanded = false
    }
    this.isLoading = false
  }

  changeKeyword(keyword: string): void {
    this.keyword = keyword
  }

  search(): string {
    const realKeyword: string = this.keyword.trim()

    if (realKeyword.length === 0) {
      this.errorMessage = '请输入搜索关键词'
      return ''
    }

    this.searchRepository.saveSearchHistory(realKeyword, this.userId)
    this.keyword = realKeyword
    this.loadSearchHistory()

    return realKeyword
  }

  searchByHistory(keyword: string): string {
    const realKeyword: string = keyword.trim()

    if (realKeyword.length === 0) {
      return ''
    }

    this.keyword = realKeyword
    this.searchRepository.saveSearchHistory(realKeyword, this.userId)
    this.loadSearchHistory()

    return realKeyword
  }

  deleteHistory(historyId: string): void {
    if (historyId.length === 0) {
      return
    }

    this.searchRepository.deleteSearchHistory(historyId)
    this.loadSearchHistory()
  }

  clearHistory(): void {
    this.searchRepository.clearSearchHistory(this.userId)
    this.isHistoryExpanded = false
    this.loadSearchHistory()
  }

  clearKeyword(): void {
    this.keyword = ''
  }

  clearError(): void {
    this.errorMessage = ''
  }
}