import { SessionStatus } from "../../enums/SessionStatus"


export interface PerformanceDetailVO {
  /** 演出项目ID */
  projectId: string

  /** 默认选中的场次ID */
  selectedSessionId: string

  /** 演出海报竖图 */
  posterUrl: string

  /** 演出名称 */
  title: string

  /** 演出类型 */
  categoryName: string

  /** 价格区间 */
  minPrice?: number
  maxPrice?: number

  /** 当前用户是否已想看 */
  isWanted: boolean

  /** 巡演城市站点列表 */
  sessions: PerformanceSessionItemVO[]

  /** 当前选中场次的场馆信息 */
  venue: VenueDisplayVO

  /** 演出服务标签 */
  serviceTags: ServiceTagVO[]

  /** 演出详情内容 */
  detailContent?: string

  /** 观演须知 */
  noticeItems: NoticeItemVO[]

}

export interface NoticeItemVO {
  noticeId: string
  title: string
  iconUrl?: string
  description: string
}

export interface PerformanceSessionItemVO {
  sessionId: string
  cityName: string
  stationName: string
  startTime: string
  sessionStatus: SessionStatus
}

export interface VenueDisplayVO {
  venueId: string
  venueName: string
  venueAddress: string
  longitude?: number
  latitude?: number
}
export interface ServiceTagVO {
  tagId: string
  tagName: string
  description?: string
  detailItems?: string[]
}
