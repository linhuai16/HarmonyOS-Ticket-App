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
  TicketSessionVO,
  TicketSkuSelectVO
} from '../model/vo/performance/TicketSelectPageVO'

import { performanceProjectMockList } from '../mock/performance/PerformanceProjectMock'
import { performanceSessionMockList } from '../mock/performance/PerformanceSessionMock'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { Venue } from '../model/entity/Venue'
import { ServiceTag } from '../model/entity/ServiceTag'
import { NoticeItem } from '../model/entity/NoticeItem'
import { TicketSku } from '../model/entity/TicketSku'
import { DateTimeUtil } from '../utils/DateTimeUtil'
import { PerformanceDataUtil } from '../utils/PerformanceDataUtil'

const DEFAULT_LIMIT: number = 10
const MOCK_NOW: string = '2026-05-20 00:00:00'

/**
 * 分类页按城市、分类、时间过滤，再按热度/最新排序；
 * 搜索按演出名称、分类、城市、场馆匹配；
 * 详情页聚合 Project、Session、Venue、serviceTags、noticeItems；
 * 票档选择页查询项目、场次、当前场次票档。
 */
export class PerformanceRepository {
  getCategoryPerformanceList(
    cityName: string,
    categoryId: string | undefined,
    sortType: PerformanceSortType,
    filterTime: string | undefined = undefined,
    limit: number = DEFAULT_LIMIT,
    offset: number = 0
  ): CategoryPageVO {
    const normalizedCityName: string = PerformanceDataUtil.normalizeCityName(cityName)
    const allList: CategoryPerformanceItemVO[] = this.buildCategoryPerformanceList(
      normalizedCityName,
      categoryId,
      sortType,
      filterTime
    )

    return {
      currentCityName: normalizedCityName,
      performanceList: this.slicePage(allList, limit, offset),
      hasMore: offset + limit < allList.length
    }
  }

  searchPerformances(
    keyword: string,
    cityName: string | undefined = undefined,
    limit: number = DEFAULT_LIMIT,
    offset: number = 0
  ): SearchResultPageVO {
    const trimmedKeyword: string = keyword.trim()

    if (trimmedKeyword.length === 0) {
      return {
        keyword: keyword,
        resultList: [],
        hasMore: false
      }
    }

    const allList: SearchResultItemVO[] = this.buildSearchResultList(trimmedKeyword, cityName)

    return {
      keyword: keyword,
      resultList: this.slicePage(allList, limit, offset),
      hasMore: offset + limit < allList.length
    }
  }

  getPerformanceDetail(
    projectId: string,
    sessionId: string,
    userId: string | undefined = undefined
  ): PerformanceDetailVO | undefined {
    const project: PerformanceProject | undefined = PerformanceDataUtil.findVisibleProject(projectId)

    if (project === undefined) {
      return undefined
    }

    const sessions: PerformanceSession[] = PerformanceDataUtil.findVisibleSessionsByProjectId(projectId)

    if (sessions.length === 0) {
      return undefined
    }

    const selectedSession: PerformanceSession | undefined = sessions.find((item: PerformanceSession) => {
      return item.sessionId === sessionId
    })

    if (selectedSession === undefined) {
      return undefined
    }

    return this.buildPerformanceDetailVO(project, selectedSession, sessions)
  }

  getTicketSelectPage(projectId: string, sessionId: string): TicketSelectPageVO | undefined {
    const project: PerformanceProject | undefined = PerformanceDataUtil.findVisibleProject(projectId)

    if (project === undefined) {
      return undefined
    }

    const selectedSession: PerformanceSession | undefined = PerformanceDataUtil.findVisibleSessionById(projectId, sessionId)

    if (selectedSession === undefined) {
      return undefined
    }

    return {
      projectId: project.projectId,
      projectTitle: project.title,
      session: this.buildTicketSessionVO(selectedSession),
      skus: this.buildTicketSkuSelectList(selectedSession.sessionId),
      limitPerOrder: selectedSession.limitPerOrder
    }
  }

