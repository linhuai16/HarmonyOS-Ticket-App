import { SessionStatus } from '../../enums/SessionStatus'

export enum PerformanceSortType {
  HOT = 'HOT',
  NEW = 'NEW'
}

export class CategoryPerformanceItemVO {
  projectId: string = ''
  sessionId: string = ''
  posterUrl: string = ''
  categoryName: string = ''
  title: string = ''
  sessionStatus: SessionStatus = SessionStatus.ON_SALE
  startTime: string = ''
  cityName: string = ''
  venueName: string = ''
  minPrice?: number
}

export class CategoryPageVO {
  currentCityName: string = ''
  performanceList: CategoryPerformanceItemVO[] = []
  hasMore: boolean = false
  total: number = 0
  limit: number = 0
  offset: number = 0
}
