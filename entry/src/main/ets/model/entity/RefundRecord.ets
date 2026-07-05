/**
 * 退款记录
 *
 * 只记录退款交易本身的业务事实。
 * 订单所属项目、场次等信息可通过 orderId -> Order 获取，不在退款记录中重复保存。
 */
export type RefundRecordStatus = 'REFUNDING' | 'REFUND_SUCCESS' | 'REFUND_FAILED'

export interface RefundRecord {
  /** 退款记录主键 */
  refundId: string
  /** 所属订单 */
  orderId: string
  /** 实际退款金额快照 */
  refundAmount: number
  /** 手续费快照，0 表示无手续费 */
  feeAmount: number
  /** 退款状态 */
  status: RefundRecordStatus
  /** 退款完成时间，仅退款成功后写入 */
  refundTime?: string
}
