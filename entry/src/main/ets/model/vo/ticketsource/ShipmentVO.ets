import { MoneyVO } from './MoneyVO'
import { ShipmentStatus } from './TicketSourceTypes'

/** 用户侧物流模型，不暴露第三方内部标识。 */
export interface ShipmentVO {
  orderId: string
  orderNo: string
  deliveryType: string
  deliveryFee: MoneyVO
  shipmentStatus: ShipmentStatus
  carrierName?: string
  waybillNo?: string
  trackingUrl?: string
  shippedTime?: string
  signedTime?: string
  lastSyncTime?: string
  canRefresh: boolean
  deliveryFeeRefundableHint: boolean
  deliveryFeeRefundHint: string
  lastSyncStatus: string
  warnings: string[]
}
