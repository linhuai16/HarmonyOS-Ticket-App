import {
  CategoryPageVO,
  CategoryPerformanceItemVO,
  PerformanceSortType
} from '../model/vo/performance/CategoryPageVO'

import {
  SearchResultPageVO,
  SearchResultItemVO
} from '../model/vo/performance/SearchPageVO'

import {
  PerformanceDetailVO,
  PerformanceSessionItemVO,
  VenueDisplayVO,
  ServiceTagVO,
  NoticeItemVO
} from '../model/vo/performance/PerformanceDetailVO'

import {
  TicketSelectPageVO,
  TicketSkuSelectVO
} from '../model/vo/performance/TicketSelectPageVO'

import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { SessionStatus } from '../model/enums/SessionStatus'
import { SkuStatus } from '../model/enums/SkuStatus'

interface ApiCategoryPageVO {
  performances?: ApiPerformanceCardVO[]
  total?: number
  limit?: number
  offset?: number
}

interface ApiSearchResultPageVO {
  keyword?: string
  performances?: ApiPerformanceCardVO[]
  total?: number
  limit?: number
  offset?: number
}

interface ApiPerformanceCardVO {
  projectId?: number
  sessionId?: number
  categoryId?: number
  categoryName?: string
  title?: string
  posterUrl?: string
  cityName?: string
  stationName?: string
  venueName?: string
  startTime?: string
  minPrice?: number
  maxPrice?: number
  sessionStatus?: string
}

interface ApiPerformanceDetailVO {
  project?: ApiProjectDetailVO
  sessions?: ApiSessionItemVO[]
  selectedSession?: ApiSessionItemVO
  venue?: ApiVenueVO
  serviceTags?: ApiServiceTagVO[]
  noticeItems?: ApiNoticeItemVO[]
}

interface ApiProjectDetailVO {
  projectId?: number
  title?: string
  categoryId?: number
  categoryName?: string
  posterUrl?: string
  detailContent?: string
  minPrice?: number
  maxPrice?: number
  wanted?: boolean
}

interface ApiSessionItemVO {
  sessionId?: number
  projectId?: number
  cityName?: string
  stationName?: string
  venueId?: number
  venueName?: string
  venueAddress?: string
  startTime?: string
  endTime?: string
  sessionStatus?: string
  minPrice?: number
  maxPrice?: number
  limitPerOrder?: number
  stationDetailContent?: string
  deliveryType?: string
  longitude?: number
  latitude?: number
}

interface ApiVenueVO {
  venueId?: number
  venueName?: string
  cityName?: string
  address?: string
  longitude?: number
  latitude?: number
}

interface ApiServiceTagVO {
  tagId?: number
  tagName?: string
  iconUrl?: string
  description?: string
}

interface ApiNoticeItemVO {
  noticeId?: number
  title?: string
  iconUrl?: string
  description?: string
}

interface ApiTicketSelectPageVO {
  project?: ApiProjectDetailVO
  session?: ApiSessionItemVO
  venue?: ApiVenueVO
  ticketSkus?: ApiTicketSkuVO[]
}

interface ApiTicketSkuVO {
  skuId?: number
  skuName?: string
  skuDesc?: string
  price?: number
  skuStatus?: string
  /** 后端 JSON 在未知库存场景会明确返回 null。Repository 边界统一转成 undefined。 */
  stockAvailable?: number | null
  maxSelectableQuantity?: number | null
}

const DEFAULT_LIMIT: number = 10

/**
 * 演出 Repository：已切换为 SpringBoot 接口。
 */