  private buildCategoryPerformanceList(
    cityName: string,
    categoryId: string | undefined,
    sortType: PerformanceSortType,
    filterTime: string | undefined
  ): CategoryPerformanceItemVO[] {
    const result: CategoryPerformanceItemVO[] = []

    performanceProjectMockList.forEach((project: PerformanceProject) => {
      if (!this.canShowProjectInList(project, categoryId)) {
        return
      }

      this.findCategorySessions(project.projectId, cityName, filterTime).forEach((session: PerformanceSession) => {
        result.push(this.buildCategoryPerformanceItem(project, session))
      })
    })

    this.sortCategoryList(result, sortType)
    return result
  }

  private buildSearchResultList(keyword: string, cityName: string | undefined): SearchResultItemVO[] {
    const result: SearchResultItemVO[] = []
    const lowerKeyword: string = keyword.toLowerCase()
    const normalizedCityName: string = PerformanceDataUtil.normalizeCityName(cityName)

    performanceProjectMockList.forEach((project: PerformanceProject) => {
      if (!PerformanceDataUtil.isProjectVisible(project)) {
        return
      }

      this.findSearchMatchedSessions(project, normalizedCityName, lowerKeyword).forEach((session: PerformanceSession) => {
        result.push(this.buildSearchResultItem(project, session))
      })
    })

    result.sort((a: SearchResultItemVO, b: SearchResultItemVO) => {
      const scoreA: number = PerformanceDataUtil.getSearchScore(a.title, a.categoryName, a.cityName, a.venueName, lowerKeyword)
      const scoreB: number = PerformanceDataUtil.getSearchScore(b.title, b.categoryName, b.cityName, b.venueName, lowerKeyword)

      if (scoreA !== scoreB) {
        return scoreB - scoreA
      }

      return DateTimeUtil.toTimeMillis(a.startTime) - DateTimeUtil.toTimeMillis(b.startTime)
    })

    return result
  }

  private buildPerformanceDetailVO(
    project: PerformanceProject,
    selectedSession: PerformanceSession,
    sessions: PerformanceSession[]
  ): PerformanceDetailVO {
    const venue: Venue | undefined = PerformanceDataUtil.findVenue(selectedSession.venueId)

    return {
      projectId: project.projectId,
      selectedSessionId: selectedSession.sessionId,
      posterUrl: project.posterUrl,
      title: project.title,
      categoryName: PerformanceDataUtil.getCategoryName(project.categoryId),
      minPrice: selectedSession.minPrice ?? project.minPrice,
      maxPrice: selectedSession.maxPrice ?? project.maxPrice,
      isWanted: false,
      sessions: this.buildDetailSessionList(sessions),
      venue: this.buildVenueDisplayVO(selectedSession, venue),
      serviceTags: this.buildServiceTagVOList(PerformanceDataUtil.getProjectServiceTags(project.projectId)),
      detailContent: this.getDetailContent(project, selectedSession),
      noticeItems: this.buildNoticeItemVOList(PerformanceDataUtil.getProjectNoticeItems(project.projectId))
    }
  }

  private canShowProjectInList(project: PerformanceProject, categoryId: string | undefined): boolean {
    if (!PerformanceDataUtil.isProjectVisible(project)) {
      return false
    }

    if (categoryId !== undefined && categoryId.length > 0 && project.categoryId !== categoryId) {
      return false
    }

    return true
  }

  private findCategorySessions(
    projectId: string,
    cityName: string,
    filterTime: string | undefined
  ): PerformanceSession[] {
    return performanceSessionMockList.filter((session: PerformanceSession) => {
      return session.projectId === projectId &&
        session.cityName === cityName &&
        PerformanceDataUtil.isSessionVisible(session) &&
        PerformanceDataUtil.matchFilterTime(session, filterTime, MOCK_NOW)
    })
  }

  private findSearchMatchedSessions(
    project: PerformanceProject,
    cityName: string,
    lowerKeyword: string
  ): PerformanceSession[] {
    return performanceSessionMockList.filter((session: PerformanceSession) => {
      if (session.projectId !== project.projectId || !PerformanceDataUtil.isSessionVisible(session)) {
        return false
      }

      if (cityName.length > 0 && session.cityName !== cityName) {
        return false
      }

      return PerformanceDataUtil.matchSearchKeyword(project, session, lowerKeyword)
    })
  }

