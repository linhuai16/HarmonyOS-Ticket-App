import { categoryMockList } from '../mock/category/CategoryMock'
import { performanceProjectMockList } from '../mock/performance/PerformanceProjectMock'
import { performanceSessionMockList } from '../mock/performance/PerformanceSessionMock'
import { ticketSkuMockList } from '../mock/performance/TicketSkuMock'
import { venueMockList } from '../mock/performance/VenueMock'
import { Category } from '../model/entity/Category'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { TicketSku } from '../model/entity/TicketSku'
import { Venue } from '../model/entity/Venue'
import { ProjectStatus } from '../model/enums/ProjectStatus'
import { SessionStatus } from '../model/enums/SessionStatus'
import { SkuStatus } from '../model/enums/SkuStatus'
import { DateTimeUtil } from './DateTimeUtil'

const ONE_DAY_MILLIS: number = 24 * 60 * 60 * 1000

/**
 * 演出基础数据工具。
 *
 * 说明：
 * 这些方法不是页面业务逻辑，而是多个 Repository 会重复用到的基础数据查找 / 判断逻辑。
 * 当前一期使用 Mock 数据，所以先放在 utils 中复用；后续如果接真实接口，可以再迁移到统一数据服务。
 */
export class PerformanceDataUtil {
  static normalizeCityName(cityName: string | undefined): string {
    let realCityName: string = cityName === undefined ? '' : cityName.trim()

    if (realCityName.endsWith('市')) {
      realCityName = realCityName.substring(0, realCityName.length - 1)
    }

    return realCityName
  }

  static getCategoryName(categoryId: string): string {
    const category: Category | undefined = categoryMockList.find((item: Category) => {
      return item.categoryId === categoryId
    })

    return category?.categoryName ?? ''
  }

  static findProject(projectId: string): PerformanceProject | undefined {
    return performanceProjectMockList.find((project: PerformanceProject) => {
      return project.projectId === projectId
    })
  }

  static findVisibleProject(projectId: string): PerformanceProject | undefined {
    return performanceProjectMockList.find((project: PerformanceProject) => {
      return project.projectId === projectId && PerformanceDataUtil.isProjectVisible(project)
    })
  }

  static isProjectVisible(project: PerformanceProject): boolean {
    return project.projectStatus !== ProjectStatus.OFFLINE
  }

  static isSessionVisible(session: PerformanceSession): boolean {
    return session.sessionStatus !== SessionStatus.OFFLINE
  }

  static findVisibleSessionsByProjectId(projectId: string): PerformanceSession[] {
    return performanceSessionMockList
      .filter((session: PerformanceSession) => {
        return session.projectId === projectId && PerformanceDataUtil.isSessionVisible(session)
      })
      .sort((a: PerformanceSession, b: PerformanceSession) => {
        return PerformanceDataUtil.compareSessionStartTimeAsc(a, b)
      })
  }

  static findVisibleSessionById(projectId: string, sessionId: string): PerformanceSession | undefined {
    return performanceSessionMockList.find((session: PerformanceSession) => {
      return session.projectId === projectId &&
        session.sessionId === sessionId &&
        PerformanceDataUtil.isSessionVisible(session)
    })
  }

  static findVisibleSession(sessionId: string): PerformanceSession | undefined {
    return performanceSessionMockList.find((session: PerformanceSession) => {
      return session.sessionId === sessionId && PerformanceDataUtil.isSessionVisible(session)
    })
  }

  static findSession(sessionId: string): PerformanceSession | undefined {
    return performanceSessionMockList.find((session: PerformanceSession) => {
      return session.sessionId === sessionId
    })
  }

  static findVenue(venueId: string): Venue | undefined {
    return venueMockList.find((venue: Venue) => {
      return venue.venueId === venueId
    })
  }

  static getVenueName(venueId: string): string {
    const venue: Venue | undefined = PerformanceDataUtil.findVenue(venueId)
    return venue?.venueName ?? ''
  }

