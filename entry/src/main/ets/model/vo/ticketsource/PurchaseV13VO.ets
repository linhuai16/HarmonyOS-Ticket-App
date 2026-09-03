import { MoneyVO } from './MoneyVO'
import { OrderTicketSelectionRequest, TicketPurchaseMode, TicketMode, DeliveryMode } from './TicketSourceTypes'

export interface V13InventoryViewVO {
  stockState: string
  availableStock?: number
  exact: boolean
  displayText: string
  canContinue: boolean
}

export interface V13EstimatedAmountVO {
  priceStatus: 'ESTIMATED'
  ticketAmount: MoneyVO
  deliveryFee: MoneyVO
  payAmount: MoneyVO
  displayText: string
}

export interface V13FulfillmentOptionVO {
  optionCode: string
  displayName: string
  credentialType: TicketMode
  deliveryMethod: DeliveryMode
  requiresAddress: boolean
  requiresDynamicRefresh: boolean
  recommended: boolean
  deliveryFee: MoneyVO
  userTips: string[]
}

export interface V13AudienceEligibilityVO {
  audienceId: string
  canSelect: boolean
  disabledReason: string
}

export interface V13PurchaseInitVO {
  userId?: string
  projectId: string
  sessionId: string
  skuId: string
  skuName: string
  quantity: number
  limitPerOrder: number
  inventoryView: V13InventoryViewVO
  purchaseMode: TicketPurchaseMode
  fulfillmentOptions: V13FulfillmentOptionVO[]
  estimatedAmount: V13EstimatedAmountVO
  audienceEligibility: V13AudienceEligibilityVO[]
  notices: string[]
}

export interface V13SubmitOrderRequestVO {
  userId: string
  projectId: string
  sessionId: string
  skuId: string
  quantity: number
  tickets: OrderTicketSelectionRequest[]
  fulfillmentOptionCode: string
  addressId?: string
  clientSubmitNo: string
  expectedPayAmountMinor: number
}

export interface V13SubmitOrderVO {
  orderId: string
  orderNo: string
  orderStatus: string
  priceStatus: 'CONFIRMED' | 'CHANGED' | 'EXPIRED' | 'FAILED'
  ticketAmount: MoneyVO
  deliveryFee: MoneyVO
  payAmount: MoneyVO
  reservationExpireAt: string
  paymentButtonText: string
  userMessage: string
}
