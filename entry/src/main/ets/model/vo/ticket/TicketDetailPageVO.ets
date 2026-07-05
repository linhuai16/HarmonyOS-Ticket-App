import { CertificateType } from "../../enums/CertificateType"
import { TicketStatus } from "../../enums/TicketStatus"

export interface TicketDetailPageVO {
  posterUrl: string
  projectTitle: string
  startTime: string
  venueName: string

  tickets: ElectronicTicketVO[]

  customerServicePhone?: string
}

export interface ElectronicTicketVO {
  ticketId: string

  ticketStatus: TicketStatus

  ticketIndex: number
  ticketTotal: number

  qrCodeValue?: string        //电子票码内容

  skuName: string        //票档
  seatInfo?: string        //座位
  /** 绑定观演人姓名 */
  audienceName: string

  /** 证件类型 */
  certificateType?: CertificateType

  /** 脱敏证件号 */
  maskedCertificateNo: string


  abnormalReason?: string    //异常原因
}
