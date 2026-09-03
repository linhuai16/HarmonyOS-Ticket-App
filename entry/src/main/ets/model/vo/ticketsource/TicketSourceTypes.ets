export type TicketPurchaseMode = 'SYSTEM_ASSIGN' | 'GENERAL_ADMISSION'

export type DeliveryMode = 'PAPERLESS' | 'EXPRESS' | 'SELF_PICKUP'

export type ShipmentStatus =
  'NOT_REQUIRED' | 'WAIT_SHIPMENT' | 'SHIPPED' | 'IN_TRANSIT' | 'DELIVERED' | 'EXCEPTION' | 'RETURNED'

export type CredentialType =
  'STATIC_QR' | 'DYNAMIC_QR' | 'ID_CARD' | 'EXCHANGE_CODE' | 'SMS_CODE' | 'URL' | 'TEXT' | 'PAPER_TICKET'

export type DynamicQrMode = 'REMOTE_REFRESH' | 'LOCAL_CRYPTO' | 'PROVIDER_WALLET'

/** 后端 ticketMode 表示具体履约凭证类型，而 PAPERLESS 属于 deliveryMode。 */
export type TicketMode = CredentialType

/** V1.2 一张票只绑定一个观演人；订单购买数量由 tickets.length 唯一确定。 */
export interface OrderTicketSelectionRequest {
  clientTicketNo: string
  audienceId: string
}
