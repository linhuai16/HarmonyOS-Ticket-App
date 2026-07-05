import { RefundRule } from '../../model/entity/RefundRule'
import { RefundType } from '../../model/enums/RefundType'

export const refundRuleMockList: RefundRule[] = [
  {
    refundRuleId: 'refund_rule_1001',
    projectId: 'proj_1001',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '开演前 72 小时以上可退，按规则收取手续费。',
    stages: [{ beforeStartHours: 168, feeRate: 0 }, { beforeStartHours: 72, feeRate: 0.2 },
      { beforeStartHours: 24, feeRate: 0.5 }]
  },
  {
    refundRuleId: 'refund_rule_1002',
    projectId: 'proj_1002',
    refundType: RefundType.NO_REFUND,
    ruleText: '本项目为不可退项目，请确认后购买。'
  },
  {
    refundRuleId: 'refund_rule_1003',
    projectId: 'proj_1003',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '开演前 24 小时以上可退，扣除 20% 手续费。',
    stages: [{ beforeStartHours: 24, feeRate: 0.2 }]
  }
]
