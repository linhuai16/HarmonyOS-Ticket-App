import { PayMethod } from '../model/enums/PayMethod'

export class AppNavRoute {
  static readonly SEARCH: string = 'Search'
  static readonly SEARCH_RESULT: string = 'SearchResult'
  static readonly CATEGORY: string = 'Category'
  static readonly WANT: string = 'Want'
  static readonly PERFORMANCE_DETAIL: string = 'PerformanceDetail'
  static readonly PERFORMANCE_VIDEO_FULLSCREEN: string = 'PerformanceVideoFullscreen'
  static readonly TICKET_SELECT: string = 'TicketSelect'
  static readonly SUBMIT_ORDER: string = 'SubmitOrder'
  static readonly PAY_SUCCESS: string = 'PaySuccess'
  static readonly ORDER_LIST: string = 'OrderList'
  static readonly ORDER_DETAIL: string = 'OrderDetail'
  static readonly REFUND_APPLY: string = 'RefundApply'
  static readonly TICKET_FOLDER: string = 'TicketFolder'
  static readonly TICKET_DETAIL: string = 'TicketDetail'
}

export interface SearchNavParams {
  initialKeyword?: string
}

export interface SearchResultNavParams {
  keyword?: string
  userId?: string
}

export interface CategoryNavParams {
  categoryId?: string
}

export interface WantNavParams {
  userId?: string
}

export interface PerformanceDetailNavParams {
  projectId?: string
  sessionId?: string
  userId?: string
  posterUrl?: string
  title?: string
  categoryName?: string
  startTime?: string
  cityName?: string
  venueName?: string
  minPrice?: number
  maxPrice?: number
  source?: string
}

export interface PerformanceVideoFullscreenNavParams {
  videoUrl?: string
  posterUrl?: string
  title?: string
  startPositionMs?: number
  isMuted?: boolean
}

export interface TicketSelectNavParams {
  projectId?: string
  selectedSessionId?: string
  sessionId?: string
  userId?: string
}

export interface SubmitOrderNavParams {
  userId?: string
  projectId?: string
  sessionId?: string
  skuId?: string
  quantity?: number
}

export interface PaySuccessNavParams {
  userId?: string
  orderId?: string
  payMethod?: PayMethod
}

export interface OrderListNavParams {
  userId?: string
}

export interface OrderDetailNavParams {
  userId?: string
  orderId?: string
}

export interface RefundApplyNavParams {
  userId?: string
  orderId?: string
}

export interface TicketFolderNavParams {
  userId?: string
}

export interface TicketDetailNavParams {
  userId?: string
  orderId?: string
  ticketId?: string
}

export class AppNavigator {
  static openSearch(stack: NavPathStack, params: SearchNavParams = {}): void {
    stack.pushPathByName(AppNavRoute.SEARCH, params)
  }

  static openSearchResult(stack: NavPathStack, params: SearchResultNavParams): void {
    stack.pushPathByName(AppNavRoute.SEARCH_RESULT, params)
  }

  static openCategory(stack: NavPathStack, params: CategoryNavParams): void {
    stack.pushPathByName(AppNavRoute.CATEGORY, params)
  }

  static openWant(stack: NavPathStack, params: WantNavParams): void {
    stack.pushPathByName(AppNavRoute.WANT, params)
  }

  static openPerformanceDetail(stack: NavPathStack, params: PerformanceDetailNavParams): void {
    stack.pushPathByName(AppNavRoute.PERFORMANCE_DETAIL, params)
  }

  static openPerformanceVideoFullscreen(stack: NavPathStack, params: PerformanceVideoFullscreenNavParams): void {
    stack.pushPathByName(AppNavRoute.PERFORMANCE_VIDEO_FULLSCREEN, params)
  }

  static openTicketSelect(stack: NavPathStack, params: TicketSelectNavParams): void {
    stack.pushPathByName(AppNavRoute.TICKET_SELECT, params)
  }

  static openSubmitOrder(stack: NavPathStack, params: SubmitOrderNavParams): void {
    stack.pushPathByName(AppNavRoute.SUBMIT_ORDER, params)
  }

  static openPaySuccess(stack: NavPathStack, params: PaySuccessNavParams): void {
    stack.pushPathByName(AppNavRoute.PAY_SUCCESS, params)
  }

  static openOrderList(stack: NavPathStack, params: OrderListNavParams): void {
    stack.pushPathByName(AppNavRoute.ORDER_LIST, params)
  }

  static openOrderDetail(stack: NavPathStack, params: OrderDetailNavParams): void {
    stack.pushPathByName(AppNavRoute.ORDER_DETAIL, params)
  }

  static replaceWithOrderDetail(stack: NavPathStack, params: OrderDetailNavParams): void {
    stack.replacePathByName(AppNavRoute.ORDER_DETAIL, params)
  }

  static openRefundApply(stack: NavPathStack, params: RefundApplyNavParams): void {
    stack.pushPathByName(AppNavRoute.REFUND_APPLY, params)
  }

  static openTicketFolder(stack: NavPathStack, params: TicketFolderNavParams): void {
    stack.pushPathByName(AppNavRoute.TICKET_FOLDER, params)
  }

  static openTicketDetail(stack: NavPathStack, params: TicketDetailNavParams): void {
    stack.pushPathByName(AppNavRoute.TICKET_DETAIL, params)
  }
}
