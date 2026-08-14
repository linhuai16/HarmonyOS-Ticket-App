export interface HomePageVO {
  /** 当前城市 */
  currentCityName: string

  /** 首页分类入口 */
  categories: HomeCategoryVO[]

  /** Banner轮播图 */
  banners: HomeBannerVO[]

  /** 推荐演出列表 */
  recommendList: HomeRecommendItemVO[]

  /** 是否还有更多推荐数据 */
  hasMore: boolean
}
export interface HomeCategoryVO {
  /** 分类ID */
  categoryId: string

  /** 分类名称 */
  categoryName: string

  /** 分类图标 */
  iconUrl?: string
}
export interface HomeBannerVO {
  /** Banner ID */
  bannerId: string

  /** 轮播图地址 */
  imageUrl: string

  /** 关联演出项目ID，点击进入票详情页 */
  projectId: string
}
export interface HomeRecommendItemVO {
  /** 演出项目ID */
  projectId: string

  /** 默认展示场次ID，点击卡片进入详情时使用 */
  sessionId: string

  /** 演出海报 */
  posterUrl: string

  /** 演出类型标签 */
  categoryName: string

  /** 演出标题 */
  title: string

  /** 推荐场次所在城市；首页推荐已不按当前城市过滤 */
  cityName: string

  /** 演出时间 */
  startTime: string

  /** 最低价格，展示“￥xxx 起” */
  minPrice?: number
}