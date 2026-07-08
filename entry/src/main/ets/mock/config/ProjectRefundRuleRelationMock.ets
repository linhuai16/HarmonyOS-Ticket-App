/**
 * 项目 - 退款规则关系 Mock
 *
 * 注解：
 * RefundRule 是可复用的规则配置；某个项目使用哪条规则由该关系决定。
 * 后续接数据库时可对应 project_refund_rule 关联表。
 */
export interface ProjectRefundRuleRelationMock {
  projectId: string
  refundRuleId: string
}

export const projectRefundRuleRelationMockList: ProjectRefundRuleRelationMock[] = [
  { projectId: 'proj_1001', refundRuleId: 'refund_rule_1001' },
  { projectId: 'proj_1002', refundRuleId: 'refund_rule_1002' },
  { projectId: 'proj_1003', refundRuleId: 'refund_rule_1003' },
  { projectId: 'proj_1004', refundRuleId: 'refund_rule_1004' },
  { projectId: 'proj_1005', refundRuleId: 'refund_rule_1004' },
  { projectId: 'proj_1006', refundRuleId: 'refund_rule_1002' },
  { projectId: 'proj_1007', refundRuleId: 'refund_rule_1002' },
  { projectId: 'proj_1008', refundRuleId: 'refund_rule_1002' }
]
