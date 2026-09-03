import {
  OrderListPageVO,
  OrderListItemVO
} from '../model/vo/order/OrderListPageVO'

import {
  OrderRepository,
  OrderListTab
} from '../repository/OrderRepository'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

export class OrderListViewModel {
  orders: OrderListItemVO[] = []

  userId: string = ''
  currentTab: OrderListTab = OrderListTab.ALL

  pageNo: number = 1
  pageSize: number = 10
  hasMore: boolean = false

  isLoading: boolean = false
  isRefreshing: boolean = false
  errorMessage: string = ''

  private orderRepository: OrderRepository = new OrderRepository()

  async loadPage(userId: string, tab: OrderListTab = OrderListTab.ALL): Promise<void> {
    if (this.isLoading) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    this.currentTab = tab
    const firstPageNo: number = 1

    try {
      const pageVO: OrderListPageVO = await this.orderRepository.getOrderList(
        userId,
        tab,
        firstPageNo,
        this.pageSize
      )
      this.orders = pageVO.orders
      this.hasMore = pageVO.hasMore
      this.pageNo = firstPageNo
    } catch (error) {
      this.errorMessage = '订单列表加载失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }

  async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return
    }

    this.isRefreshing = true
    this.errorMessage = ''
    const firstPageNo: number = 1
    const previousState: string = this.serviceCardStateSignature(this.orders)

    try {
      const pageVO: OrderListPageVO = await this.orderRepository.getOrderList(
        this.userId,
        this.currentTab,
        firstPageNo,
        this.pageSize
      )
      this.orders = pageVO.orders
      this.hasMore = pageVO.hasMore
      this.pageNo = firstPageNo
      if (previousState !== this.serviceCardStateSignature(pageVO.orders)) {
        AppStorageVersionUtil.bumpOrderChangedVersion()
      }
    } catch (error) {
      this.errorMessage = '订单列表刷新失败，请稍后重试'
    } finally {
      this.isRefreshing = false
    }
  }

  async changeTab(tab: OrderListTab): Promise<void> {
    this.currentTab = tab
    await this.loadPage(this.userId, tab)
  }

  async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMore) {
      return
    }

    this.isLoading = true
    this.errorMessage = ''

    const nextPageNo: number = this.pageNo + 1

    try {
      const pageVO: OrderListPageVO = await this.orderRepository.getOrderList(
        this.userId,
        this.currentTab,
        nextPageNo,
        this.pageSize
      )
      this.orders = this.orders.concat(pageVO.orders)
      this.hasMore = pageVO.hasMore
      this.pageNo = nextPageNo
    } catch (error) {
      this.errorMessage = '加载更多失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private serviceCardStateSignature(orders: OrderListItemVO[]): string {
    return orders.map((item: OrderListItemVO): string => {
      return item.orderId + ':' + String(item.orderStatus) + ':' + item.actionType
    }).join('|')
  }
}
