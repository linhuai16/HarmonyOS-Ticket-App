import {
  SearchPageVO,
  SearchHistoryItemVO
} from '../model/vo/performance/SearchPageVO'

import { ApiClient, ApiQueryParam } from '../network/ApiClient'

interface ApiSearchPageVO {
  histories?: ApiSearchHistoryItemVO[]
}

interface ApiSearchHistoryItemVO {
  historyId?: number
  keyword?: string
  lastSearchTime?: string
}

class SaveSearchHistoryRequest {
  userId: number
  keyword: string

  constructor(userId: number, keyword: string) {
    this.userId = userId
    this.keyword = keyword
  }
}

const DEFAULT_USER_ID: string = '1'

/**
 * 搜索历史 Repository：已切换为 SpringBoot 接口。
 */
export class SearchRepository {
  async getSearchPage(userId: string = DEFAULT_USER_ID): Promise<SearchPageVO> {
    const data: ApiSearchPageVO = await ApiClient.get<ApiSearchPageVO>('/api/search/history', [
      new ApiQueryParam('userId', this.toUserId(userId))
    ])

    return {
      histories: this.buildHistoryList(data.histories ?? [])
    }
  }

  async saveSearchHistory(keyword: string, userId: string = DEFAULT_USER_ID): Promise<void> {
    const realKeyword: string = keyword.trim()
    if (realKeyword.length === 0) {
      return
    }

    await ApiClient.post<object>('/api/search/history', new SaveSearchHistoryRequest(this.toUserId(userId), realKeyword))
  }

  async deleteSearchHistory(historyId: string, userId: string = DEFAULT_USER_ID): Promise<void> {
    if (historyId.length === 0) {
      return
    }

    await ApiClient.delete<object>('/api/search/history/' + historyId, [
      new ApiQueryParam('userId', this.toUserId(userId))
    ])
  }

  async clearSearchHistory(userId: string = DEFAULT_USER_ID): Promise<void> {
    await ApiClient.delete<object>('/api/search/history', [
      new ApiQueryParam('userId', this.toUserId(userId))
    ])
  }

  private buildHistoryList(list: ApiSearchHistoryItemVO[]): SearchHistoryItemVO[] {
    return list.map((item: ApiSearchHistoryItemVO): SearchHistoryItemVO => {
      return {
        historyId: this.toId(item.historyId),
        keyword: item.keyword ?? ''
      }
    })
  }

  private toId(value: number | string | undefined): string {
    if (value === undefined) {
      return ''
    }
    return String(value)
  }

  private toUserId(userId: string): number {
    const parsed: number = Number(userId)
    if (Number.isNaN(parsed) || parsed <= 0) {
      return 1
    }
    return parsed
  }
}
