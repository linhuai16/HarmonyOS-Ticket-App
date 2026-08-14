import { RefundStatus } from '../../enums/RefundStatus'

export interface RefundProgressVO {
  refundId: string
  orderId: string
  refundStatus: RefundStatus
  refundAmount: number
  feeAmount: number
  applyTime?: string
  refundTime?: string
  failReason?: string
}
