import { RefundType } from "../enums/RefundType"

/**
 * 退款规则主表实体。
 *
 * 说明：
 * 1. 退款规则按项目配置，projectId 必须保留。
 * 2. 条件退阶梯不直接放在 RefundRule.stages 中，避免主实体持有嵌套数组。
 * 3. 后续接数据库时，可对应 refund_rule 表；阶梯明细对应 refund_rule_stage 表。
 */
export interface RefundRule {
  /** 退款规则ID */
  refundRuleId: string

  /** 适用项目ID；不同项目可配置不同退款规则 */
  projectId: string

  /** 退款类型：条件退 / 不可退 */
  refundType: RefundType
}
