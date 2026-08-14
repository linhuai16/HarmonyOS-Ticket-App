import { DeliveryType } from "../../enums/DeliveryType"
import { OrderStatus } from "../../enums/OrderStatus"
import { PayMethod } from "../../enums/PayMethod"

export interface OrderDetailVO {
  orderId: string
  orderNo: string

  orderStatus: OrderStatus

  posterUrl: string
  categoryName: string
  projectTitle: string
  startTime: string
  venueName: string
  venueAddress: string

  orderItems: OrderDetailItemVO[]
  audiences: OrderDetailAudienceVO[]

  deliveryType: DeliveryType
  deliveryMode?: string
  address?: OrderDetailAddressVO

  createTime: string
  payExpireTime?: string
  payTime?: string
  ticketIssuedTime?: string
  cancelTime?: string
  finishTime?: string
  refundTime?: string

  totalAmount: number
  serviceFee?: number
  deliveryFee?: number
  payAmount: number
  payMethod?: PayMethod

  ticketActionType: 'VIEW_TICKET' | 'TICKETING' | 'NONE'
  defaultTicketId?: string

  refundAmount?: number        //退款金额
  refundFeeAmount?: number        //手续费
  projectId: string
  sessionId: string
}

export interface OrderDetailItemVO {
  skuName: string
  unitPrice: number
  quantity: number
  subtotalAmount: number
}

export interface OrderDetailAudienceVO {
  realName: string
  maskedCertificateNo: string
  maskedPhone?: string
}
export interface OrderDetailAddressVO {
  receiverName: string
  receiverPhone: string
  fullAddress: string
}
