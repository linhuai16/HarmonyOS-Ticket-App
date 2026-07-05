import { ElectronicTicket } from '../../model/entity/ElectronicTicket'
import { TicketStatus } from '../../model/enums/TicketStatus'

export const electronicTicketMockList: ElectronicTicket[] = [
  {
    ticketId: 'ticket_001',
    orderId: 'order_001',
    orderItemId: 'order_item_001',
    orderAudienceId: 'order_aud_001',
    ticketStatus: TicketStatus.UNUSED,
    qrCodeValue: 'MOCK_QR_ORDER_001_TICKET_001',
    seatInfo: '内场 A3 区 8 排 16 座',
    generateTime: '2026-06-03 10:04:10'
  },
  {
    ticketId: 'ticket_002',
    orderId: 'order_001',
    orderItemId: 'order_item_001',
    orderAudienceId: 'order_aud_002',
    ticketStatus: TicketStatus.UNUSED,
    qrCodeValue: 'MOCK_QR_ORDER_001_TICKET_002',
    seatInfo: '内场 A3 区 8 排 17 座',
    generateTime: '2026-06-03 10:04:10'
  },
  {
    ticketId: 'ticket_003',
    orderId: 'order_003',
    orderItemId: 'order_item_003',
    orderAudienceId: 'order_aud_004',
    ticketStatus: TicketStatus.CHECKED,
    qrCodeValue: 'MOCK_QR_ORDER_003_TICKET_001',
    seatInfo: '楼座 2 排 5 座',
    generateTime: '2026-05-20 11:03:00',
    checkTime: '2026-06-16 19:10:00'
  },
  {
    ticketId: 'ticket_004',
    orderId: 'order_003',
    orderItemId: 'order_item_003',
    orderAudienceId: 'order_aud_005',
    ticketStatus: TicketStatus.CHECKED,
    qrCodeValue: 'MOCK_QR_ORDER_003_TICKET_002',
    seatInfo: '楼座 2 排 6 座',
    generateTime: '2026-05-20 11:03:00',
    checkTime: '2026-06-16 19:11:00'
  },
  {
    ticketId: 'ticket_005',
    orderId: 'order_004',
    orderItemId: 'order_item_004',
    orderAudienceId: 'order_aud_006',
    ticketStatus: TicketStatus.EXPIRED,
    qrCodeValue: 'MOCK_QR_ORDER_004_TICKET_001',
    seatInfo: '单人票 随机动线',
    generateTime: '2026-05-25 12:05:00',
    expireTime: '2026-05-26 09:30:00'
  }

  ,{
    ticketId: 'ticket_006',
    orderId: 'order_006',
    orderItemId: 'order_item_006',
    orderAudienceId: 'order_aud_007',
    ticketStatus: TicketStatus.GENERATING,
    seatInfo: '待出票后分配座位',
  },
  {
    ticketId: 'ticket_007',
    orderId: 'order_007',
    orderItemId: 'order_item_007',
    orderAudienceId: 'order_aud_008',
    ticketStatus: TicketStatus.ERROR,
    seatInfo: '状态验证票',
    abnormalReason: '出票接口返回异常，等待系统重试'
  }
]
