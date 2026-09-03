import { MoneyVO } from './MoneyVO'
import { DeliveryMode, TicketMode, TicketPurchaseMode } from './TicketSourceTypes'

/** 服务端根据第三方能力收敛后的用户可选履约组合。 */
export interface PurchaseFulfillmentOptionVO {
  optionCode: string
  ticketMode: TicketMode
  deliveryMode: DeliveryMode
  label: string
  requiresAddress: boolean
  recommended: boolean
  deliveryFee: MoneyVO
}

/** 第十批购票页履约白名单，不包含任何 provider* 标识。 */
export interface PurchaseOptionsVO {
  projectId: string
  sessionId: string
  skuId: string
  saleable: boolean
  purchaseMode: TicketPurchaseMode
  limitPerOrder: number
  stockAvailable?: number
  stockExact: boolean
  options: PurchaseFulfillmentOptionVO[]
  warnings: string[]
}
