import { TicketSourceOrderQuoteRequest } from '../model/vo/ticketsource/OrderRequestVO'
import { OrderTicketSelectionRequest } from '../model/vo/ticketsource/TicketSourceTypes'

/** V1.2/V1.3 单票档下单请求的纯数据校验，不依赖网络/页面，可直接做本地单元测试。 */
export class TicketSourceOrderValidator {
  static validateQuoteRequest(request: TicketSourceOrderQuoteRequest): void {
    if (request.userId.trim().length === 0 || request.projectId.trim().length === 0 ||
      request.sessionId.trim().length === 0 || request.skuId.trim().length === 0) {
      throw new Error('用户、项目、场次和票档不能为空')
    }
    if (request.tickets.length === 0) {
      throw new Error('至少选择一张票')
    }

    const clientTicketNos: string[] = []
    const audienceIds: string[] = []
    request.tickets.forEach((ticket: OrderTicketSelectionRequest) => {
      const clientTicketNo: string = ticket.clientTicketNo.trim()
      const audienceId: string = ticket.audienceId.trim()
      if (clientTicketNo.length === 0 || audienceId.length === 0) {
        throw new Error('每张票必须提供clientTicketNo并绑定观演人')
      }
      if (clientTicketNos.indexOf(clientTicketNo) >= 0) {
        throw new Error('同一订单clientTicketNo不能重复')
      }
      if (audienceIds.indexOf(audienceId) >= 0) {
        throw new Error('同一观演人在一个订单中只能绑定一张票')
      }
      clientTicketNos.push(clientTicketNo)
      audienceIds.push(audienceId)
    })

    if (request.ticketMode === 'PAPER_TICKET' && request.deliveryMode === 'EXPRESS' &&
      (request.addressId === undefined || request.addressId.trim().length === 0)) {
      throw new Error('纸质票快递配送必须选择收货地址')
    }
    if (request.ticketMode === 'PAPER_TICKET' && request.deliveryMode === 'PAPERLESS') {
      throw new Error('纸质票不能使用PAPERLESS配送模式')
    }
    if (request.deliveryMode === 'EXPRESS' && request.ticketMode !== 'PAPER_TICKET') {
      throw new Error('只有纸质票可以使用快递配送')
    }
  }

  static validateSubmitTickets(tickets: OrderTicketSelectionRequest[], quantity: number): void {
    if (tickets.length === 0) {
      throw new Error('至少选择一张票')
    }
    if (tickets.length !== quantity) {
      throw new Error('购买数量必须等于tickets.length')
    }
    const clientTicketNos: string[] = []
    const audienceIds: string[] = []
    tickets.forEach((ticket: OrderTicketSelectionRequest) => {
      const clientTicketNo: string = ticket.clientTicketNo.trim()
      const audienceId: string = ticket.audienceId.trim()
      if (clientTicketNo.length === 0 || audienceId.length === 0) {
        throw new Error('每张票必须提供clientTicketNo并绑定观演人')
      }
      if (clientTicketNos.indexOf(clientTicketNo) >= 0) {
        throw new Error('同一订单clientTicketNo不能重复')
      }
      if (audienceIds.indexOf(audienceId) >= 0) {
        throw new Error('同一观演人在一个订单中只能绑定一张票')
      }
      clientTicketNos.push(clientTicketNo)
      audienceIds.push(audienceId)
    })
  }

}
