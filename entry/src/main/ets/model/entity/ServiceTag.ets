/**
 * 演出服务标签实体。
 *
 * 说明：
 * ServiceTag 是服务标签字典配置，只保存标签自身的稳定信息。
 * 标签是否属于某个项目、在该项目下的展示顺序，放在项目-服务标签关系数据中维护；
 * 不在 ServiceTag 实体中保存 projectId / sortOrder 等关联字段。
 */
export interface ServiceTag {
  /** 服务标签ID */
  tagId: string

  /** 服务标签名称，如实名制购票、电子票、条件退 */
  tagName: string

  /** 服务标签图标资源名 */
  iconUrl?: string

  /** 服务标签说明，用于点击标签后的说明弹窗 */
  description: string

  /** 标签分类 */
  tagType?: string
}
