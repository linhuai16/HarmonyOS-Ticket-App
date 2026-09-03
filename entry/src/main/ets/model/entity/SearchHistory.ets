/**
 * 搜索历史实体。
 *
 * 说明：
 * 1. 一条记录表示某个用户搜索过的一个关键词。
 * 2. 重复搜索同一关键词时，不删除旧记录再新增，而是刷新 lastSearchTime。
 */
export interface SearchHistory {
  /** 搜索记录ID */
  historyId: string

  /** 所属用户ID */
  userId: string

  /** 搜索关键词 */
  keyword: string

  /** 最近一次搜索时间 */
  lastSearchTime: string
}
