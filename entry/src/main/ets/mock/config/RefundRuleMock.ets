import { RefundRule } from '../../model/entity/RefundRule'
import { RefundType } from '../../model/enums/RefundType'

/**
 * 项目退款规则 Mock。
 *
 * 说明：
 * RefundRule 只保存规则主信息；条件退阶梯明细放在 RefundRuleStageMock 中，
 * 用 refundRuleId 关联，模拟以后数据库中的 refund_rule + refund_rule_stage 两张表。
 */
export const refundRuleMockList: RefundRule[] = [
  {
    refundRuleId: 'refund_rule_1001',
    projectId: 'proj_1001',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 72 小时以上免手续费，24 小时以上收取 20% 手续费，开演前 24 小时内不支持退款。'
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
    ruleText: '支持条件退。开演前 48 小时以上免手续费，24 小时以上收取 30% 手续费，开演前 24 小时内不支持退款。'
  },
  {
    refundRuleId: 'refund_rule_1004',
    projectId: 'proj_1004',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 24 小时以上免手续费，开演前 24 小时内不支持退款。'
  },
  {
    refundRuleId: 'refund_rule_1005',
    projectId: 'proj_1005',
    refundType: RefundType.CONDITIONAL_REFUND,
    ruleText: '支持条件退。开演前 24 小时以上免手续费，开演前 24 小时内不支持退款。'
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
