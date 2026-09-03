import { TicketStatus } from "../../enums/TicketStatus"

export interface TicketFolderPageVO {
  tickets: TicketFolderItemVO[]
}

export interface TicketFolderItemVO {
  orderId: string
  projectId?: string
  sessionId?: string
  projectStatus?: string
  sessionStatus?: string

  /** WAIT_USE / REFUNDING / FINISHED / REFUND_SUCCESS */
  orderStatus?: string

  /** 默认打开的电子票ID */
  ticketId?: string

  posterUrl: string
  projectTitle: string
  startTime: string
  venueName: string
  venueAddress: string

  /** ETICKET / PAPER_TICKET */
  deliveryType: string
  /** PAPERLESS / EXPRESS / SELF_PICKUP */
  deliveryMode?: string

  /** 订单中的票张数 */
  ticketCount: number

  /** 票档名称 */
  skuName: string

  /**
   * 票夹卡片展示状态
   */
  displayStatus: 'UNUSED' | 'UNAVAILABLE'

  /** 真实票状态，可辅助前端判断 */
  ticketStatus: TicketStatus

}
