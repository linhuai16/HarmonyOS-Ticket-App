import {
  WantListPageVO,
  WantPerformanceItemVO
} from '../model/vo/want/WantListPageVO'
import { ProjectStatus } from '../model/enums/ProjectStatus'
import { SessionStatus } from '../model/enums/SessionStatus'
import { ApiClient } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

interface BackendWantListPageVO {
  wants?: BackendWantItemVO[]
  items?: BackendWantItemVO[]
}

interface BackendWantItemVO {
  wantId: number | string
  projectId: number | string
  sessionId?: number | string
  posterUrl: string
  categoryName: string
  title: string
  startTime?: string
  venueName?: string
  minPrice?: number
  projectStatus?: string
  sessionStatus?: string
}

interface WantActionResponse {
  success: boolean
  isWanted?: boolean
}

/** 想看 Repository：从 SpringBoot 接口读写，不再使用 Mock。 */
export class WantRepository {
  async getWantList(userId: string): Promise<WantListPageVO> {
    if (userId.length === 0) {
      return { items: [] }
    }

    const response: BackendWantListPageVO =
      await ApiClient.get<BackendWantListPageVO>('/api/users/' + encodeURIComponent(userId) + '/wants')

    const rawItems: BackendWantItemVO[] = response.items ?? response.wants ?? []
    const items: WantPerformanceItemVO[] = rawItems.map((item: BackendWantItemVO): WantPerformanceItemVO => {
      return {
        wantId: String(item.wantId),
        projectId: String(item.projectId),
        sessionId: item.sessionId === undefined ? '' : String(item.sessionId),
        posterUrl: item.posterUrl,
        categoryName: item.categoryName,
        title: item.title,
        startTime: item.startTime ?? '',
        venueName: item.venueName ?? '',
        minPrice: item.minPrice,
        projectStatus: (item.projectStatus ?? ProjectStatus.ON_SALE) as ProjectStatus,
        sessionStatus: (item.sessionStatus ?? SessionStatus.ON_SALE) as SessionStatus
      }
    })

    return { items: items }
  }

  async addWant(userId: string, projectId: string): Promise<boolean> {
    if (userId.length === 0 || projectId.length === 0) {
      return false
    }

    const response: WantActionResponse =
      await ApiClient.post<WantActionResponse>('/api/users/' + encodeURIComponent(userId) + '/wants/' + encodeURIComponent(projectId))

    if (response.success) {
      AppStorageVersionUtil.bumpWantChangedVersion()
      AppStorageVersionUtil.bumpUserCenterChangedVersion()
    }
    return response.success
  }

  async cancelWant(userId: string, projectId: string): Promise<boolean> {
    if (userId.length === 0 || projectId.length === 0) {
      return false
    }

    const response: WantActionResponse =
      await ApiClient.delete<WantActionResponse>('/api/users/' + encodeURIComponent(userId) + '/wants/' + encodeURIComponent(projectId))

    if (response.success) {
      AppStorageVersionUtil.bumpWantChangedVersion()
      AppStorageVersionUtil.bumpUserCenterChangedVersion()
    }
    return response.success
  }
}
