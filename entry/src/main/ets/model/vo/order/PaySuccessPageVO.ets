import { DeliveryType } from "../../enums/DeliveryType"
import { PayMethod } from "../../enums/PayMethod"

export interface PaySuccessPageVO {

  /** 支付金额 */
  payAmount: number

  /** 演出信息 */
  performance: PaySuccessPerformanceVO

  /** 订单编号 */
  orderNo: string

  /** 票档信息 */
  skuName: string

  /** 配送方式 */
  deliveryType: DeliveryType

  /** 支付方式 */
  payMethod?: PayMethod

  /** 查看订单按钮需要的订单ID */
  orderId: string
}

export interface PaySuccessPerformanceVO {
  posterUrl: string
  categoryName: string
  projectTitle: string
  startTime: string
  venueAddress: string
}


