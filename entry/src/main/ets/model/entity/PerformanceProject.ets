import { ProjectStatus } from "../enums/ProjectStatus"

/**
 * 演出项目
 * 注解：
 * 表示一个完整演出商品，例如“某歌手巡回演唱会”。
 * 只存项目级通用业务信息，不存具体城市站点的场馆、演出时间、票档库存。
 */
export interface PerformanceProject {
  /** 本系统演出项目ID */
  projectId: string

  /** 演出名称 */
  title: string

  /** 分类ID；分类名称由 Repository 根据 Category 组装到 VO */
  categoryId: string

  /** 主海报，列表页/详情页使用 */
  posterUrl: string

  /** 项目默认详情，可存富文本/HTML/图片JSON */
  detailContent?: string

  /** 项目级最低票价缓存；用于列表/推荐等高频展示，具体场次可用场次价格覆盖 */
  minPrice?: number

  /** 项目级最高票价缓存；用于详情页价格区间，具体场次可用场次价格覆盖 */
  maxPrice?: number

  /** 想看人数 */
  wantCount: number

  /** 热度分，后台计算，用于推荐/热度排序 */
  hotScore?: number

  /**
   * 项目整体状态
   * 注解：
   * 只表示项目是否整体可展示/可售，不代表每个城市站点状态。
   */
  projectStatus: ProjectStatus

  /** 是否首页推荐 */
  recommendFlag?: boolean

  /** 发布时间，用于最新排序 */
  publishTime?: string
}
