/**
 * 首页 Banner 配置
 * 注解：
 * 用于首页轮播图后台配置。一期 Banner 只关联演出项目，
 * Page 展示所需的跳转参数由 Repository 根据 relatedProjectId 组装到 VO。
 */
export interface BannerItem {
  /** Banner ID */
  bannerId: string

  /** 图片资源名 / 图片地址 */
  imageUrl: string

  /** 关联演出项目ID，点击 Banner 进入演出详情页 */
  relatedProjectId: string

  /** 排序值，数值越小越靠前 */
  sortOrder: number

  /** 生效时间 */
  startTime: string

  /** 失效时间 */
  endTime: string
}
