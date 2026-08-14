import {
  CategoryPageVO,
  CategoryPerformanceItemVO,
  PerformanceSortType
} from '../model/vo/performance/CategoryPageVO'

import { PerformanceRepository } from '../repository/PerformanceRepository'
import { CityRepository } from '../repository/CityRepository'

const CATEGORY_PAGE_SIZE: number = 10

/**
 * 分类列表 ViewModel。
 */
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
  private pageSize: number = CATEGORY_PAGE_SIZE

  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private cityRepository: CityRepository = new CityRepository()

  constructor() {
    this.currentCityName = this.cityRepository.getCurrentCity()
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
    await this.loadCategoryList()
  }

  async reloadIfCityChanged(): Promise<void> {
    const newCityName: string = this.cityRepository.getCurrentCity()

    if (newCityName === this.currentCityName) {
      return
    }

    this.currentCityName = newCityName
    this.offset = 0
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
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''
    this.currentCityName = this.cityRepository.getCurrentCity()

    try {
      const pageVO: CategoryPageVO = await this.performanceRepository.getCategoryPerformanceList(
        this.currentCityName,
        this.categoryId,
        this.sortType,
        this.filterTime,
        this.pageSize,
        this.offset
      )

      this.currentCityName = pageVO.currentCityName
      this.categoryList = pageVO.performanceList
      this.hasMore = pageVO.hasMore
      this.offset = this.categoryList.length
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '分类列表加载失败'
    } finally {
      this.isLoading = false
    }
  }

  private async loadMoreCategoryList(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    try {
      const pageVO: CategoryPageVO = await this.performanceRepository.getCategoryPerformanceList(
        this.currentCityName,
        this.categoryId,
        this.sortType,
        this.filterTime,
        this.pageSize,
        this.offset
      )

      this.categoryList = this.categoryList.concat(pageVO.performanceList)
      this.hasMore = pageVO.hasMore
      this.offset = this.categoryList.length
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '加载更多失败'
    } finally {
      this.isLoading = false
    }
  }
}