export class PerformanceRepository {
  async getCategoryPerformanceList(
    cityName: string,
    categoryId: string | undefined,
    sortType: PerformanceSortType,
    filterTime: string | undefined = undefined,
    limit: number = DEFAULT_LIMIT,
    offset: number = 0
  ): Promise<CategoryPageVO> {
    const normalizedCityName: string = this.normalizeCityName(cityName)
    const data: ApiCategoryPageVO = await ApiClient.get<ApiCategoryPageVO>('/api/performances/category', [
      new ApiQueryParam('cityName', normalizedCityName),
      new ApiQueryParam('categoryId', this.toApiCategoryId(categoryId)),
      new ApiQueryParam('sortType', sortType),
      new ApiQueryParam('filterTime', filterTime),
      new ApiQueryParam('limit', limit),
      new ApiQueryParam('offset', offset)
    ])

    const list: ApiPerformanceCardVO[] = data.performances ?? []
    const total: number = data.total ?? list.length
    const realLimit: number = data.limit ?? limit
    const realOffset: number = data.offset ?? offset

    const pageVO: CategoryPageVO = {
      currentCityName: normalizedCityName,
      performanceList: this.buildApiCategoryPerformanceList(list),
      hasMore: realOffset + realLimit < total
    }
    return pageVO
  }

  async searchPerformances(
    keyword: string,
    limit: number = DEFAULT_LIMIT,
    offset: number = 0
  ): Promise<SearchResultPageVO> {
    const trimmedKeyword: string = keyword.trim()

    if (trimmedKeyword.length === 0) {
      const emptyVO: SearchResultPageVO = {
        keyword: keyword,
        resultList: [],
        hasMore: false
      }
      return emptyVO
    }

    const data: ApiSearchResultPageVO = await ApiClient.get<ApiSearchResultPageVO>('/api/performances/search', [
      new ApiQueryParam('keyword', trimmedKeyword),
      new ApiQueryParam('limit', limit),
      new ApiQueryParam('offset', offset)
    ])

    const list: ApiPerformanceCardVO[] = data.performances ?? []
    const total: number = data.total ?? list.length
    const realLimit: number = data.limit ?? limit
    const realOffset: number = data.offset ?? offset

    const pageVO: SearchResultPageVO = {
      keyword: data.keyword ?? trimmedKeyword,
      resultList: this.buildApiSearchResultList(list),
      hasMore: realOffset + realLimit < total
    }
    return pageVO
  }

  async getPerformanceDetail(
    projectId: string,
    cityName: string,
    sessionId: string | undefined = undefined,
    userId: string | undefined = undefined
  ): Promise<PerformanceDetailVO | undefined> {
    const normalizedCityName: string = this.normalizeCityName(cityName)
    const data: ApiPerformanceDetailVO = await ApiClient.get<ApiPerformanceDetailVO>(
      '/api/performances/' + encodeURIComponent(projectId) + '/detail',
      [
        new ApiQueryParam('cityName', normalizedCityName),
        new ApiQueryParam('sessionId', sessionId),
        new ApiQueryParam('userId', userId)
      ]
    )

    return this.buildApiPerformanceDetailVO(data)
  }

  async getTicketSelectPage(projectId: string, sessionId: string): Promise<TicketSelectPageVO | undefined> {
    const data: ApiTicketSelectPageVO = await ApiClient.get<ApiTicketSelectPageVO>(
      '/api/performances/' + encodeURIComponent(projectId) + '/sessions/' + encodeURIComponent(sessionId) + '/ticket-select'
    )

    return this.buildApiTicketSelectPageVO(data)
  }

  private buildApiPerformanceDetailVO(data: ApiPerformanceDetailVO): PerformanceDetailVO | undefined {
    const project: ApiProjectDetailVO | undefined = data.project
    const sessions: ApiSessionItemVO[] = data.sessions ?? []
    const selectedSession: ApiSessionItemVO | undefined = data.selectedSession ?? (sessions.length > 0 ? sessions[0] : undefined)

    if (project === undefined || selectedSession === undefined) {
      return undefined
    }

    const detail: PerformanceDetailVO = {
      projectId: this.toId(project.projectId),
      selectedSessionId: this.toId(selectedSession.sessionId),
      posterUrl: project.posterUrl ?? '',
      title: project.title ?? '',
      categoryName: project.categoryName ?? '',
      minPrice: selectedSession.minPrice ?? project.minPrice,
      maxPrice: selectedSession.maxPrice ?? project.maxPrice,
      isWanted: project.wanted ?? false,
      sessions: this.buildApiDetailSessionList(sessions),
      venue: this.buildApiVenueDisplayVO(data.venue, selectedSession),
      serviceTags: this.buildApiServiceTagVOList(data.serviceTags ?? []),
      detailContent: this.getApiDetailContent(project, selectedSession),
      noticeItems: this.buildApiNoticeItemVOList(data.noticeItems ?? [])
    }

    return detail
  }