  static getVenueAddress(venueId: string): string {
    const venue: Venue | undefined = PerformanceDataUtil.findVenue(venueId)
    return venue?.address ?? ''
  }

  static findSku(skuId: string): TicketSku | undefined {
    return ticketSkuMockList.find((sku: TicketSku) => sku.skuId === skuId)
  }

  static getTicketSkusBySessionId(sessionId: string): TicketSku[] {
    return ticketSkuMockList
      .filter((sku: TicketSku) => sku.sessionId === sessionId)
      .sort((a: TicketSku, b: TicketSku) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))
  }

  static hasAvailableSku(sessionId: string): boolean {
    const sku: TicketSku | undefined = ticketSkuMockList.find((item: TicketSku) => {
      return item.sessionId === sessionId && PerformanceDataUtil.isSkuAvailable(item)
    })

    return sku !== undefined
  }

  static isSkuAvailable(sku: TicketSku): boolean {
    return sku.skuStatus !== SkuStatus.SOLD_OUT && sku.stockAvailable > 0
  }

  static matchFilterTime(session: PerformanceSession, filterTime: string | undefined, baseTime: string): boolean {
    if (filterTime === undefined || filterTime.length === 0) {
      return true
    }

    if (filterTime === 'NEXT_30_DAYS') {
      return PerformanceDataUtil.isSessionInNextDays(session, baseTime, 30)
    }

    if (filterTime === 'NEXT_7_DAYS') {
      return PerformanceDataUtil.isSessionInNextDays(session, baseTime, 7)
    }

    return session.startTime.startsWith(filterTime)
  }

  static matchSearchKeyword(project: PerformanceProject, session: PerformanceSession, lowerKeyword: string): boolean {
    const categoryName: string = PerformanceDataUtil.getCategoryName(project.categoryId)
    const venueName: string = PerformanceDataUtil.getVenueName(session.venueId)

    return project.title.toLowerCase().includes(lowerKeyword) ||
      categoryName.toLowerCase().includes(lowerKeyword) ||
      session.cityName.toLowerCase().includes(lowerKeyword) ||
      venueName.toLowerCase().includes(lowerKeyword)
  }

  static getSearchScore(
    title: string,
    categoryName: string,
    cityName: string,
    venueName: string,
    lowerKeyword: string
  ): number {
    if (title.toLowerCase().includes(lowerKeyword)) {
      return 4
    }

    if (categoryName.toLowerCase().includes(lowerKeyword)) {
      return 3
    }

    if (cityName.toLowerCase().includes(lowerKeyword)) {
      return 2
    }

    if (venueName.toLowerCase().includes(lowerKeyword)) {
      return 1
    }

    return 0
  }

  static getProjectHotScore(project: PerformanceProject | undefined): number {
    if (project === undefined) {
      return 0
    }

    return project.hotScore ?? project.wantCount
  }

  static compareSessionStartTimeAsc(a: PerformanceSession, b: PerformanceSession): number {
    return DateTimeUtil.toTimeMillis(a.startTime) - DateTimeUtil.toTimeMillis(b.startTime)
  }

  static compareProjectPublishTimeDesc(projectA: PerformanceProject | undefined, projectB: PerformanceProject | undefined): number {
    return DateTimeUtil.toTimeMillis(projectB?.publishTime) - DateTimeUtil.toTimeMillis(projectA?.publishTime)
  }

  private static isSessionInNextDays(session: PerformanceSession, baseTime: string, days: number): boolean {
    const nowMillis: number = DateTimeUtil.toTimeMillis(baseTime)
    const sessionMillis: number = DateTimeUtil.toTimeMillis(session.startTime)
    const endMillis: number = nowMillis + days * ONE_DAY_MILLIS
    return sessionMillis >= nowMillis && sessionMillis <= endMillis
  }
}
