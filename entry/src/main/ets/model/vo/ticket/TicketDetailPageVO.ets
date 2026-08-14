import { CertificateType } from '../../enums/CertificateType'
import { TicketStatus } from '../../enums/TicketStatus'
import { CredentialType, DynamicQrMode } from '../ticketsource/TicketSourceTypes'

export interface TicketDetailPageVO {
  posterUrl: string
  projectTitle: string
  startTime: string
  venueName: string
  venueAddress: string
  venueLongitude?: number
  venueLatitude?: number
  orderStatus?: string
  deliveryType: string
  deliveryMode?: string
  totalQuantity: number
  tickets: ElectronicTicketVO[]
  customerServicePhone?: string
}

/** 用户侧安全票凭证模型。动态二维码明文不会通过详情接口返回。 */
export interface ElectronicTicketVO {
  ticketId: string
  ticketStatus: TicketStatus
  ticketIndex: number
  ticketTotal: number
  credentialType?: CredentialType
  dynamicQrMode?: DynamicQrMode
  credentialVersion?: string
  credentialExpireTime?: string
  refreshAfterSeconds?: number
  /** 仅静态凭证允许在详情接口返回；DYNAMIC_QR 必须为空。 */
  credentialDisplayValue?: string
  qrCodeValue?: string
  skuName: string
  seatInfo?: string
  entranceInfo?: string
  audienceName: string
  certificateType?: CertificateType
  maskedCertificateNo: string
  abnormalReason?: string
}
