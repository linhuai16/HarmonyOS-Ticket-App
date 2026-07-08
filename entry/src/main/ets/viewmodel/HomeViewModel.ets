import {
  HomePageVO,
  HomeCategoryVO,
  HomeBannerVO,
  HomeRecommendItemVO
} from '../model/vo/home/HomePageVO'

import { HomeRepository } from '../repository/HomeRepository'
import { CityRepository } from '../repository/CityRepository'

const HOME_PAGE_SIZE: number = 10

export class HomeViewModel {
  currentCityName: string = ''
  categories: HomeCategoryVO[] = []
  banners: HomeBannerVO[] = []
  recommendList: HomeRecommendItemVO[] = []

  hasMore: boolean = false
  isLoading: boolean = false
  isRefreshing: boolean = false
  errorMessage: string = ''

  private offset: number = 0
  private pageSize: number = HOME_PAGE_SIZE

  private homeRepository: HomeRepository = new HomeRepository()
  private cityRepository: CityRepository = new CityRepository()

  constructor() {
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  loadHome(): void {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''
    this.offset = 0

    const cityName: string = this.cityRepository.getCurrentCity()
    this.currentCityName = cityName

    const pageVO: HomePageVO = this.homeRepository.getHomeIndex(
      cityName,
      this.pageSize,
      this.offset
    )

    this.applyHomePageVO(pageVO)
    this.offset = this.recommendList.length
    this.isLoading = false
  }

  refreshHome(): void {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.errorMessage = ''
    this.offset = 0

    const cityName: string = this.cityRepository.getCurrentCity()
    this.currentCityName = cityName

    const pageVO: HomePageVO = this.homeRepository.getHomeIndex(
      cityName,
      this.pageSize,
      this.offset
    )

    this.applyHomePageVO(pageVO)
    this.offset = this.recommendList.length
    this.isRefreshing = false
  }

  loadMore(): void {
    if (this.isLoading || !this.hasMore) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    const pageVO: HomePageVO = this.homeRepository.getHomeIndex(
      this.currentCityName,
      this.pageSize,
      this.offset
    )

    this.recommendList = this.recommendList.concat(pageVO.recommendList)
    this.hasMore = pageVO.hasMore
    this.offset = this.recommendList.length

    this.isLoading = false
  }

  changeCity(cityName: string): void {
    if (cityName.length === 0) {
      return
    }

    this.cityRepository.saveCurrentCity(cityName)
    this.currentCityName = cityName
    this.loadHome()
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private applyHomePageVO(pageVO: HomePageVO): void {
    this.currentCityName = pageVO.currentCityName
    this.categories = pageVO.categories
    this.banners = pageVO.banners
    this.recommendList = pageVO.recommendList
    this.hasMore = pageVO.hasMore
  }
}