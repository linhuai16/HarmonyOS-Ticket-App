import { CategoryPageVO, CategoryPerformanceItemVO, PerformanceSortType } from '../model/vo/performance/CategoryPageVO'
import { PerformanceRepository } from '../repository/PerformanceRepository'
import { CityRepository } from '../repository/CityRepository'
import { CategoryCacheSnapshot, PerformancePageCache } from '../cache/PerformancePageCache'

const CATEGORY_BATCH_SIZE: number = 20

export class CategoryViewModel {
  currentCityName: string = ''
  categoryId: string | undefined = undefined
  sortType: PerformanceSortType = PerformanceSortType.HOT
  filterTime: string | undefined = undefined
  categoryList: CategoryPerformanceItemVO[] = []
  hasMore: boolean = false
  isLoading: boolean = false
  isRefreshing: boolean = false
  errorMessage: string = ''

  private offset: number = 0
  private batchSize: number = CATEGORY_BATCH_SIZE
  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private cityRepository: CityRepository = new CityRepository()
  private requestVersion: number = 0

  constructor() {
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  restoreCache(categoryId: string | undefined = undefined): boolean {
    this.currentCityName = this.cityRepository.getCurrentCity()
    this.categoryId = categoryId
    this.sortType = PerformanceSortType.HOT
    this.filterTime = undefined
    const snapshot: CategoryCacheSnapshot | undefined = PerformancePageCache.getCategory(this.buildCacheKey())
    if (snapshot === undefined) {
      return false
    }

    this.currentCityName = snapshot.cityName
    this.categoryList = snapshot.performanceList.slice()
    this.hasMore = snapshot.hasMore
    this.offset = snapshot.offset
    return true
  }

  async initCategoryPage(categoryId: string | undefined = undefined): Promise<void> {
    this.categoryId = categoryId
    this.offset = 0
    await this.loadCategoryList()
  }

  async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.offset = 0
    this.errorMessage = ''
    await this.loadCategoryList()
    this.isRefreshing = false
  }

  async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMore) {
      return
    }
    await this.loadMoreCategoryList()
  }

  async changeCity(cityName: string): Promise<void> {
    if (cityName.length === 0) {
      return
    }

    this.cityRepository.saveCurrentCity(cityName)
    this.currentCityName = this.cityRepository.getCurrentCity()
    this.offset = 0
    this.categoryList = []
    this.hasMore = false
    await this.loadCategoryList()
  }

  async reloadIfCityChanged(): Promise<void> {
    const newCityName: string = this.cityRepository.getCurrentCity()
    if (newCityName === this.currentCityName) {
      return
    }

    this.currentCityName = newCityName
    this.offset = 0
    this.categoryList = []
    this.hasMore = false
    await this.loadCategoryList()
  }

  async changeCategory(categoryId: string | undefined): Promise<void> {
    this.categoryId = categoryId
    this.offset = 0
    await this.loadCategoryList()
  }

  async changeSort(sortType: PerformanceSortType): Promise<void> {
    this.sortType = sortType
    this.offset = 0
    await this.loadCategoryList()
  }

  async changeFilterTime(filterTime: string | undefined): Promise<void> {
    this.filterTime = filterTime
    this.offset = 0
    await this.loadCategoryList()
  }

  async clearFilterTime(): Promise<void> {
    this.filterTime = undefined
    this.offset = 0
    await this.loadCategoryList()
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private async loadCategoryList(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.currentCityName = this.cityRepository.getCurrentCity()
    const requestVersion: number = ++this.requestVersion
    const requestCity: string = this.currentCityName
    const requestCategoryId: string | undefined = this.categoryId
    const requestSortType: PerformanceSortType = this.sortType
    const requestFilterTime: string | undefined = this.filterTime
    const requestOffset: number = this.offset

    try {
      const pageVO: CategoryPageVO = await this.performanceRepository.getCategoryPerformanceList(
        requestCity,
        requestCategoryId,
        requestSortType,
        requestFilterTime,
        this.batchSize,
        requestOffset
      )
      if (requestVersion !== this.requestVersion || requestCity !== this.currentCityName) {
        return
      }
      this.currentCityName = pageVO.currentCityName
      this.categoryList = pageVO.performanceList
      this.hasMore = pageVO.hasMore
      this.offset = pageVO.offset + pageVO.performanceList.length
      this.saveCache()
    } catch (error) {
      if (requestVersion === this.requestVersion) {
        this.errorMessage = error instanceof Error ? error.message : '分类列表加载失败'
      }
    } finally {
      if (requestVersion === this.requestVersion) {
        this.isLoading = false
      }
    }
  }

  private async loadMoreCategoryList(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    const requestVersion: number = this.requestVersion
    const requestCity: string = this.currentCityName

    try {
      const pageVO: CategoryPageVO = await this.performanceRepository.getCategoryPerformanceList(
        requestCity,
        this.categoryId,
        this.sortType,
        this.filterTime,
        this.batchSize,
        this.offset
      )
      if (requestVersion !== this.requestVersion || requestCity !== this.currentCityName) {
        return
      }
      this.offset = pageVO.offset + pageVO.performanceList.length
      this.categoryList = this.appendUnique(this.categoryList, pageVO.performanceList)
      this.hasMore = pageVO.hasMore
      this.saveCache()
    } catch (error) {
      if (requestVersion === this.requestVersion) {
        this.errorMessage = error instanceof Error ? error.message : '加载更多失败'
      }
    } finally {
      if (requestVersion === this.requestVersion) {
        this.isLoading = false
      }
    }
  }

  private appendUnique(current: CategoryPerformanceItemVO[], incoming: CategoryPerformanceItemVO[]): CategoryPerformanceItemVO[] {
    const result: CategoryPerformanceItemVO[] = current.slice()
    const keys: Set<string> = new Set<string>()
    result.forEach((item: CategoryPerformanceItemVO) => {
      keys.add(item.projectId + '_' + item.sessionId)
    })
    incoming.forEach((item: CategoryPerformanceItemVO) => {
      const key: string = item.projectId + '_' + item.sessionId
      if (!keys.has(key)) {
        keys.add(key)
        result.push(item)
      }
    })
    return result
  }

  private saveCache(): void {
    const snapshot: CategoryCacheSnapshot = {
      key: this.buildCacheKey(),
      cityName: this.currentCityName,
      performanceList: this.categoryList.slice(),
      hasMore: this.hasMore,
      offset: this.offset,
      updatedAt: Date.now()
    }
    PerformancePageCache.saveCategory(snapshot)
  }

  private buildCacheKey(): string {
    return this.currentCityName + '|' + (this.categoryId ?? 'ALL') + '|' + this.sortType + '|' + (this.filterTime ?? 'ALL')
  }
}
