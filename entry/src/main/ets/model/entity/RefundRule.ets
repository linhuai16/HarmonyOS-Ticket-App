import { RefundType } from "../enums/RefundType"

/**
 * 退款规则实体
 *
 * 注解：
 * 一期退款规则按项目配置。
 * 用户主动退款时，系统根据 projectId 找到对应规则，再结合演出开始时间计算手续费。
 */
export interface RefundRule {
  /** 退款规则ID */
  refundRuleId: string

  /** 适用项目ID */
  projectId: string

  /** 退款类型：条件退 / 不可退 */
  refundType: RefundType

  /** 规则说明，前端展示 */
  ruleText: string

  /** 条件退阶梯规则；不可退项目可以不配置 */
  stages?: RefundStage[]
}

export interface RefundStage {
  /** 开演前多少小时以上 */
  beforeStartHours: number

  /** 手续费比例，如 0.2 表示扣 20% */
  feeRate: number
}
