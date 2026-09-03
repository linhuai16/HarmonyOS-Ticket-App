import { MoneyVO } from './MoneyVO'
import { DeliveryMode } from './TicketSourceTypes'

/**
 * 麦麦订单计价中与纸质票配送有关的前端模型。
 * 不包含第三方 providerDeliveryQuoteId，鸿蒙端只持有麦麦 quoteId。
 */
export interface DeliveryQuoteVO {
  deliveryMode: DeliveryMode
  addressId?: string
  deliveryFee: MoneyVO
  warnings: string[]
}
