import { RefundRuleStage } from '../../model/entity/RefundRuleStage'

/**
 * 条件退阶梯规则 Mock。
 *
 * 说明：
 * 用 refundRuleId 关联 RefundRuleMock，避免 RefundRule 实体持有 stages 嵌套数组。
 */
export const refundRuleStageMockList: RefundRuleStage[] = [
  {
    stageId: 'refund_stage_1001_01',
    refundRuleId: 'refund_rule_1001',
    beforeStartHours: 72,
    feeRate: 0,
    sortOrder: 1
  },
  {
    stageId: 'refund_stage_1001_02',
    refundRuleId: 'refund_rule_1001',
    beforeStartHours: 24,
    feeRate: 0.2,
    sortOrder: 2
  },
  {
    stageId: 'refund_stage_1003_01',
    refundRuleId: 'refund_rule_1003',
    beforeStartHours: 48,
    feeRate: 0,
    sortOrder: 1
  },
  {
    stageId: 'refund_stage_1003_02',
    refundRuleId: 'refund_rule_1003',
    beforeStartHours: 24,
    feeRate: 0.3,
    sortOrder: 2
  },
  {
    stageId: 'refund_stage_1004_01',
    refundRuleId: 'refund_rule_1004',
    beforeStartHours: 24,
    feeRate: 0,
    sortOrder: 1
  },
  {
    stageId: 'refund_stage_1005_01',
    refundRuleId: 'refund_rule_1005',
    beforeStartHours: 24,
    feeRate: 0,
    sortOrder: 1
  }
]