  private buildApiTicketSelectPageVO(data: ApiTicketSelectPageVO): TicketSelectPageVO | undefined {
    const project: ApiProjectDetailVO | undefined = data.project
    const session: ApiSessionItemVO | undefined = data.session

    if (project === undefined || session === undefined) {
      return undefined
    }

    const pageVO: TicketSelectPageVO = {
      projectId: this.toId(project.projectId),
      projectTitle: project.title ?? '',
      session: {
        sessionId: this.toId(session.sessionId),
        cityName: session.cityName ?? '',
        stationName: session.stationName ?? '',
        venueName: data.venue?.venueName ?? session.venueName ?? '',
        venueAddress: data.venue?.address ?? session.venueAddress ?? '',
        startTime: this.formatDateTime(session.startTime),
        sessionStatus: this.toSessionStatus(session.sessionStatus)
      },
      skus: this.buildApiTicketSkuSelectList(data.ticketSkus ?? []),
      limitPerOrder: session.limitPerOrder ?? 1
    }
    return pageVO
  }

  private buildApiDetailSessionList(list: ApiSessionItemVO[]): PerformanceSessionItemVO[] {
    return list.map((item: ApiSessionItemVO): PerformanceSessionItemVO => {
      const vo: PerformanceSessionItemVO = {
        sessionId: this.toId(item.sessionId),
        cityName: item.cityName ?? '',
        stationName: item.stationName ?? '',
        startTime: this.formatDateTime(item.startTime),
        sessionStatus: this.toSessionStatus(item.sessionStatus)
      }
      return vo
    })
  }

  private buildApiVenueDisplayVO(venue: ApiVenueVO | undefined, selectedSession: ApiSessionItemVO): VenueDisplayVO {
    const vo: VenueDisplayVO = {
      venueId: this.toId(venue?.venueId ?? selectedSession.venueId),
      venueName: venue?.venueName ?? selectedSession.venueName ?? '',
      venueAddress: venue?.address ?? selectedSession.venueAddress ?? '',
      longitude: venue?.longitude ?? selectedSession.longitude,
      latitude: venue?.latitude ?? selectedSession.latitude
    }
    return vo
  }

  private buildApiServiceTagVOList(list: ApiServiceTagVO[]): ServiceTagVO[] {
    return list.map((item: ApiServiceTagVO): ServiceTagVO => {
      const vo: ServiceTagVO = {
        tagId: this.toId(item.tagId),
        tagName: item.tagName ?? '',
        iconUrl: item.iconUrl,
        description: item.description
      }
      return vo
    })
  }

  private buildApiNoticeItemVOList(list: ApiNoticeItemVO[]): NoticeItemVO[] {
    return list.map((item: ApiNoticeItemVO): NoticeItemVO => {
      const vo: NoticeItemVO = {
        noticeId: this.toId(item.noticeId),
        title: item.title ?? '',
        iconUrl: item.iconUrl,
        description: item.description ?? ''
      }
      return vo
    })
  }

  private buildApiTicketSkuSelectList(list: ApiTicketSkuVO[]): TicketSkuSelectVO[] {
    return list.map((item: ApiTicketSkuVO): TicketSkuSelectVO => {
      // V1.3.3：availableStock/stockAvailable = null 表示供应商未提供精确库存，
      // 不等于 0，更不能因为 JSON null 直接落到页面的“不可点击”判断。
      // 页面领域 VO 统一使用 undefined 表示未知库存，避免 null > 0 被计算为 false。
      const stockAvailable: number | undefined =
        item.stockAvailable === undefined || item.stockAvailable === null
          ? undefined
          : Number(item.stockAvailable)
      const vo: TicketSkuSelectVO = {
        skuId: this.toId(item.skuId),
        skuName: item.skuName ?? '',
        skuDesc: this.sanitizeSkuDesc(item.skuDesc),
        price: item.price ?? 0,
        skuStatus: this.toSkuStatus(item.skuStatus),
        stockAvailable: stockAvailable
      }
      return vo
    })
  }


