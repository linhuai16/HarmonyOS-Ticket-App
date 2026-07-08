/**
 * 项目-服务标签关系 Mock。
 *
 * 说明：
 * 1. 该文件用于模拟数据库中的 project_service_tag_relation 关联表。
 * 2. 不放在 model/entity 下，因为前端客户端不负责后台配置管理。
 * 3. Repository/Util 通过 projectId + tagId 关联 ServiceTagMock，组装页面 VO。
 */
export interface ProjectServiceTagRelationMock {
  /** 演出项目ID */
  projectId: string

  /** 服务标签ID */
  tagId: string

  /** 当前项目下该标签的展示顺序 */
  sortOrder: number
}

export const projectServiceTagRelationMockList: ProjectServiceTagRelationMock[] = [
  { projectId: 'proj_1001', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1001', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1001', tagId: 'tag_conditional_refund', sortOrder: 3 },

  { projectId: 'proj_1002', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1002', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1002', tagId: 'tag_no_refund', sortOrder: 3 },

  { projectId: 'proj_1003', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1003', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1003', tagId: 'tag_conditional_refund', sortOrder: 3 },

  { projectId: 'proj_1004', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1004', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1004', tagId: 'tag_no_refund', sortOrder: 3 },

  { projectId: 'proj_1005', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1005', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1005', tagId: 'tag_no_refund', sortOrder: 3 },

  { projectId: 'proj_1006', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1006', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1006', tagId: 'tag_no_refund', sortOrder: 3 },

  { projectId: 'proj_1007', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1007', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1007', tagId: 'tag_conditional_refund', sortOrder: 3 },

  { projectId: 'proj_1008', tagId: 'tag_realname', sortOrder: 1 },
  { projectId: 'proj_1008', tagId: 'tag_eticket', sortOrder: 2 },
  { projectId: 'proj_1008', tagId: 'tag_no_refund', sortOrder: 3 }
]
