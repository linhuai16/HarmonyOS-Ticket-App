import {
  CategoryPageVO,
  CategoryPerformanceItemVO,
  PerformanceSortType
} from '../model/vo/performance/CategoryPageVO'

import {
  SearchResultPageVO,
  SearchResultItemVO
} from '../model/vo/performance/SearchPageVO'

import { PerformanceRepository } from '../repository/PerformanceRepository'
import { CityRepository } from '../repository/CityRepository'

const CATEGORY_PAGE_SIZE: number = 10

/**
    分类列表
    搜索结果列表
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

  initCategoryPage(categoryId: string | undefined = undefined): void {
    this.categoryId = categoryId
    this.offset = 0
    this.loadCategoryList()
  }




  refresh(): void {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.offset = 0
    this.errorMessage = ''

    this.loadCategoryList()

    this.isRefreshing = false
  }

  loadMore(): void {
    if (this.isLoading || !this.hasMore) {
      return
    }

    this.loadMoreCategoryList()
  }

  changeCity(cityName: string): void {
    if (cityName.length === 0) {
      return
    }

    this.cityRepository.saveCurrentCity(cityName)
    this.currentCityName = this.cityRepository.getCurrentCity()
    this.offset = 0
    this.loadCategoryList()
  }

  reloadIfCityChanged(): void {
    const newCityName: string = this.cityRepository.getCurrentCity()

    if (newCityName === this.currentCityName) {
      return
    }

    this.currentCityName = newCityName
    this.offset = 0
    this.loadCategoryList()
  }

  changeCategory(categoryId: string | undefined): void {
    this.categoryId = categoryId
    this.offset = 0
    this.loadCategoryList()
  }

  changeSort(sortType: PerformanceSortType): void {
    this.sortType = sortType
    this.offset = 0
    this.loadCategoryList()
  }

  changeFilterTime(filterTime: string | undefined): void {
    this.filterTime = filterTime
    this.offset = 0
    this.loadCategoryList()
  }

  clearFilterTime(): void {
    this.filterTime = undefined
    this.offset = 0
    this.loadCategoryList()
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private loadCategoryList(): void {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''
    this.currentCityName = this.cityRepository.getCurrentCity()

    const pageVO: CategoryPageVO = this.performanceRepository.getCategoryPerformanceList(
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
    this.isLoading = false
  }

  private loadMoreCategoryList(): void {
    this.isLoading = true
    this.errorMessage = ''

    const pageVO: CategoryPageVO = this.performanceRepository.getCategoryPerformanceList(
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
    this.isLoading = false
  }



}