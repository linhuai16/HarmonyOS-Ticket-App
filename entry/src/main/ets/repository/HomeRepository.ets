import {
  HomePageVO,
  HomeCategoryVO,
  HomeBannerVO,
  HomeRecommendItemVO
} from '../model/vo/home/HomePageVO'

import { categoryMockList } from '../mock/category/CategoryMock'
import { bannerMockList } from '../mock/banner/BannerMock'
import { performanceProjectMockList } from '../mock/performance/PerformanceProjectMock'
import { performanceSessionMockList } from '../mock/performance/PerformanceSessionMock'
import { Category } from '../model/entity/Category'
import { BannerItem } from '../model/entity/BannerItem'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { ProjectStatus } from '../model/enums/ProjectStatus'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { SessionStatus } from '../model/enums/SessionStatus'
import { DateTimeUtil } from '../utils/DateTimeUtil'
import { PerformanceDataUtil } from '../utils/PerformanceDataUtil'

const MOCK_NOW: string = '2026-06-01 00:00:00'
const RECOMMEND_VISIBLE_DAYS: number = 30
const MAX_BANNER_COUNT: number = 10

/**
 查询有效 Banner
 → 查询首页分类
 → 按综合评分查询推荐演出
 → 推荐演出过滤当前城市、未售空、未来一个月内
 → 返回 HomePageVO
 */
export class HomeRepository {
  getHomeIndex(cityName: string, limit: number = 10, offset: number = 0): HomePageVO {
    const allRecommendList: HomeRecommendItemVO[] = this.buildRecommendList(cityName)
    const pageList: HomeRecommendItemVO[] = this.slicePage(allRecommendList, limit, offset)

    return {
      currentCityName: cityName,
      categories: this.buildHomeCategories(),
      banners: this.buildHomeBanners(),
      recommendList: pageList,
      hasMore: offset + limit < allRecommendList.length
    }
  }

  private buildHomeCategories(): HomeCategoryVO[] {
    return categoryMockList
      .slice()
      .sort((a: Category, b: Category) => a.sortOrder - b.sortOrder)
      .map((item: Category): HomeCategoryVO => {
        return {
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          iconUrl: item.iconUrl
        }
      })
  }

  private buildHomeBanners(): HomeBannerVO[] {
    return bannerMockList
      .slice()
      .filter((banner: BannerItem) => this.isValidBanner(banner))
      .sort((a: BannerItem, b: BannerItem) => a.sortOrder - b.sortOrder)
      .slice(0, MAX_BANNER_COUNT)
      .map((item: BannerItem): HomeBannerVO => {
        return {
          bannerId: item.bannerId,
          imageUrl: item.imageUrl,
          projectId: item.relatedProjectId
        }
      })
  }

  private buildRecommendList(cityName: string): HomeRecommendItemVO[] {
    const result: HomeRecommendItemVO[] = []
    const projects: PerformanceProject[] = performanceProjectMockList
      .slice()
      .filter((project: PerformanceProject) => this.isRecommendProject(project))
      .sort((a: PerformanceProject, b: PerformanceProject) => this.getRecommendScore(b) - this.getRecommendScore(a))

    projects.forEach((project: PerformanceProject) => {
      const session: PerformanceSession | undefined = this.findRecommendSession(project.projectId, cityName)
      if (session === undefined) {
        return
      }

      result.push(this.buildRecommendItem(project, session))
    })

    return result
  }

  private buildRecommendItem(project: PerformanceProject, session: PerformanceSession): HomeRecommendItemVO {
    return {
      projectId: project.projectId,
      sessionId: session.sessionId,
      posterUrl: project.posterUrl,
      categoryName: PerformanceDataUtil.getCategoryName(project.categoryId),
      title: project.title,
      startTime: session.startTime,
      minPrice: session.minPrice ?? project.minPrice
    }
  }

  private findRecommendSession(projectId: string, cityName: string): PerformanceSession | undefined {
    const sessions: PerformanceSession[] = performanceSessionMockList
      .filter((session: PerformanceSession) => {
        return session.projectId === projectId &&
          session.cityName === cityName &&
          this.isSessionRecommendVisible(session) &&
          PerformanceDataUtil.hasAvailableSku(session.sessionId)
      })
      .sort((a: PerformanceSession, b: PerformanceSession) => {
        return PerformanceDataUtil.compareSessionStartTimeAsc(a, b)
      })

    return sessions.length > 0 ? sessions[0] : undefined
  }

  private isRecommendProject(project: PerformanceProject): boolean {
    return project.projectStatus === ProjectStatus.ON_SALE && project.recommendFlag === true
  }

  private isSessionRecommendVisible(session: PerformanceSession): boolean {
    if (session.sessionStatus === SessionStatus.SOLD_OUT ||
      session.sessionStatus === SessionStatus.ENDED ||
      session.sessionStatus === SessionStatus.OFFLINE) {
      return false
    }

    const nowTime: number = DateTimeUtil.toTimeMillis(MOCK_NOW)
    const startTime: number = DateTimeUtil.toTimeMillis(session.startTime)
    const visibleEndTime: number = nowTime + RECOMMEND_VISIBLE_DAYS * 24 * 60 * 60 * 1000

    return startTime >= nowTime && startTime <= visibleEndTime
  }

  private isValidBanner(banner: BannerItem): boolean {
    const nowTime: number = DateTimeUtil.toTimeMillis(MOCK_NOW)
    const startTime: number = DateTimeUtil.toTimeMillis(banner.startTime)
    const endTime: number = DateTimeUtil.toTimeMillis(banner.endTime)

    if (startTime > nowTime || endTime < nowTime) {
      return false
    }

    return performanceProjectMockList.some((item: PerformanceProject) => {
      return item.projectId === banner.relatedProjectId && item.projectStatus !== ProjectStatus.OFFLINE
    })
  }

  private getRecommendScore(project: PerformanceProject): number {
    return project.hotScore ?? project.wantCount
  }

  private slicePage(list: HomeRecommendItemVO[], limit: number, offset: number): HomeRecommendItemVO[] {
    return list.slice(offset, offset + limit)
  }
}
