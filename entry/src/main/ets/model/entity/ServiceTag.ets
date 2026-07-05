/**
 * 演出服务标签实体
 *
 * 注解：
 * 服务标签是项目级配置事实，用于说明项目购票服务能力。
 * Page 所需展示 VO 仍由 Repository 从该实体组装。
 */
export interface ServiceTag {
  /** 服务标签ID */
  tagId: string

  /** 服务标签名称，如实名制购票、电子票、条件退 */
  tagName: string

  /** 服务标签图标资源名 */
  iconUrl: string

  /** 服务标签说明，用于点击标签后的说明弹窗 */
  description: string

  /** 标签展示顺序 */
  sortOrder: number
}
