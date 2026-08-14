export enum RefundType {
  /** 第三方票源订单用户侧统一业务值：仅支持整单退款。 */
  FULL_ORDER = 'FULL_ORDER',
  /** 条件退 */
  CONDITIONAL_REFUND = 'CONDITIONAL_REFUND',
  /** 不可退 */
  NO_REFUND = 'NO_REFUND'
}
