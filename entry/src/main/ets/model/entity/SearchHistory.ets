/**
 * 搜索历史
 *
 * 注解：
 * 记录用户搜索过的关键词。
 * Page 需要展示 historyId + keyword；
 * Repository 使用 searchTime 做排序和重复关键词更新时间处理。
 */
export interface SearchHistory {
  /** 搜索记录ID */
  historyId: string

  /** 所属用户ID */
  userId: string

  /** 搜索关键词 */
  keyword: string

  /** 搜索时间 */
  searchTime: string
}
