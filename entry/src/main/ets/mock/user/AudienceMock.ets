import { Audience } from '../../model/entity/Audience'
import { CertificateType } from '../../model/enums/CertificateType'

export const audienceMockList: Audience[] = [
  {
    audienceId: 'aud_001',
    userId: 'user_001',
    realName: '林淮',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101200001015678',
    phone: '15863257845',
    isDefault: true
  },
  {
    audienceId: 'aud_002',
    userId: 'user_001',
    realName: '许宁',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101199912125582',
    phone: '13912345678',
    isDefault: false
  },
  {
    audienceId: 'aud_003',
    userId: 'user_001',
    realName: '陈安',
    certificateType: CertificateType.PASSPORT,
    certificateNo: 'EA1234567',
    phone: '13722223333',
    isDefault: false
  }
]
