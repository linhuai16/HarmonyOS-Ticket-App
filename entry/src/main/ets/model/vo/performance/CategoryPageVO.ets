import { SessionStatus } from "../../enums/SessionStatus"


export interface CategoryPageVO {
  currentCityName: string
  performanceList: CategoryPerformanceItemVO[]
  hasMore: boolean
}
export enum PerformanceSortType {
  /** 热度排序 */
  HOT = 'HOT',

  /** 最新发布时间排序 */
  NEW = 'NEW'
}
export interface CategoryPerformanceItemVO {
  /** 演出项目ID */
  projectId: string

  /** 场次ID */
  sessionId: string

  /** 海报图 */
  posterUrl: string

  /** 演出类型标签 */
  categoryName: string

  /** 演出标题 */
  title: string

  /** 演出状态 */
  sessionStatus: SessionStatus


  /** 演出时间 */
  startTime: string

  /** 城市名称 */
  cityName: string

  /** 场馆名称 */
  venueName: string

  /** 最低价格 */
  minPrice?: number
}