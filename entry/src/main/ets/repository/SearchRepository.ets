import {
  SearchPageVO,
  SearchHistoryItemVO
} from '../model/vo/performance/SearchPageVO'

import { SearchHistory } from '../model/entity/SearchHistory'
import { searchHistoryMockList } from '../mock/search/SearchHistoryMock'
import { DateTimeUtil } from '../utils/DateTimeUtil'
import { IdGenerator } from '../utils/IdGenerator'

const MAX_HISTORY_COUNT: number = 50
const MOCK_USER_ID: string = 'user_001'

/**
 * 搜索历史 Repository。
 *
 * 只负责搜索历史的读取、保存、删除、清空。
 * 搜索结果本身仍由 PerformanceRepository.searchPerformances() 负责，避免两个 Repository 职责重叠。
 */
export class SearchRepository {
  getSearchPage(userId: string = MOCK_USER_ID): SearchPageVO {
    return {
      histories: this.getUserHistories(userId).map((item: SearchHistory): SearchHistoryItemVO => {
        return this.buildHistoryItemVO(item)
      })
    }
  }

  saveSearchHistory(keyword: string, userId: string = MOCK_USER_ID): void {
    const realKeyword: string = keyword.trim()
    if (realKeyword.length === 0) {
      return
    }

    this.removeSameKeywordHistory(userId, realKeyword)
    searchHistoryMockList.unshift(this.createSearchHistory(userId, realKeyword))
    this.limitHistoryCount(userId)
  }

  deleteSearchHistory(historyId: string): void {
    this.removeHistories((item: SearchHistory) => {
      return item.historyId === historyId
    })
  }

  clearSearchHistory(userId: string = MOCK_USER_ID): void {
    this.removeHistories((item: SearchHistory) => {
      return item.userId === userId
    })
  }

  private getUserHistories(userId: string): SearchHistory[] {
    return searchHistoryMockList
      .filter((item: SearchHistory) => item.userId === userId)
      .sort((a: SearchHistory, b: SearchHistory) => this.compareSearchTimeDesc(a, b))
  }

  private removeSameKeywordHistory(userId: string, keyword: string): void {
    this.removeHistories((item: SearchHistory) => {
      return item.userId === userId && item.keyword === keyword
    })
  }

  private limitHistoryCount(userId: string): void {
    const userHistories: SearchHistory[] = this.getUserHistories(userId)
    if (userHistories.length <= MAX_HISTORY_COUNT) {
      return
    }

    const removeIds: string[] = userHistories
      .slice(MAX_HISTORY_COUNT)
      .map((item: SearchHistory): string => item.historyId)

    this.removeHistories((item: SearchHistory) => {
      return removeIds.indexOf(item.historyId) >= 0
    })
  }

  private removeHistories(match: (item: SearchHistory) => boolean): void {
    for (let i = searchHistoryMockList.length - 1; i >= 0; i--) {
      if (match(searchHistoryMockList[i])) {
        searchHistoryMockList.splice(i, 1)
      }
    }
  }

  private createSearchHistory(userId: string, keyword: string): SearchHistory {
    return {
      historyId: IdGenerator.createSearchHistoryId(),
      userId: userId,
      keyword: keyword,
      searchTime: DateTimeUtil.now()
    }
  }

  private buildHistoryItemVO(item: SearchHistory): SearchHistoryItemVO {
    return {
      historyId: item.historyId,
      keyword: item.keyword
    }
  }

  private compareSearchTimeDesc(a: SearchHistory, b: SearchHistory): number {
    return DateTimeUtil.toTimeMillis(b.searchTime) - DateTimeUtil.toTimeMillis(a.searchTime)
  }
}
