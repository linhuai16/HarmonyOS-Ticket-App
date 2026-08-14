/**
 * 条件退阶梯规则实体。
 *
 * 说明：
 * 1. 只描述 RefundRule 下的一条阶梯明细，不放入 RefundRule.stages 嵌套数组。
 * 2. 后续接数据库时，可对应 refund_rule_stage 表。
 */
export interface RefundRuleStage {
  /** 阶梯规则ID */
  stageId: string

  /** 所属退款规则ID */
  refundRuleId: string

  /** 距离开演至少多少分钟，包含该值 */
  minBeforeStartMinutes: number

  /** 距离开演小于多少分钟，空表示无上限 */
  maxBeforeStartMinutes?: number

  /** 手续费比例，如 0.2 表示扣 20% */
  feeRate: number

  /** 同一退款规则下的展示排序 */
  sortOrder: number
}
