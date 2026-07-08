import { ProjectStatus } from "../../enums/ProjectStatus"
import { SessionStatus } from "../../enums/SessionStatus"


export interface WantListPageVO {
  items: WantPerformanceItemVO[]
}
export interface WantPerformanceItemVO {
  wantId: string
  projectId: string
  sessionId: string

  posterUrl: string
  categoryName: string
  title: string
  startTime: string
  venueName: string

  minPrice?: number
  /** 项目整体状态 */
  projectStatus: ProjectStatus
  sessionStatus: SessionStatus
}
