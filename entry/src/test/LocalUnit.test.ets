import { describe, expect, it } from '@ohos/hypium'
import { TicketFolderItemVO } from '../main/ets/model/vo/ticket/TicketFolderPageVO'
import { TicketStatus } from '../main/ets/model/enums/TicketStatus'
import { TicketSourceOrderQuoteRequest } from '../main/ets/model/vo/ticketsource/OrderRequestVO'
import { OrderTicketSelectionRequest } from '../main/ets/model/vo/ticketsource/TicketSourceTypes'
import { ServiceCardPolicy } from '../main/ets/servicecard/ServiceCardPolicy'
import { TicketSourceOrderValidator } from '../main/ets/utils/TicketSourceOrderValidator'

function selection(clientTicketNo: string, audienceId: string): OrderTicketSelectionRequest {
  return { clientTicketNo, audienceId }
}

function ticket(orderId: string, startTime: string,
                displayStatus: 'UNUSED' | 'UNAVAILABLE' = 'UNUSED'): TicketFolderItemVO {
  return {
    orderId,
    posterUrl: '',
    projectTitle: orderId,
    startTime,
    venueName: '',
    venueAddress: '',
    deliveryType: 'ETICKET',
    ticketCount: 1,
    skuName: '',
    displayStatus,
    ticketStatus: TicketStatus.UNUSED
  }
}

function validationMessage(action: () => void): string {
  try {
    action()
    return ''
  } catch (error) {
    return (error as Error).message
  }
}

export default function localUnitTest(): void {
  describe('TicketSourceOrderValidator', () => {
    it('accepts matching ticket selections', 0, () => {
      const tickets: OrderTicketSelectionRequest[] = [selection('client-1', 'audience-1')]
      expect(validationMessage((): void => TicketSourceOrderValidator.validateSubmitTickets(tickets, 1))).assertEqual('')
    })

    it('rejects quantity mismatch', 0, () => {
      const tickets: OrderTicketSelectionRequest[] = [selection('client-1', 'audience-1')]
      expect(validationMessage((): void => TicketSourceOrderValidator.validateSubmitTickets(tickets, 2)))
        .assertEqual('购买数量必须等于tickets.length')
    })

    it('rejects duplicate client ticket numbers', 0, () => {
      const tickets: OrderTicketSelectionRequest[] = [
        selection('client-1', 'audience-1'), selection('client-1', 'audience-2')
      ]
      expect(validationMessage((): void => TicketSourceOrderValidator.validateSubmitTickets(tickets, 2)))
        .assertEqual('同一订单clientTicketNo不能重复')
    })

    it('rejects duplicate audiences', 0, () => {
      const tickets: OrderTicketSelectionRequest[] = [
        selection('client-1', 'audience-1'), selection('client-2', 'audience-1')
      ]
      expect(validationMessage((): void => TicketSourceOrderValidator.validateSubmitTickets(tickets, 2)))
        .assertEqual('同一观演人在一个订单中只能绑定一张票')
    })

    it('requires an address for paper express delivery', 0, () => {
      const request: TicketSourceOrderQuoteRequest = {
        userId: 'user-1', projectId: 'project-1', sessionId: 'session-1', skuId: 'sku-1',
        tickets: [selection('client-1', 'audience-1')], ticketMode: 'PAPER_TICKET', deliveryMode: 'EXPRESS'
      }
      expect(validationMessage((): void => TicketSourceOrderValidator.validateQuoteRequest(request)))
        .assertEqual('纸质票快递配送必须选择收货地址')
    })

    it('rejects express delivery for electronic tickets', 0, () => {
      const request: TicketSourceOrderQuoteRequest = {
        userId: 'user-1', projectId: 'project-1', sessionId: 'session-1', skuId: 'sku-1',
        tickets: [selection('client-1', 'audience-1')], ticketMode: 'STATIC_QR', deliveryMode: 'EXPRESS',
        addressId: 'address-1'
      }
      expect(validationMessage((): void => TicketSourceOrderValidator.validateQuoteRequest(request)))
        .assertEqual('只有纸质票可以使用快递配送')
    })
  })

  describe('ServiceCardPolicy', () => {
    it('excludes past and unavailable tickets', 0, () => {
      const now: number = new Date('2026-09-03T12:00:00').getTime()
      const selected: TicketFolderItemVO | undefined = ServiceCardPolicy.selectUpcomingTicket([
        ticket('past', '2026-09-03 11:59:59'),
        ticket('unavailable', '2026-09-03 12:30:00', 'UNAVAILABLE'),
        ticket('future', '2026-09-03 13:00:00')
      ], now)
      expect(selected?.orderId).assertEqual('future')
    })

    it('selects the nearest dated ticket before an undated ticket', 0, () => {
      const now: number = new Date('2026-09-03T12:00:00').getTime()
      const selected: TicketFolderItemVO | undefined = ServiceCardPolicy.selectUpcomingTicket([
        ticket('undated', ''),
        ticket('later', '2026-09-05 12:00:00'),
        ticket('nearest', '2026-09-04 12:00:00')
      ], now)
      expect(selected?.orderId).assertEqual('nearest')
    })
  })
}
