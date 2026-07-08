import { Order } from '../../model/entity/Order'
import { ElectronicTicket } from '../../model/entity/ElectronicTicket'
import { PerformanceSession } from '../../model/entity/PerformanceSession'
import { TicketStatus } from '../../model/enums/TicketStatus'
import { OrderStatus } from '../../model/enums/OrderStatus'
import { OrderDataHelper } from './OrderDataHelper'
import { TICKET_ISSUE_BEFORE_HOURS } from './OrderConstants'
import { OrderDetailTicketActionType } from './OrderConstants'
import { OrderActionType } from './OrderConstants'
import { DateTimeUtil } from '../../utils/DateTimeUtil'
import { IdGenerator } from '../../utils/IdGenerator'

export class OrderTicketService {
  private dataHelper: OrderDataHelper

  constructor(dataHelper: OrderDataHelper) {
    this.dataHelper = dataHelper
  }

  issueDueTicketsForUser(userId: string): boolean {
    let changed: boolean = false

    this.dataHelper.findUserOrders(userId)
      .filter((order: Order) => order.orderStatus === OrderStatus.WAIT_USE)
      .forEach((order: Order) => {
        if (this.issueDueTicketsForOrder(order)) {
          changed = true
        }
      })

    return changed
  }

  issueDueTicketsForOrder(order: Order): boolean {
    if (order.orderStatus !== OrderStatus.WAIT_USE) {
      return false
    }

    const session: PerformanceSession | undefined = this.dataHelper.findSession(order.sessionId)
    if (session === undefined) {
      return false
    }

    const expectedIssueTime: string = this.buildExpectedIssueTime(session)
    if (DateTimeUtil.toTimeMillis(expectedIssueTime) > new Date().getTime()) {
      return false
    }

    const generatingTickets: ElectronicTicket[] = this.dataHelper.findTickets(order.orderId).filter((item: ElectronicTicket) => {
      return item.ticketStatus === TicketStatus.GENERATING
    })

    if (generatingTickets.length === 0) {
      return false
    }

    const nowTime: string = DateTimeUtil.now()

    generatingTickets.forEach((ticket: ElectronicTicket) => {
      ticket.ticketStatus = TicketStatus.UNUSED
      ticket.qrCodeValue = IdGenerator.createQrCodeValue(ticket.ticketId)
      ticket.generateTime = nowTime
    })

    order.ticketIssuedTime = nowTime
    return true
  }

  buildExpectedIssueTime(session: PerformanceSession): string {
    const time: number = DateTimeUtil.toTimeMillis(session.startTime) - TICKET_ISSUE_BEFORE_HOURS * 60 * 60 * 1000
    return DateTimeUtil.formatTime(new Date(time))
  }

  buildOrderActionType(order: Order): OrderActionType {
    if (order.orderStatus === OrderStatus.WAIT_PAY) {
      return 'CONTINUE_PAY'
    }

    if (order.orderStatus === OrderStatus.WAIT_USE) {
      const ticketActionType: OrderDetailTicketActionType = this.buildOrderDetailTicketActionType(order)
      if (ticketActionType === 'VIEW_TICKET') {
        return 'VIEW_TICKET'
      }
      if (ticketActionType === 'TICKETING') {
        return 'TICKETING'
      }
    }

    return 'NONE'
  }

  buildOrderDetailTicketActionType(order: Order): OrderDetailTicketActionType {
    if (order.orderStatus !== OrderStatus.WAIT_USE) {
      return 'NONE'
    }

    const tickets: ElectronicTicket[] = this.dataHelper.findTickets(order.orderId)
    const hasUnused: boolean = tickets.some((item: ElectronicTicket) => item.ticketStatus === TicketStatus.UNUSED)
    if (hasUnused) {
      return 'VIEW_TICKET'
    }

    const hasGeneratingOrError: boolean = tickets.some((item: ElectronicTicket) => {
      return item.ticketStatus === TicketStatus.GENERATING || item.ticketStatus === TicketStatus.ERROR
    })
    if (hasGeneratingOrError) {
      return 'TICKETING'
    }

    return 'NONE'
  }

  getDefaultViewTicketId(orderId: string): string | undefined {
    const ticket: ElectronicTicket | undefined = this.dataHelper.findTickets(orderId).find((item: ElectronicTicket) => {
      return item.ticketStatus === TicketStatus.UNUSED
    })

    return ticket?.ticketId
  }

  buildTicketIssuedTime(order: Order): string | undefined {
    if (order.ticketIssuedTime !== undefined) {
      return order.ticketIssuedTime
    }

    const ticket: ElectronicTicket | undefined = this.dataHelper.findTickets(order.orderId).find((item: ElectronicTicket) => {
      return item.generateTime !== undefined &&
        (item.ticketStatus === TicketStatus.UNUSED || item.ticketStatus === TicketStatus.CHECKED || item.ticketStatus === TicketStatus.EXPIRED)
    })

    return ticket === undefined ? undefined : ticket.generateTime
  }
}
