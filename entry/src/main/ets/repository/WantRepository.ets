import {
  WantListPageVO,
  WantPerformanceItemVO
} from '../model/vo/want/WantListPageVO'

import { WantRecord } from '../model/entity/WantRecord'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { PerformanceDataUtil } from '../utils/PerformanceDataUtil'
import { WantDataUtil } from '../utils/WantDataUtil'

/**
 * 想看 Repository。
 *
 * 对外保留想看列表、添加想看、取消想看、想看状态判断；
 * 基础查找、时间排序、默认场次选择、想看数量维护统一复用 WantDataUtil / PerformanceDataUtil。
 */
export class WantRepository {
  getWantList(userId: string): WantListPageVO {
    const items: WantPerformanceItemVO[] = []

    WantDataUtil.getUserWantRecords(userId).forEach((want: WantRecord) => {
      const item: WantPerformanceItemVO | undefined = this.buildWantPerformanceItemVO(want)

      if (item !== undefined) {
        items.push(item)
      }
    })

    return {
      items: items
    }
  }

  addWant(userId: string, projectId: string): boolean {
    if (userId.trim().length === 0 || projectId.trim().length === 0) {
      return false
    }

    const project: PerformanceProject | undefined = PerformanceDataUtil.findProject(projectId)

    if (!WantDataUtil.canAddWant(project)) {
      return false
    }

    if (WantDataUtil.isWanted(userId, projectId)) {
      return true
    }

    WantDataUtil.addWantRecord(userId, projectId)

    if (project !== undefined) {
      WantDataUtil.increaseProjectWantCount(project)
    }

    return true
  }

  cancelWant(userId: string, projectId: string): boolean {
    if (userId.trim().length === 0 || projectId.trim().length === 0) {
      return false
    }

    const index: number = WantDataUtil.findWantRecordIndex(userId, projectId)

    if (index < 0) {
      return false
    }

    WantDataUtil.removeWantRecordAt(index)
    WantDataUtil.decreaseProjectWantCount(PerformanceDataUtil.findProject(projectId))

    return true
  }

  isWanted(userId: string, projectId: string): boolean {
    if (userId.trim().length === 0 || projectId.trim().length === 0) {
      return false
    }

    return WantDataUtil.isWanted(userId, projectId)
  }

  private buildWantPerformanceItemVO(want: WantRecord): WantPerformanceItemVO | undefined {
    const project: PerformanceProject | undefined = PerformanceDataUtil.findProject(want.projectId)

    if (!WantDataUtil.canAddWant(project)) {
      return undefined
    }

    if (project === undefined) {
      return undefined
    }

    const session: PerformanceSession | undefined = WantDataUtil.findDefaultVisibleSession(project.projectId)

    if (session === undefined) {
      return undefined
    }

    return {
      wantId: want.wantId,
      projectId: project.projectId,
      sessionId: session.sessionId,
      posterUrl: project.posterUrl,
      categoryName: PerformanceDataUtil.getCategoryName(project.categoryId),
      title: project.title,
      startTime: session.startTime,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      minPrice: session.minPrice ?? project.minPrice,
      projectStatus: project.projectStatus,
      sessionStatus: session.sessionStatus
    }
  }
}
