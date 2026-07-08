/**
 * 项目-观演须知关系 Mock。
 *
 * 说明：
 * 1. 该文件用于模拟数据库中的 project_notice_item_relation 关联表。
 * 2. 同一演出类型下不同项目可以配置不同须知；不同演出类型也可以配置不同须知。
 * 3. 前端客户端只消费 Repository 聚合后的 VO，不在 Entity 层增加关联实体。
 */
export interface ProjectNoticeItemRelationMock {
  /** 演出项目ID */
  projectId: string

  /** 观演须知ID */
  noticeId: string

  /** 当前项目下该须知的展示顺序 */
  sortOrder: number
}

export const projectNoticeItemRelationMockList: ProjectNoticeItemRelationMock[] = [
  { projectId: 'proj_1001', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1001', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1001', noticeId: 'notice_real_name', sortOrder: 3 },
  { projectId: 'proj_1001', noticeId: 'notice_refund_rule', sortOrder: 4 },
  { projectId: 'proj_1001', noticeId: 'notice_forbidden_items', sortOrder: 5 },
  { projectId: 'proj_1001', noticeId: 'notice_security_check', sortOrder: 6 },

  { projectId: 'proj_1002', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1002', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1002', noticeId: 'notice_child_ticket', sortOrder: 3 },
  { projectId: 'proj_1002', noticeId: 'notice_invoice', sortOrder: 4 },
  { projectId: 'proj_1002', noticeId: 'notice_real_name', sortOrder: 5 },
  { projectId: 'proj_1002', noticeId: 'notice_forbidden_items', sortOrder: 6 },

  { projectId: 'proj_1003', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1003', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1003', noticeId: 'notice_real_name', sortOrder: 3 },
  { projectId: 'proj_1003', noticeId: 'notice_refund_rule', sortOrder: 4 },
  { projectId: 'proj_1003', noticeId: 'notice_forbidden_items', sortOrder: 5 },
  { projectId: 'proj_1003', noticeId: 'notice_security_check', sortOrder: 6 },

  { projectId: 'proj_1004', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1004', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1004', noticeId: 'notice_child_ticket', sortOrder: 3 },
  { projectId: 'proj_1004', noticeId: 'notice_real_name', sortOrder: 4 },
  { projectId: 'proj_1004', noticeId: 'notice_security_check', sortOrder: 5 },

  { projectId: 'proj_1005', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1005', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1005', noticeId: 'notice_real_name', sortOrder: 3 },
  { projectId: 'proj_1005', noticeId: 'notice_forbidden_items', sortOrder: 4 },
  { projectId: 'proj_1005', noticeId: 'notice_security_check', sortOrder: 5 },

  { projectId: 'proj_1006', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1006', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1006', noticeId: 'notice_child_ticket', sortOrder: 3 },
  { projectId: 'proj_1006', noticeId: 'notice_invoice', sortOrder: 4 },
  { projectId: 'proj_1006', noticeId: 'notice_real_name', sortOrder: 5 },

  { projectId: 'proj_1007', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1007', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1007', noticeId: 'notice_child_ticket', sortOrder: 3 },
  { projectId: 'proj_1007', noticeId: 'notice_invoice', sortOrder: 4 },
  { projectId: 'proj_1007', noticeId: 'notice_real_name', sortOrder: 5 },
  { projectId: 'proj_1007', noticeId: 'notice_refund_rule', sortOrder: 6 },

  { projectId: 'proj_1008', noticeId: 'notice_limit_rule', sortOrder: 1 },
  { projectId: 'proj_1008', noticeId: 'notice_entry_method', sortOrder: 2 },
  { projectId: 'proj_1008', noticeId: 'notice_child_ticket', sortOrder: 3 },
  { projectId: 'proj_1008', noticeId: 'notice_invoice', sortOrder: 4 },
  { projectId: 'proj_1008', noticeId: 'notice_real_name', sortOrder: 5 },
  { projectId: 'proj_1008', noticeId: 'notice_forbidden_items', sortOrder: 6 },
  { projectId: 'proj_1008', noticeId: 'notice_security_check', sortOrder: 7 }
]