  private buildCategoryPerformanceItem(project: PerformanceProject, session: PerformanceSession): CategoryPerformanceItemVO {
    return {
      projectId: project.projectId,
      sessionId: session.sessionId,
      posterUrl: project.posterUrl,
      categoryName: PerformanceDataUtil.getCategoryName(project.categoryId),
      title: project.title,
      sessionStatus: session.sessionStatus,
      startTime: session.startTime,
      cityName: session.cityName,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      minPrice: session.minPrice ?? project.minPrice
    }
  }

  private buildSearchResultItem(project: PerformanceProject, session: PerformanceSession): SearchResultItemVO {
    return {
      projectId: project.projectId,
      sessionId: session.sessionId,
      posterUrl: project.posterUrl,
      categoryName: PerformanceDataUtil.getCategoryName(project.categoryId),
      title: project.title,
      startTime: session.startTime,
      cityName: session.cityName,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      minPrice: session.minPrice ?? project.minPrice,
      maxPrice: session.maxPrice ?? project.maxPrice
    }
  }

  private sortCategoryList(result: CategoryPerformanceItemVO[], sortType: PerformanceSortType): void {
    if (sortType === PerformanceSortType.NEW) {
      result.sort((a: CategoryPerformanceItemVO, b: CategoryPerformanceItemVO) => {
        return PerformanceDataUtil.compareProjectPublishTimeDesc(
          PerformanceDataUtil.findProject(a.projectId),
          PerformanceDataUtil.findProject(b.projectId)
        )
      })
      return
    }

    result.sort((a: CategoryPerformanceItemVO, b: CategoryPerformanceItemVO) => {
      return PerformanceDataUtil.getProjectHotScore(PerformanceDataUtil.findProject(b.projectId)) -
        PerformanceDataUtil.getProjectHotScore(PerformanceDataUtil.findProject(a.projectId))
    })
  }

  private buildDetailSessionList(sessions: PerformanceSession[]): PerformanceSessionItemVO[] {
    return sessions.map((session: PerformanceSession): PerformanceSessionItemVO => {
      return {
        sessionId: session.sessionId,
        cityName: session.cityName,
        stationName: session.stationName,
        startTime: session.startTime,
        sessionStatus: session.sessionStatus
      }
    })
  }

  private buildVenueDisplayVO(session: PerformanceSession, venue: Venue | undefined): VenueDisplayVO {
    return {
      venueId: session.venueId,
      venueName: venue?.venueName ?? '',
      venueAddress: venue?.address ?? '',
      longitude: venue?.longitude,
      latitude: venue?.latitude
    }
  }

  private getDetailContent(project: PerformanceProject, selectedSession: PerformanceSession): string | undefined {
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

  private buildServiceTagVOList(serviceTags: ServiceTag[] | undefined): ServiceTagVO[] {
    if (serviceTags === undefined) {
      return []
    }

    return serviceTags
      .map((tag: ServiceTag): ServiceTagVO => {
        return {
          tagId: tag.tagId,
          tagName: tag.tagName,
          iconUrl: tag.iconUrl,
          description: tag.description
        }
      })
  }

  private buildNoticeItemVOList(noticeItems: NoticeItem[] | undefined): NoticeItemVO[] {
    if (noticeItems === undefined) {
      return []
    }

    return noticeItems
      .map((notice: NoticeItem): NoticeItemVO => {
        return {
          noticeId: notice.noticeId,
          title: notice.title,
          iconUrl: notice.iconUrl,
          description: notice.description
        }
      })
  }

  private buildTicketSessionVO(session: PerformanceSession): TicketSessionVO {
    return {
      sessionId: session.sessionId,
      cityName: session.cityName,
      stationName: session.stationName,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      venueAddress: PerformanceDataUtil.getVenueAddress(session.venueId),
      startTime: session.startTime,
      sessionStatus: session.sessionStatus
    }
  }

  private buildTicketSkuSelectList(sessionId: string): TicketSkuSelectVO[] {
    return PerformanceDataUtil.getTicketSkusBySessionId(sessionId)
      .map((sku: TicketSku): TicketSkuSelectVO => {
        return {
          skuId: sku.skuId,
          skuName: sku.skuName,
          skuDesc: sku.skuDesc,
          price: sku.price,
          skuStatus: sku.skuStatus,
          stockAvailable: sku.stockAvailable
        }
      })
  }

  private slicePage<T>(list: T[], limit: number, offset: number): T[] {
    return list.slice(offset, offset + limit)
  }
}
