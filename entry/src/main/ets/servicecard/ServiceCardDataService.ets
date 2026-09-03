import { common } from '@kit.AbilityKit'
import { HomeRecommendItemVO } from '../model/vo/home/HomePageVO'
import { OrderListItemVO } from '../model/vo/order/OrderListPageVO'
import { OrderDetailVO } from '../model/vo/order/OrderDetailVO'
import { TicketFolderItemVO } from '../model/vo/ticket/TicketFolderPageVO'
import { HomeRepository } from '../repository/HomeRepository'
import { OrderListTab, OrderRepository } from '../repository/OrderRepository'
import { TicketRepository } from '../repository/TicketRepository'
import { MediaResourceUtil } from '../common/MediaResourceUtil'
import { ServiceCardData, ServiceCardTarget } from './ServiceCardData'
import { ServiceCardPolicy } from './ServiceCardPolicy'
import { ServiceCardStore } from './ServiceCardStore'

export class ServiceCardDataService {
  private orderRepository: OrderRepository = new OrderRepository()
  private ticketRepository: TicketRepository = new TicketRepository()
  private homeRepository: HomeRepository = new HomeRepository()

  async load(context: common.Context): Promise<ServiceCardData> {
    const userId: string = ServiceCardStore.getUserId(context)
    const token: string = ServiceCardStore.getToken(context)
    const owner: string = userId.length > 0 && token.length > 0 ? userId : 'guest'
    try {
      let data: ServiceCardData
      if (owner !== 'guest') {
        data = await this.loadUserPriorityData(userId, context)
      } else {
        data = await this.loadGuestData(context)
      }
      data.updatedText = this.buildUpdatedText()
      ServiceCardStore.saveLastData(context, owner, data)
      return data
    } catch (error) {
      const cached: ServiceCardData | undefined = ServiceCardStore.getLastData(context, owner)
      if (cached !== undefined) {
        cached.updatedText = '离线数据 · ' + cached.updatedText
        return cached
      }
      const data: ServiceCardData = this.buildOfflineData(owner !== 'guest', userId)
      return data
    }
  }

  private async loadUserPriorityData(userId: string, context: common.Context): Promise<ServiceCardData> {
    const waitPayOrders: OrderListItemVO[] =
      (await this.orderRepository.getOrderList(userId, OrderListTab.WAIT_PAY, 1, 20)).orders
    if (waitPayOrders.length > 0) {
      return await this.buildWaitPayData(userId, waitPayOrders[0])
    }

    const waitUseOrders: OrderListItemVO[] =
      (await this.orderRepository.getOrderList(userId, OrderListTab.WAIT_USE, 1, 50)).orders
    const ticketing: OrderListItemVO | undefined =
      waitUseOrders.find((item: OrderListItemVO): boolean => item.actionType === 'TICKETING')
    if (ticketing !== undefined) {
      return this.buildTicketingData(userId, ticketing)
    }

    const tickets: TicketFolderItemVO[] = (await this.ticketRepository.getTicketFolderPage(userId)).tickets
    const upcoming: TicketFolderItemVO | undefined = ServiceCardPolicy.selectUpcomingTicket(tickets)
    if (upcoming !== undefined) {
      return this.buildUpcomingData(userId, upcoming)
    }

    return await this.loadHotData(context, userId)
  }

  private async loadGuestData(context: common.Context): Promise<ServiceCardData> {
    const hot: ServiceCardData = await this.loadHotData(context, '')
    if (hot.statusCode === 'HOT') {
      hot.primaryText = '未登录 · ' + hot.primaryText
      return hot
    }
    hot.statusText = '暂无数据'
    hot.title = '暂无可展示的热门演出'
    hot.primaryText = '登录后可查看订单与票夹'
    hot.actionText = '去登录'
    hot.target = ServiceCardTarget.LOGIN
    return hot
  }

  private async buildWaitPayData(userId: string, order: OrderListItemVO): Promise<ServiceCardData> {
    let detail: OrderDetailVO | undefined = undefined
    try {
      detail = await this.orderRepository.getOrderDetail(userId, order.orderId)
    } catch (error) {
    }
    const data: ServiceCardData = new ServiceCardData()
    data.statusCode = 'WAIT_PAY'
    data.statusText = '待支付'
    data.title = order.projectTitle
    data.primaryText = this.formatAmount(order.payAmount) + ' · ' + String(order.quantity) + '张'
    const payExpireTime: number = this.parseDateTime(detail?.payExpireTime ?? '')
    data.payExpireTimestamp = payExpireTime
    data.payRemainingMillis = this.buildPayRemainingMillis(payExpireTime)
    data.secondaryText = payExpireTime <= 0 ? '支付有效期以订单详情为准' :
      data.payRemainingMillis > 0 ? '' : '支付已超时 · 请查看订单'
    data.actionText = '去支付'
    data.target = ServiceCardTarget.ORDER_DETAIL
    data.userId = userId
    data.orderId = order.orderId
    data.posterUrl = this.resolvePoster(order.posterUrl)
    return data
  }

