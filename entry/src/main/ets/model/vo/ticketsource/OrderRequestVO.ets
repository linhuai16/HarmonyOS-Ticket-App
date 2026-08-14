import { DeliveryMode, OrderTicketSelectionRequest, TicketMode, TicketPurchaseMode } from './TicketSourceTypes'

/** V1.2 单票档第三方计价请求；购买数量由 tickets.length 唯一确定。 */
export interface TicketSourceOrderQuoteRequest {
  userId: string
  projectId: string
  sessionId: string
  skuId: string
  tickets: OrderTicketSelectionRequest[]
  purchaseMode?: TicketPurchaseMode
  ticketMode: TicketMode
  deliveryMode: DeliveryMode
  addressId?: string
}
