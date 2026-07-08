import { DeliveryType } from "../enums/DeliveryType"
import { OrderStatus } from "../enums/OrderStatus"
import { PayMethod } from "../enums/PayMethod"

/**
 * 订单
 * 注解：
 * 表示用户一次购票行为。
 * 订单状态和电子票状态分开。
 */
export interface Order {
  /** 本系统订单ID */
  orderId: string

  /** 订单编号 */
  orderNo: string

  /** 用户ID */
  userId: string

  /** 演出项目ID */
  projectId: string

  /** 场次ID */
  sessionId: string

  /** 订单状态 */
  orderStatus: OrderStatus

  /** 订单总金额 */
  totalAmount: number

  /** 实付金额 */
  payAmount: number

  /** 支付方式 */
  payMethod?: PayMethod

  /** 配送方式 */
  deliveryType: DeliveryType

  /** 下单时间 */
  createTime: string

  /** 支付截止时间 */
  payExpireTime?: string

  /** 支付时间 */
  payTime?: string

  /** 取消时间 */
  cancelTime?: string

  /** 实际出票时间，多张票通常同一批出票 */
  ticketIssuedTime?: string

  /** 完成时间 */
  finishTime?: string
}
