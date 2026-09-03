import { TicketStatus } from '../../enums/TicketStatus'
import { CredentialType, DynamicQrMode } from './TicketSourceTypes'

/** 第三方履约结果映射后的鸿蒙安全模型；不暴露 providerTicketId/providerTicketProductId。 */
export interface TicketCredentialVO {
  ticketId: string
  ticketNo: string
  ticketStatus: TicketStatus
  credentialType?: CredentialType
  dynamicQrMode?: DynamicQrMode
  credentialVersion?: string
  credentialExpireTime?: string
  refreshAfterSeconds?: number
  seatInfo?: string
  clientTicketNo: string
  holderRef: string
  holderName: string
}
