import { SearchResultItemVO, SearchResultPageVO } from '../model/vo/performance/SearchPageVO'
import { PerformanceRepository } from '../repository/PerformanceRepository'
import { SearchRepository } from '../repository/SearchRepository'
import { PerformancePageCache, SearchCacheSnapshot } from '../cache/PerformancePageCache'
import { CityRepository } from '../repository/CityRepository'

const SEARCH_BATCH_SIZE: number = 20
const DEFAULT_USER_ID: string = '1'

export class SearchResultViewModel {
  userId: string = DEFAULT_USER_ID
  keyword: string = ''
  currentCityName: string = ''
  inputKeyword: string = ''
  resultList: SearchResultItemVO[] = []
  hasMore: boolean = false
  isLoading: boolean = false
  isRefreshing: boolean = false
  errorMessage: string = ''

  private offset: number = 0
  private batchSize: number = SEARCH_BATCH_SIZE
  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private searchRepository: SearchRepository = new SearchRepository()
  private cityRepository: CityRepository = new CityRepository()

  restoreCache(keyword: string, userId: string = DEFAULT_USER_ID): boolean {
    this.userId = userId
    this.currentCityName = this.cityRepository.getCurrentCity()
    this.keyword = keyword.trim()
    this.inputKeyword = this.keyword
    const snapshot: SearchCacheSnapshot | undefined = PerformancePageCache.getSearch(this.buildCacheKey())
    if (snapshot === undefined) {
      return false
    }

    this.resultList = snapshot.resultList.slice()
    this.hasMore = snapshot.hasMore
    this.offset = snapshot.offset
    return true
  }

  async initPage(keyword: string, userId: string = DEFAULT_USER_ID): Promise<void> {
    this.userId = userId
    this.currentCityName = this.cityRepository.getCurrentCity()
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
        this.currentCityName,
        this.keyword,
        this.batchSize,
        this.offset
      )
      this.resultList = pageVO.resultList
      this.hasMore = pageVO.hasMore
      this.offset = pageVO.offset + pageVO.resultList.length
      this.saveCache()
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
        this.currentCityName,
        this.keyword,
        this.batchSize,
        this.offset
      )
      this.offset = pageVO.offset + pageVO.resultList.length
      this.resultList = this.appendUnique(this.resultList, pageVO.resultList)
      this.hasMore = pageVO.hasMore
      this.saveCache()
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载更多失败'
    } finally {
      this.isLoading = false
    }
  }

  private appendUnique(current: SearchResultItemVO[], incoming: SearchResultItemVO[]): SearchResultItemVO[] {
    const result: SearchResultItemVO[] = current.slice()
    const keys: Set<string> = new Set<string>()
    result.forEach((item: SearchResultItemVO) => {
      keys.add(item.projectId + '_' + item.sessionId)
    })
    incoming.forEach((item: SearchResultItemVO) => {
      const key: string = item.projectId + '_' + item.sessionId
      if (!keys.has(key)) {
        keys.add(key)
        result.push(item)
      }
    })
    return result
  }

  private saveCache(): void {
    const snapshot: SearchCacheSnapshot = {
      key: this.buildCacheKey(),
      cityName: this.currentCityName,
      keyword: this.keyword,
      resultList: this.resultList.slice(),
      hasMore: this.hasMore,
      offset: this.offset,
      updatedAt: Date.now()
    }
    PerformancePageCache.saveSearch(snapshot)
  }

  private buildCacheKey(): string {
    return this.currentCityName + '|' + this.keyword.trim().toLowerCase()
  }
}
