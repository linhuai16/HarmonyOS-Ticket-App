import { SessionStatus } from "../../enums/SessionStatus"
import { SkuStatus } from "../../enums/SkuStatus"

export interface TicketSelectPageVO {
  projectId: string

  projectTitle: string

  /** 当前已选场次：由详情页点击立即购票/预订时确定 */
  session: TicketSessionVO

  /** 当前场次下的票档列表 */
  skus: TicketSkuSelectVO[]

  /** 当前场次每单限购数量 */
  limitPerOrder: number
}

export interface TicketSessionVO {
  sessionId: string

  cityName: string

  stationName: string

  venueName: string

  venueAddress: string

  startTime: string

  sessionStatus: SessionStatus
}

export interface TicketSkuSelectVO {
  skuId: string

  skuName: string

  skuDesc?: string

  price: number

  skuStatus: SkuStatus

  /** 可售库存，可选展示或用于按钮置灰 */
  stockAvailable?: number
}
