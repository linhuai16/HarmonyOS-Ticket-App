import { OrderStatus } from "../../enums/OrderStatus"

export interface OrderListPageVO {
  orders: OrderListItemVO[]
  hasMore: boolean
}

export interface OrderListItemVO {
  orderId: string
  orderNo: string

  orderStatus: OrderStatus

  posterUrl: string
  projectTitle: string
  startTime: string
  venueName: string

  skuName: string
  unitPrice: number
  quantity: number

  payAmount: number

  actionType: 'CONTINUE_PAY' | 'VIEW_TICKET' | 'TICKETING' | 'NONE'
}
