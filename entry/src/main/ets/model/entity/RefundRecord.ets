import { RefundStatus } from '../enums/RefundStatus'

/**
 * 退款记录。
 *
 * 说明：
 * 1. RefundRecord 只记录退款交易本身的业务事实。
 * 2. 用户、项目、场次、订单明细等信息通过 orderId -> Order / OrderItem 获取，不在退款记录中重复保存。
 * 3. refundAmount / feeAmount 是退款申请生成时的金额快照，后续规则变化不影响历史记录。
 */
export interface RefundRecord {
  /** 退款记录主键 */
  refundId: string

  /** 所属订单ID */
  orderId: string

  /** 退款申请时间；系统自动退款时取系统发起退款的时间 */
  applyTime: string

  /** 退款原因；用户主动退款时来自申请页，系统自动退款时记录系统原因 */
  reason?: string

  /** 实际退款金额快照 */
  refundAmount: number

  /** 手续费快照，0 表示无手续费 */
  feeAmount: number

  /** 退款状态 */
  refundStatus: RefundStatus

  /** 退款完成时间，仅退款成功后写入 */
  refundTime?: string
}
