import { DeliveryType } from "../../enums/DeliveryType"
import { ServiceTagVO } from "../performance/PerformanceDetailVO"

export interface SubmitOrderPageVO {
  /** 支付倒计时提示 */
  payExpireMinutes: number

  /** 演出信息 */
  performance: SubmitOrderPerformanceVO

  /** 票品信息 */
  orderItems: SubmitOrderItemVO[]

  /** 演出服务标签 */
  serviceTags: ServiceTagVO[]

  /** 可选择观演人数 */
  requiredAudienceCount: number

  /** 价格明细 */
  priceDetail: SubmitOrderPriceDetailVO

  /** 当前订单配送方式，由场次/票品规则决定，不由用户自由选择 */
  deliveryType: DeliveryType
}

export interface SubmitOrderPerformanceVO {
  projectId: string
  sessionId: string
  projectTitle: string
  venueName: string
  venueAddress: string
  startTime: string
}
export interface SubmitOrderItemVO {
  skuId: string
  skuName: string
  unitPrice: number
  quantity: number
}
export interface SubmitOrderAudienceVO {
  audienceId: string
  realName: string

  /** 脱敏证件号 */
  maskedCertificateNo: string

}
export interface SubmitOrderAddressVO {
  addressId: string
  receiverName: string
  receiverPhone: string
  fullAddress: string
}
export interface SubmitOrderPriceDetailVO {
  ticketAmount: number
  serviceFee?: number
  deliveryFee?: number
  discountAmount?: number
  totalAmount: number
  payAmount: number
}
