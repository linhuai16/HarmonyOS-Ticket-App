import {
  SearchResultItemVO,
  SearchResultPageVO
} from '../model/vo/performance/SearchPageVO'

import { PerformanceRepository } from '../repository/PerformanceRepository'
import { SearchRepository } from '../repository/SearchRepository'
import { CityRepository } from '../repository/CityRepository'

const SEARCH_PAGE_SIZE: number = 10
const MOCK_USER_ID: string = 'user_001'


/**
 顶部搜索框可输入；
 输入后搜索按钮可用；
 点击 x 清空；
 二次搜索保存历史；
 二次搜索重新加载结果列表；
 结果列表分页；
 城市变化后重新加载结果；
 点击卡片跳转详情页；
 不包含分类、排序、时间筛选。
 */

export class SearchResultViewModel {
  userId: string = MOCK_USER_ID

  /** 当前真正用于搜索的关键词 */
  keyword: string = ''

  /** 顶部搜索框输入中的关键词 */
  inputKeyword: string = ''

  currentCityName: string = ''

  resultList: SearchResultItemVO[] = []
  hasMore: boolean = false

  isLoading: boolean = false
  isRefreshing: boolean = false
  errorMessage: string = ''

  private offset: number = 0
  private pageSize: number = SEARCH_PAGE_SIZE

  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private searchRepository: SearchRepository = new SearchRepository()
  private cityRepository: CityRepository = new CityRepository()

  constructor() {
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  initPage(keyword: string, userId: string = MOCK_USER_ID): void {
    this.userId = userId
    this.keyword = keyword.trim()
    this.inputKeyword = this.keyword
    this.offset = 0
    this.loadResultList()
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

  /**
   * 搜索结果页顶部二次搜索
   */
  searchAgain(): void {
    const realKeyword: string = this.inputKeyword.trim()

    if (realKeyword.length === 0) {
      this.errorMessage = '请输入搜索关键词'
      return
    }

    this.searchRepository.saveSearchHistory(realKeyword, this.userId)

    this.keyword = realKeyword
    this.inputKeyword = realKeyword
    this.offset = 0
    this.loadResultList()
  }

  refresh(): void {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.offset = 0
    this.loadResultList()
    this.isRefreshing = false
  }

  loadMore(): void {
    if (this.isLoading || !this.hasMore) {
      return
    }

    this.loadMoreResultList()
  }


  /**
   * 页面重新显示时检查当前城市是否变化。
   * 搜索结果页当前不展示城市入口，但如果用户从其他入口切换了城市，
   * 回到该页后仍应按当前关键词和新城市刷新结果。
   */
  reloadIfCityChanged(): void {
    const newCityName: string = this.cityRepository.getCurrentCity()

    if (newCityName === this.currentCityName) {
      return
    }

    this.currentCityName = newCityName
    this.offset = 0
    this.loadResultList()
  }


  buildDetailJumpParams(item: SearchResultItemVO): Record<string, string> {
    return {
      "projectId": item.projectId,
      "sessionId": item.sessionId
    }
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private loadResultList(): void {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''
    this.currentCityName = this.cityRepository.getCurrentCity()

    const pageVO: SearchResultPageVO = this.performanceRepository.searchPerformances(
      this.keyword,
      this.currentCityName,
      this.pageSize,
      this.offset
    )

    this.resultList = pageVO.resultList
    this.hasMore = pageVO.hasMore
    this.offset = this.resultList.length

    this.isLoading = false
  }

  private loadMoreResultList(): void {
    this.isLoading = true
    this.errorMessage = ''

    const pageVO: SearchResultPageVO = this.performanceRepository.searchPerformances(
      this.keyword,
      this.currentCityName,
      this.pageSize,
      this.offset
    )

    this.resultList = this.resultList.concat(pageVO.resultList)
    this.hasMore = pageVO.hasMore
    this.offset = this.resultList.length

    this.isLoading = false
  }
}