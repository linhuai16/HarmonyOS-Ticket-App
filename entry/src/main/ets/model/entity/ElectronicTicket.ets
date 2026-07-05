import { TicketStatus } from "../enums/TicketStatus"

/**
 * 电子票
 *
 * 注解：
 * 一张票对应一个入场凭证。
 * 一个订单买多张票，会生成多条电子票记录。
 *
 * 字段优化说明：
 * - userId 可通过 orderId -> Order.userId 获取，不在电子票实体中重复保存。
 * - ticketIndex / ticketTotal 属于页面展示序号，由 TicketRepository 组装 VO 时计算。
 */
export interface ElectronicTicket {
  /** 电子票ID */
  ticketId: string

  /** 所属订单ID */
  orderId: string

  /** 所属订单项ID */
  orderItemId: string

  /** 绑定观演人快照ID；一张票对应一个下单观演人快照 */
  orderAudienceId: string

  /** 票状态 */
  ticketStatus: TicketStatus

  /** 二维码地址或二维码内容 */
  qrCodeValue?: string

  /** 座位信息 */
  seatInfo?: string

  /** 电子票生成时间 */
  generateTime?: string

  /** 检票时间 */
  checkTime?: string

  /** 失效时间 */
  expireTime?: string

  /** 异常原因，如二维码获取失败 */
  abnormalReason?: string
}
