export class SearchHistoryItemVO {
  historyId: string = ''
  keyword: string = ''
}

export class SearchPageVO {
  histories: SearchHistoryItemVO[] = []
}

export class SearchResultItemVO {
  projectId: string = ''
  sessionId: string = ''
  posterUrl: string = ''
  categoryName: string = ''
  title: string = ''
  startTime: string = ''
  cityName: string = ''
  venueName: string = ''
  minPrice?: number
  maxPrice?: number
}

export class SearchResultPageVO {
  keyword: string = ''
  resultList: SearchResultItemVO[] = []
  hasMore: boolean = false
  total: number = 0
  limit: number = 0
  offset: number = 0
}
