import { WantRecord } from '../model/entity/WantRecord'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { wantRecordMockList } from '../mock/want/WantRecordMock'
import { ProjectStatus } from '../model/enums/ProjectStatus'
import { DateTimeUtil } from './DateTimeUtil'
import { IdGenerator } from './IdGenerator'
import { PerformanceDataUtil } from './PerformanceDataUtil'

/**
 * 想看数据工具。
 *
 * 说明：
 * WantRepository、演出详情页想看状态都会涉及想看记录查找、默认场次选择、想看数量维护。
 * 这些不是页面逻辑，统一放到 utils 中，避免 Repository 内重复维护 Mock 数据查找规则。
 */
export class WantDataUtil {
  static getUserWantRecords(userId: string): WantRecord[] {
    if (userId.trim().length === 0) {
      return []
    }

    return wantRecordMockList
      .filter((want: WantRecord) => want.userId === userId)
      .sort((a: WantRecord, b: WantRecord) => {
        return DateTimeUtil.toTimeMillis(b.wantTime) - DateTimeUtil.toTimeMillis(a.wantTime)
      })
  }

  static findWantRecord(userId: string, projectId: string): WantRecord | undefined {
    return wantRecordMockList.find((item: WantRecord) => {
      return item.userId === userId && item.projectId === projectId
    })
  }

  static findWantRecordIndex(userId: string, projectId: string): number {
    return wantRecordMockList.findIndex((item: WantRecord) => {
      return item.userId === userId && item.projectId === projectId
    })
  }

  static isWanted(userId: string, projectId: string): boolean {
    return WantDataUtil.findWantRecord(userId, projectId) !== undefined
  }

  static addWantRecord(userId: string, projectId: string): WantRecord {
    const want: WantRecord = {
      wantId: IdGenerator.createWantId(),
      userId: userId,
      projectId: projectId,
      wantTime: DateTimeUtil.now()
    }

    wantRecordMockList.push(want)
    return want
  }

  static removeWantRecordAt(index: number): void {
    if (index >= 0 && index < wantRecordMockList.length) {
      wantRecordMockList.splice(index, 1)
    }
  }

  static canAddWant(project: PerformanceProject | undefined): boolean {
    return project !== undefined && project.projectStatus !== ProjectStatus.OFFLINE
  }

  static findDefaultVisibleSession(projectId: string): PerformanceSession | undefined {
    const sessions: PerformanceSession[] = PerformanceDataUtil.findVisibleSessionsByProjectId(projectId)

    if (sessions.length === 0) {
      return undefined
    }

    return sessions[0]
  }

  static increaseProjectWantCount(project: PerformanceProject): void {
    project.wantCount = project.wantCount + 1
  }

  static decreaseProjectWantCount(project: PerformanceProject | undefined): void {
    if (project !== undefined && project.wantCount > 0) {
      project.wantCount = project.wantCount - 1
    }
  }
}
