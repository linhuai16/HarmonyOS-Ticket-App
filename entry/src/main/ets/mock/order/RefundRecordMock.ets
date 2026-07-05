import { RefundRecord } from '../../model/entity/RefundRecord'

export const refundRecordMockList: RefundRecord[] = [
  {
    refundId: 'refund_001',
    orderId: 'order_004',
    refundAmount: 268,
    feeAmount: 0,
    status: 'REFUND_SUCCESS',
    refundTime: '2026-05-26 09:30:00'
  }
]
