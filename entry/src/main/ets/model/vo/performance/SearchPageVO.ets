export interface SearchPageVO {
  /** 搜索历史列表，后端返回全部；前端默认展示前3行，点击展开后展示全部 */
  histories: SearchHistoryItemVO[]

}

export interface SearchHistoryItemVO {
  /** 搜索历史ID */
  historyId: string

  /** 搜索关键词 */
  keyword: string
}

export interface SearchResultPageVO {
  /** 搜索关键词 */
  keyword: string

  /** 搜索结果列表 */
  resultList: SearchResultItemVO[]


  /** 是否还有更多，用于下拉加载更多 */
  hasMore: boolean
}

export interface SearchResultItemVO {
  /** 演出项目ID */
  projectId: string

  /** 场次ID */
  sessionId: string

  /** 海报图 */
  posterUrl: string

  /** 演出类型 */
  categoryName: string

  /** 演出标题 */
  title: string

  /** 演出时间 */
  startTime: string

  /** 城市名称 */
  cityName: string

  /** 场馆名称 */
  venueName: string

  /** 最低价 */
  minPrice?: number

  /** 最高价 */
  maxPrice?: number
}