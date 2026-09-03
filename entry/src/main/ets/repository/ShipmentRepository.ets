import { ShipmentVO } from '../model/vo/ticketsource/ShipmentVO'
import { ShipmentStatus } from '../model/vo/ticketsource/TicketSourceTypes'
import { MoneyUtil } from '../model/vo/ticketsource/MoneyVO'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

interface BackendMoney {
  amountMinor?: number | string | null
  currency?: string | null
}

interface SyncShipmentRequestBody {
  userId: number
}

interface BackendShipmentView {
  orderId: number | string
  orderNo: string
  deliveryType: string
  deliveryFee?: BackendMoney | null
  shipmentStatus: string
  carrierName?: string | null
  waybillNo?: string | null
  trackingUrl?: string | null
  shippedTime?: string | null
  signedTime?: string | null
  lastSyncTime?: string | null
  canRefresh?: boolean
  deliveryFeeRefundableHint?: boolean
  deliveryFeeRefundHint?: string | null
  lastSyncStatus?: string | null
  warnings?: string[]
}

/** 第三方纸质票物流数据层；物流状态与本地订单状态保持独立。 */
export class ShipmentRepository {
  async getShipment(orderId: string, userId: string): Promise<ShipmentVO> {
    const response: BackendShipmentView = await ApiClient.get<BackendShipmentView>(
      '/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/shipment',
      [new ApiQueryParam('userId', userId)]
    )
    return this.map(response)
  }

  async syncShipment(orderId: string, userId: string): Promise<ShipmentVO> {
    const body: SyncShipmentRequestBody = {
      userId: Number(userId)
    }
    const response: BackendShipmentView = await ApiClient.post<BackendShipmentView>(
      '/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/shipment/sync',
      body
    )
    AppStorageVersionUtil.bumpShipmentChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()
    return this.map(response)
  }

  private map(raw: BackendShipmentView): ShipmentVO {
    return {
      orderId: String(raw.orderId),
      orderNo: raw.orderNo,
      deliveryType: raw.deliveryType,
      deliveryFee: raw.deliveryFee === undefined || raw.deliveryFee === null ? MoneyUtil.zero() :
        MoneyUtil.fromMinor(raw.deliveryFee.amountMinor, raw.deliveryFee.currency ?? 'CNY'),
      shipmentStatus: raw.shipmentStatus as ShipmentStatus,
      carrierName: this.optional(raw.carrierName),
      waybillNo: this.optional(raw.waybillNo),
      trackingUrl: this.optional(raw.trackingUrl),
      shippedTime: this.optional(raw.shippedTime),
      signedTime: this.optional(raw.signedTime),
      lastSyncTime: this.optional(raw.lastSyncTime),
      canRefresh: raw.canRefresh === true,
      deliveryFeeRefundableHint: raw.deliveryFeeRefundableHint === true,
      deliveryFeeRefundHint: raw.deliveryFeeRefundHint ?? '',
      lastSyncStatus: raw.lastSyncStatus ?? '',
      warnings: raw.warnings ?? []
    }
  }

  private optional(value: string | undefined | null): string | undefined {
    if (value === undefined || value === null || value.length === 0) {
      return undefined
    }
    return value
  }
}
