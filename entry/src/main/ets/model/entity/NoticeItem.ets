/**
 * 观演须知实体。
 *
 * 说明：
 * NoticeItem 是观演须知字典配置，只保存须知项自身的稳定信息。
 * 须知是否属于某个项目、在该项目下的展示顺序，放在项目-观演须知关系数据中维护；
 * 不在 NoticeItem 实体中保存 projectId / categoryId / sortOrder 等关联字段。
 */
export interface NoticeItem {
  /** 须知项ID */
  noticeId: string

  /** 须知标题 */
  title: string

  /** 须知图标资源名 */
  iconUrl: string

  /** 须知说明 */
  description: string
}
