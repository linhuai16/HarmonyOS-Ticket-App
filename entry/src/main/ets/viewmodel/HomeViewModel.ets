import { HomePageVO, HomeCategoryVO, HomeBannerVO, HomeRecommendItemVO } from '../model/vo/home/HomePageVO'
import { HomeRepository } from '../repository/HomeRepository'
import { CityRepository } from '../repository/CityRepository'
import { HomeCacheSnapshot, PerformancePageCache } from '../cache/PerformancePageCache'

const HOME_BATCH_SIZE: number = 20

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
  private batchSize: number = HOME_BATCH_SIZE
  private homeRepository: HomeRepository = new HomeRepository()
  private cityRepository: CityRepository = new CityRepository()
  private requestVersion: number = 0
  private cacheRestoreAttempted: boolean = false
  private static firstPageRequests: Map<string, Promise<HomePageVO>> = new Map<string, Promise<HomePageVO>>()
  private static automaticLoadFinished: Set<string> = new Set<string>()

  constructor() {
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  restoreCache(): boolean {
    if (this.cacheRestoreAttempted) {
      return this.recommendList.length > 0 || this.categories.length > 0 || this.banners.length > 0
    }
    this.cacheRestoreAttempted = true
    const cityName: string = this.currentCityName
    const snapshot: HomeCacheSnapshot | undefined = PerformancePageCache.getHome(cityName)
    if (snapshot === undefined) {
      return false
    }

    this.currentCityName = snapshot.cityName
    this.categories = snapshot.categories.slice()
    this.banners = snapshot.banners.slice()
    this.recommendList = snapshot.recommendList.slice()
    this.hasMore = snapshot.hasMore
    this.offset = snapshot.offset
    return true
  }

  async loadHome(force: boolean = false): Promise<boolean> {
    if (this.isLoading && !force) {
      return false
    }

    const cityName: string = this.currentCityName.length > 0 ? this.currentCityName : this.cityRepository.getCurrentCity()
    const requestKey: string = cityName + '|' + String(this.batchSize)
    if (!force && HomeViewModel.automaticLoadFinished.has(requestKey) && this.hasDisplayData()) {
      return false
    }
    this.isLoading = true
    this.errorMessage = ''
    this.offset = 0
    this.currentCityName = cityName
    const requestVersion: number = ++this.requestVersion

    try {
      const pageVO: HomePageVO = await this.requestFirstPage(cityName, 'load')
      if (requestVersion !== this.requestVersion || cityName !== this.currentCityName) {
        return false
      }
      this.applyHomePageVO(pageVO)
      this.offset = pageVO.offset + pageVO.recommendList.length
      this.saveFirstScreenCache()
      return true
    } catch (error) {
      if (requestVersion === this.requestVersion) {
        this.errorMessage = error instanceof Error ? error.message : '首页数据加载失败'
      }
      return true
    } finally {
      if (!force) {
        HomeViewModel.automaticLoadFinished.add(requestKey)
      }
      if (requestVersion === this.requestVersion) {
        this.isLoading = false
      }
    }
  }

  async refreshHome(): Promise<void> {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.errorMessage = ''
    this.offset = 0
    this.currentCityName = this.cityRepository.getCurrentCity()
    const requestCity: string = this.currentCityName
    const requestVersion: number = ++this.requestVersion

    try {
      const pageVO: HomePageVO = await this.requestFirstPage(requestCity, 'refresh')
      if (requestVersion !== this.requestVersion || requestCity !== this.currentCityName) {
        return
      }
      this.applyHomePageVO(pageVO)
      this.offset = pageVO.offset + pageVO.recommendList.length
      this.saveFirstScreenCache()
    } catch (error) {
      if (requestVersion === this.requestVersion) {
        this.errorMessage = error instanceof Error ? error.message : '首页刷新失败'
      }
    } finally {
      this.isRefreshing = false
    }
  }

  async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMore) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''
    const requestVersion: number = this.requestVersion
    const requestCity: string = this.currentCityName
    const requestOffset: number = this.offset

    try {
      const pageVO: HomePageVO = await this.homeRepository.getHomeIndex(
        requestCity,
        this.batchSize,
        requestOffset
      )
      if (requestVersion !== this.requestVersion || requestCity !== this.currentCityName) {
        return
      }
      this.offset = pageVO.offset + pageVO.recommendList.length
      this.recommendList = this.appendUnique(this.recommendList, pageVO.recommendList)
      this.hasMore = pageVO.hasMore
      this.saveMemoryCache()
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

  async changeCity(cityName: string): Promise<void> {
    if (cityName.length === 0) {
      return
    }

    const previousCityName: string = this.currentCityName
    this.cityRepository.saveCurrentCity(cityName)
    this.currentCityName = this.cityRepository.getCurrentCity()
    if (this.currentCityName === previousCityName) {
      return
    }
    this.requestVersion++
    this.recommendList = []
    this.hasMore = false
    this.offset = 0
    this.errorMessage = ''
    await this.loadHome(true)
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

  private hasDisplayData(): boolean {
    return this.categories.length > 0 || this.banners.length > 0 || this.recommendList.length > 0
  }

  private async requestFirstPage(cityName: string, reason: string): Promise<HomePageVO> {
    const key: string = cityName + '|' + String(this.batchSize)
    const existing: Promise<HomePageVO> | undefined = HomeViewModel.firstPageRequests.get(key)
    if (existing !== undefined) {
      return await existing
    }
    const request: Promise<HomePageVO> = this.homeRepository.getHomeIndex(cityName, this.batchSize, 0)
    HomeViewModel.firstPageRequests.set(key, request)
    try {
      const pageVO: HomePageVO = await request
      return pageVO
    } catch (error) {
      throw error instanceof Error ? error : new Error(String(error))
    } finally {
      HomeViewModel.firstPageRequests.delete(key)
    }
  }

  private appendUnique(current: HomeRecommendItemVO[], incoming: HomeRecommendItemVO[]): HomeRecommendItemVO[] {
    const result: HomeRecommendItemVO[] = current.slice()
    const keys: Set<string> = new Set<string>()
    result.forEach((item: HomeRecommendItemVO) => {
      keys.add(item.projectId + '_' + item.sessionId)
    })
    incoming.forEach((item: HomeRecommendItemVO) => {
      const key: string = item.projectId + '_' + item.sessionId
      if (!keys.has(key)) {
        keys.add(key)
        result.push(item)
      }
    })
    return result
  }

  private saveFirstScreenCache(): void {
    const snapshot: HomeCacheSnapshot = this.buildCacheSnapshot()
    PerformancePageCache.saveHomeFirstScreen(snapshot)
  }

  private saveMemoryCache(): void {
    PerformancePageCache.saveHomeMemory(this.buildCacheSnapshot())
  }

  private buildCacheSnapshot(): HomeCacheSnapshot {
    return {
      cityName: this.currentCityName,
      categories: this.categories.slice(),
      banners: this.banners.slice(),
      recommendList: this.recommendList.slice(),
      hasMore: this.hasMore,
      offset: this.offset,
      updatedAt: Date.now()
    }
  }
}