  private sanitizeSkuDesc(value: string | undefined): string | undefined {
    const text: string = value?.trim() ?? ''
    if (text.length === 0) return undefined
    if (text.indexOf('第三方票源') >= 0 || text.indexOf('MOCK-SKU') >= 0 || text.indexOf('provider') >= 0 || text.indexOf('Provider') >= 0) {
      return undefined
    }
    return text
  }

  private getApiDetailContent(project: ApiProjectDetailVO, selectedSession: ApiSessionItemVO): string | undefined {
    const sessionContent: string = selectedSession.stationDetailContent?.trim() ?? ''

    if (sessionContent.length > 0) {
      return selectedSession.stationDetailContent
    }

    const projectContent: string = project.detailContent?.trim() ?? ''

    if (projectContent.length > 0) {
      return project.detailContent
    }

    return undefined
  }

  private buildApiCategoryPerformanceList(list: ApiPerformanceCardVO[]): CategoryPerformanceItemVO[] {
    return list.map((item: ApiPerformanceCardVO): CategoryPerformanceItemVO => {
      const vo: CategoryPerformanceItemVO = {
        projectId: this.toId(item.projectId),
        sessionId: this.toId(item.sessionId),
        posterUrl: item.posterUrl ?? '',
        categoryName: item.categoryName ?? '',
        title: item.title ?? '',
        sessionStatus: this.toSessionStatus(item.sessionStatus),
        startTime: this.formatDateTime(item.startTime),
        cityName: item.cityName ?? '',
        venueName: item.venueName ?? '',
        minPrice: item.minPrice
      }
      return vo
    })
  }

  private buildApiSearchResultList(list: ApiPerformanceCardVO[]): SearchResultItemVO[] {
    return list.map((item: ApiPerformanceCardVO): SearchResultItemVO => {
      const vo: SearchResultItemVO = {
        projectId: this.toId(item.projectId),
        sessionId: this.toId(item.sessionId),
        posterUrl: item.posterUrl ?? '',
        categoryName: item.categoryName ?? '',
        title: item.title ?? '',
        startTime: this.formatDateTime(item.startTime),
        cityName: item.cityName ?? '',
        venueName: item.venueName ?? '',
        minPrice: item.minPrice,
        maxPrice: item.maxPrice
      }
      return vo
    })
  }

  private toApiCategoryId(categoryId: string | undefined): string | undefined {
    if (categoryId === undefined || categoryId.length === 0) {
      return undefined
    }
    return categoryId
  }

  private toId(value: number | string | undefined): string {
    if (value === undefined) {
      return ''
    }
    return String(value)
  }

  private formatDateTime(value: string | undefined): string {
    if (value === undefined) {
      return ''
    }
    return value.replace('T', ' ')
  }

  private normalizeCityName(cityName: string): string {
    const normalized: string = cityName.trim()
    if (normalized.endsWith('市')) {
      return normalized.substring(0, normalized.length - 1)
    }
    return normalized
  }

  private toSessionStatus(value: string | undefined): SessionStatus {
    if (value === SessionStatus.PRESALE) {
      return SessionStatus.PRESALE
    }
    if (value === SessionStatus.SOLD_OUT) {
      return SessionStatus.SOLD_OUT
    }
    if (value === SessionStatus.ENDED) {
      return SessionStatus.ENDED
    }
    if (value === SessionStatus.OFFLINE) {
      return SessionStatus.OFFLINE
    }
    return SessionStatus.ON_SALE
  }

  private toSkuStatus(value: string | undefined): SkuStatus {
    if (value === SkuStatus.ON_SALE) {
      return SkuStatus.ON_SALE
    }
    if (value === SkuStatus.PRESALE) {
      return SkuStatus.PRESALE
    }
    return SkuStatus.SOLD_OUT
  }
}
