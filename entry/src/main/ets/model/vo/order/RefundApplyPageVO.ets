import { RefundType } from '../../enums/RefundType'

export interface RefundApplyPageVO {
  orderId: string

  projectTitle: string
  posterUrl: string
  startTime: string
  venueName: string
  venueAddress: string

  skuName: string
  quantity: number

  payAmount: number
  estimatedRefundAmount: number
  feeAmount: number

  refundType: RefundType
  refundRuleText: string

  canRefund: boolean
}