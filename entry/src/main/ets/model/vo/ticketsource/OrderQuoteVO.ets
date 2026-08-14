import { MoneyVO } from './MoneyVO'
import { DeliveryQuoteVO } from './DeliveryQuoteVO'
import { DeliveryMode, OrderTicketSelectionRequest, TicketMode, TicketPurchaseMode } from './TicketSourceTypes'

export interface AppliedPromotionVO {
  promotionType: string
  title: string
  discountAmount: MoneyVO
}

export interface SingleSkuQuoteItemVO {
  skuId: string
  skuName: string
  quantity: number
  faceUnitPrice: MoneyVO
  saleUnitPrice: MoneyVO
  subtotalAmount: MoneyVO
  tickets: OrderTicketSelectionRequest[]
}

/** V1.2 下单前计价结果：一个 quote 只允许一个 skuId。 */
export interface OrderQuoteVO {
  quoteId: string
  userId: string
  projectId: string
  sessionId: string
  purchaseMode: TicketPurchaseMode
  ticketMode: TicketMode
  deliveryMode: DeliveryMode
  item: SingleSkuQuoteItemVO
  totalTicketCount: number
  faceAmount: MoneyVO
  ticketAmount: MoneyVO
  discountAmount: MoneyVO
  deliveryFeeAmount: MoneyVO
  serviceFeeAmount: MoneyVO
  payAmount: MoneyVO
  expireTime: string
  delivery: DeliveryQuoteVO
  promotions: AppliedPromotionVO[]
  warnings: string[]
}

export interface QuotedOrderCreateVO {
  orderId: string
  orderNo: string
  orderStatus: string
  paymentStatus: string
  fulfillmentMode: string
  ticketCount: number
  payAmount: MoneyVO
  payExpireTime: string
}

export interface OrderActionVO {
  orderId: string
  orderNo: string
  orderStatus: string
  paymentStatus: string
  ticketCount: number
  operationTime: string
  message: string
}
