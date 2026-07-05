import { RefundRule } from '../../model/entity/RefundRule'
import { RefundType } from '../../model/enums/RefundType'

export const refundRuleMock: RefundRule[] = [
  {
    refundRuleId: 'refund_rule_1001',
    projectId: 'proj_1001',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 72 小时以上免手续费，24 小时以上收取 20% 手续费，开演前 24 小时内不支持退款。',
    stages: [
      {
        beforeStartHours: 72,
        feeRate: 0
      },
      {
        beforeStartHours: 24,
        feeRate: 0.2
      }
    ]
  },
  {
    refundRuleId: 'refund_rule_1002',
    projectId: 'proj_1002',
    refundType: RefundType.NO_REFUND,
    ruleText: '本项目支付成功后不支持主动退款。'
  },
  {
    refundRuleId: 'refund_rule_1003',
    projectId: 'proj_1003',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 48 小时以上免手续费，24 小时以上收取 30% 手续费，开演前 24 小时内不支持退款。',
    stages: [
      {
        beforeStartHours: 48,
        feeRate: 0
      },
      {
        beforeStartHours: 24,
        feeRate: 0.3
      }
    ]
  },
  {
    refundRuleId: 'refund_rule_1004',
    projectId: 'proj_1004',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 24 小时以上免手续费，开演前 24 小时内不支持退款。',
    stages: [
      {
        beforeStartHours: 24,
        feeRate: 0
      }
    ]
  },
  {
    refundRuleId: 'refund_rule_1005',
    projectId: 'proj_1005',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 24 小时以上免手续费，开演前 24 小时内不支持退款。',
    stages: [
      {
        beforeStartHours: 24,
        feeRate: 0
      }
    ]
  },
  {
    refundRuleId: 'refund_rule_1006',
    projectId: 'proj_1006',
    refundType: RefundType.NO_REFUND,
    ruleText: '本项目支付成功后不支持主动退款。'
  },
  {
    refundRuleId: 'refund_rule_1007',
    projectId: 'proj_1007',
    refundType: RefundType.NO_REFUND,
    ruleText: '本项目支付成功后不支持主动退款。'
  },
  {
    refundRuleId: 'refund_rule_1008',
    projectId: 'proj_1008',
    refundType: RefundType.NO_REFUND,
    ruleText: '本项目支付成功后不支持主动退款。'
  }
]