  private buildTicketingData(userId: string, order: OrderListItemVO): ServiceCardData {
    const data: ServiceCardData = new ServiceCardData()
    data.statusCode = 'TICKETING'
    data.statusText = '出票中'
    data.title = order.projectTitle
    data.primaryText = String(order.quantity) + '张'
    data.secondaryText = this.formatDateTime(order.startTime)
    data.actionText = '查看进度'
    data.target = ServiceCardTarget.ORDER_DETAIL
    data.userId = userId
    data.orderId = order.orderId
    data.posterUrl = this.resolvePoster(order.posterUrl)
    return data
  }

  private buildUpcomingData(userId: string, ticket: TicketFolderItemVO): ServiceCardData {
    const data: ServiceCardData = new ServiceCardData()
    data.statusCode = 'UPCOMING'
    data.statusText = '下一场观演'
    data.title = ticket.projectTitle
    data.primaryText = this.formatDateTime(ticket.startTime)
    data.secondaryText = ticket.venueName.length > 0 ?
      ticket.venueName + ' · ' + String(ticket.ticketCount) + '张' : String(ticket.ticketCount) + '张'
    data.actionText = ticket.ticketId !== undefined && ticket.ticketId.length > 0 ? '查看票夹' : '查看订单'
    data.target = ticket.ticketId !== undefined && ticket.ticketId.length > 0 ?
      ServiceCardTarget.TICKET_DETAIL : ServiceCardTarget.ORDER_DETAIL
    data.userId = userId
    data.orderId = ticket.orderId
    data.ticketId = ticket.ticketId ?? ''
    data.posterUrl = this.resolvePoster(ticket.posterUrl)
    return data
  }

  private async loadHotData(context: common.Context, userId: string): Promise<ServiceCardData> {
    const city: string = ServiceCardStore.getCity(context)
    const items: HomeRecommendItemVO[] = (await this.homeRepository.getHomeIndex(city, 1, 0)).recommendList
    if (items.length === 0) {
      const empty: ServiceCardData = new ServiceCardData()
      empty.statusCode = 'EMPTY'
      empty.statusText = '暂无数据'
      empty.title = '暂无可展示的票务信息'
      empty.primaryText = '打开应用后可以刷新演出内容'
      empty.actionText = '打开应用'
      empty.target = ServiceCardTarget.HOME
      empty.userId = userId
      return empty
    }
    const item: HomeRecommendItemVO = items[0]
    const data: ServiceCardData = new ServiceCardData()
    data.statusCode = 'HOT'
    data.statusText = city + '热门'
    data.title = item.title
    data.primaryText = item.minPrice === undefined ? '热门演出' : this.formatAmount(item.minPrice) + '起'
    data.secondaryText = this.formatDateTime(item.startTime)
    data.actionText = '查看演出'
    data.target = ServiceCardTarget.PERFORMANCE_DETAIL
    data.userId = userId
    data.projectId = item.projectId
    data.sessionId = item.sessionId
    data.posterUrl = this.resolvePoster(item.posterUrl)
    return data
  }

  private buildPayRemainingMillis(expireTime: number): number {
    if (expireTime <= 0) {
      return 0
    }
    return Math.max(0, Math.min(86399999, expireTime - Date.now()))
  }

  private parseDateTime(value: string): number {
    const normalized: string = value.trim().replace(' ', 'T')
    if (normalized.length === 0) {
      return 0
    }
    const result: number = new Date(normalized).getTime()
    return result === result ? result : 0
  }

  private formatDateTime(value: string): string {
    const normalized: string = value.trim().replace('T', ' ')
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized
  }

  private formatAmount(value: number): string {
    return '¥' + Number(value).toFixed(2)
  }

  private resolvePoster(value: string): string {
    const source: ResourceStr = MediaResourceUtil.getMedia(value)
    return typeof source === 'string' ? source : value
  }

  private buildUpdatedText(): string {
    const now: Date = new Date()
    return '更新于 ' + this.pad(now.getHours()) + ':' + this.pad(now.getMinutes())
  }

  private pad(value: number): string {
    return value < 10 ? '0' + String(value) : String(value)
  }

  private buildOfflineData(loggedIn: boolean, userId: string): ServiceCardData {
    const data: ServiceCardData = new ServiceCardData()
    data.statusCode = 'OFFLINE'
    data.statusText = '暂时离线'
    data.title = '票务信息暂时无法更新'
    data.primaryText = '请检查网络后刷新卡片'
    data.actionText = loggedIn ? '打开应用' : '去登录'
    data.target = loggedIn ? ServiceCardTarget.HOME : ServiceCardTarget.LOGIN
    data.userId = userId
    return data
  }
}
