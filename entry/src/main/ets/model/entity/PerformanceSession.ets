import { DeliveryType } from "../enums/DeliveryType"
import { SessionStatus } from "../enums/SessionStatus"

/**
 * 演出场次 / 城市站点
 * 注解：
 * 表示某个演出项目在某个城市、某个场馆、某个时间的一场演出。
 * 场馆名称、地址、经纬度由 venueId 关联 Venue 后组装到 VO。
 */
export interface PerformanceSession {
  /** 本系统场次ID */
  sessionId: string

  /** 所属演出项目ID */
  projectId: string

  /** 城市名称 */
  cityName: string

  /** 站点名称，如上海站、北京站 */
  stationName: string

  /** 场馆ID */
  venueId: string

  /** 演出开始时间 */
  startTime: string

  /** 演出结束时间 */
  endTime?: string

  /** 开售时间 */
  saleStartTime?: string

  /** 停售时间 */
  saleEndTime?: string

  /** 出票提前小时数：用于计算预计出票时间 */
  issueOffsetHours?: number

  /**
   * 场次状态
   * 注解：
   * 真正控制详情页按钮。
   */
  sessionStatus: SessionStatus

  /** 当前站点最低价缓存；列表/详情高频展示，必要时可由 TicketSku 重新计算 */
  minPrice?: number

  /** 当前站点最高价缓存；列表/详情高频展示，必要时可由 TicketSku 重新计算 */
  maxPrice?: number

  /** 每单限购数量 */
  limitPerOrder: number

  /** 当前站点详情内容；为空时使用项目默认详情 */
  stationDetailContent?: string

  /** 当前场次配送方式 */
  deliveryType: DeliveryType
}
