import { CertificateType } from "../../enums/CertificateType"

export interface AudienceListPageVO {
  audiences: AudienceItemVO[]
}
export interface AudienceItemVO {
  audienceId: string
  realName: string
  certificateType: CertificateType
  maskedCertificateNo: string
  maskedPhone: string
  isDefault: boolean
}
