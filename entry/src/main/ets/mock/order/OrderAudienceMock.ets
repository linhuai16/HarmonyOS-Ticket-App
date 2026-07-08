import { OrderAudience } from '../../model/entity/OrderAudience'
import { CertificateType } from '../../model/enums/CertificateType'

export const orderAudienceMockList: OrderAudience[] = [
  {
    orderAudienceId: 'order_aud_001',
    orderId: 'order_001',
    realName: '李四',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101200001015678',
    phone: '15863257845'
  },
  {
    orderAudienceId: 'order_aud_002',
    orderId: 'order_001',
    realName: '许宁',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101199912125582',
    phone: '13912345678'
  },
  {
    orderAudienceId: 'order_aud_003',
    orderId: 'order_002',
    realName: '王五',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101200001015678',
    phone: '15863257845'
  },
  {
    orderAudienceId: 'order_aud_004',
    orderId: 'order_003',
    realName: '赵陆',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101200001015678',
    phone: '15863257845'
  },
  {
    orderAudienceId: 'order_aud_005',
    orderId: 'order_003',
    realName: '许宁',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101199912125582',
    phone: '13912345678'
  },
  {
    orderAudienceId: 'order_aud_006',
    orderId: 'order_004',
    realName: '序言',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101200001015678',
    phone: '15863257845'
  }

  ,{
    orderAudienceId: 'order_aud_007',
    orderId: 'order_006',
    realName: '林淮',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101200001015678',
    phone: '15863257845'
  },
  {
    orderAudienceId: 'order_aud_008',
    orderId: 'order_007',
    realName: '陈安',
    certificateType: CertificateType.ID_CARD,
    certificateNo: '110101199912125582',
    phone: '13912345678'
  }
]
