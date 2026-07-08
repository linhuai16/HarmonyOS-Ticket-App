import { RefundRecord } from '../../model/entity/RefundRecord'
import { RefundStatus } from '../../model/enums/RefundStatus'

export const refundRecordMockList: RefundRecord[] = [
  {
    refundId: 'refund_001',
    orderId: 'order_004',
    applyTime: '2026-05-25 18:20:00',
    reason: '行程变更，无法到场',
    refundAmount: 268,
    feeAmount: 0,
    refundStatus: RefundStatus.REFUND_SUCCESS,
    refundTime: '2026-05-26 09:30:00'
  }
]
