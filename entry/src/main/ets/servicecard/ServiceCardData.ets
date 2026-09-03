export class ServiceCardTarget {
  static readonly HOME: string = 'HOME'
  static readonly LOGIN: string = 'LOGIN'
  static readonly ORDER_DETAIL: string = 'ORDER_DETAIL'
  static readonly TICKET_DETAIL: string = 'TICKET_DETAIL'
  static readonly PERFORMANCE_DETAIL: string = 'PERFORMANCE_DETAIL'
}

export class ServiceCardData {
  statusCode: string = 'LOADING'
  statusText: string = '正在更新'
  title: string = '麦麦票务'
  primaryText: string = '正在获取真实票务数据'
  secondaryText: string = ''
  actionText: string = '打开应用'
  target: string = ServiceCardTarget.HOME
  userId: string = ''
  orderId: string = ''
  ticketId: string = ''
  projectId: string = ''
  sessionId: string = ''
  posterUrl: string = ''
  updatedText: string = ''
  payRemainingMillis: number = 0
  payExpireTimestamp: number = 0
}
