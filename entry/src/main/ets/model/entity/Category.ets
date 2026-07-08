/**
 * 演出分类配置
 * 注解：
 * 首页分类入口和分类页筛选使用。
 * 一期分类固定展示，不做后台上/下线控制，因此不添加 enableStatus。
 * 分类名称、图标和排序属于分类配置本身，保留在 Entity 中。
 */
export interface Category {
  /** 分类ID */
  categoryId: string

  /** 分类名称 */
  categoryName: string

  /** 分类图标资源名 */
  iconUrl: string

  /** 排序值，数值越小越靠前 */
  sortOrder: number
}
