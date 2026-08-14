import {
  SearchResultItemVO,
  SearchResultPageVO
} from '../model/vo/performance/SearchPageVO'

import { PerformanceRepository } from '../repository/PerformanceRepository'
import { SearchRepository } from '../repository/SearchRepository'

const SEARCH_PAGE_SIZE: number = 10
const DEFAULT_USER_ID: string = '1'

/**
 * 搜索结果页 ViewModel。
 */
export class SearchResultViewModel {
  userId: string = DEFAULT_USER_ID

  keyword: string = ''
  inputKeyword: string = ''

  resultList: SearchResultItemVO[] = []
  hasMore: boolean = false

  isLoading: boolean = false
  isRefreshing: boolean = false
  errorMessage: string = ''

  private offset: number = 0
  private pageSize: number = SEARCH_PAGE_SIZE

  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private searchRepository: SearchRepository = new SearchRepository()

  async initPage(keyword: string, userId: string = DEFAULT_USER_ID): Promise<void> {
    this.userId = userId
    this.keyword = keyword.trim()
    this.inputKeyword = this.keyword
    this.offset = 0
    await this.loadResultList()
  }

  changeInputKeyword(keyword: string): void {
    this.inputKeyword = keyword
    this.errorMessage = ''
  }

  clearInputKeyword(): void {
    this.inputKeyword = ''
    this.errorMessage = ''
  }

  canSearch(): boolean {
    return this.inputKeyword.trim().length > 0
  }

  async searchAgain(): Promise<void> {
    const realKeyword: string = this.inputKeyword.trim()

    if (realKeyword.length === 0) {
      this.errorMessage = '请输入搜索关键词'
      return
    }

    await this.searchRepository.saveSearchHistory(realKeyword, this.userId)

    this.keyword = realKeyword
    this.inputKeyword = realKeyword
    this.offset = 0
    await this.loadResultList()
  }

  async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.offset = 0
    await this.loadResultList()
    this.isRefreshing = false
  }

  async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMore) {
      return
    }

    await this.loadMoreResultList()
  }

  buildDetailJumpParams(item: SearchResultItemVO): Record<string, string> {
    return {
      'projectId': item.projectId,
      'sessionId': item.sessionId
    }
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private async loadResultList(): Promise<void> {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    try {
      const pageVO: SearchResultPageVO = await this.performanceRepository.searchPerformances(
        this.keyword,
        this.pageSize,
        this.offset
      )

      this.resultList = pageVO.resultList
      this.hasMore = pageVO.hasMore
      this.offset = this.resultList.length
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '搜索结果加载失败'
    } finally {
      this.isLoading = false
    }
  }

  private async loadMoreResultList(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    try {
      const pageVO: SearchResultPageVO = await this.performanceRepository.searchPerformances(
        this.keyword,
        this.pageSize,
        this.offset
      )

      this.resultList = this.resultList.concat(pageVO.resultList)
      this.hasMore = pageVO.hasMore
      this.offset = this.resultList.length
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载更多失败'
    } finally {
      this.isLoading = false
    }
  }
}
