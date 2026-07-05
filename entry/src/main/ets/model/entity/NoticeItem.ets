/**
 * 观演须知实体
 *
 * 注解：
 * 观演须知是项目级或平台默认配置事实。
 * 页面卡片展示需要的 icon/title/description/sortOrder 均来自该配置。
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

  /** 须知展示顺序 */
  sortOrder: number
}
