import { EnableStatus } from "../enums/EnableStatus"

/**
 * 首页 Banner 配置
 *
 * 注解：
 * Banner 是后台可运营配置项，一期只做首页全局 Banner，不按城市拆分。
 * 点击跳转参数由 Repository 根据 relatedProjectId 组装到 HomeBannerVO。
 */
export interface BannerItem {
  /** Banner ID */
  bannerId: string

  /** 图片资源名 / 图片地址 */
  imageUrl: string

  /** 关联演出项目ID，点击 Banner 进入演出详情页 */
  relatedProjectId: string

  /** 启用状态：用于后台手动上/下线 Banner，不等同于生效时间 */
  enableStatus: EnableStatus

  /** 排序值，数值越小越靠前 */
  sortOrder: number

  /** 生效时间 */
  startTime: string

  /** 失效时间 */
  endTime: string
}
