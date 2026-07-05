import { Order } from '../model/entity/Order'
import { OrderItem } from '../model/entity/OrderItem'
import { ElectronicTicket } from '../model/entity/ElectronicTicket'
import { OrderAudience } from '../model/entity/OrderAudience'
import { TicketFolderItemVO } from '../model/vo/ticket/TicketFolderPageVO'
import { OrderStatus } from '../model/enums/OrderStatus'
import { TicketStatus } from '../model/enums/TicketStatus'
import { orderMockList } from '../mock/order/OrderMock'
import { orderItemMockList } from '../mock/order/OrderItemMock'
import { orderAudienceMockList } from '../mock/order/OrderAudienceMock'
import { electronicTicketMockList } from '../mock/ticket/ElectronicTicketMock'
import { DateTimeUtil } from './DateTimeUtil'

/**
 * 票务数据工具。
 *
 * 说明：
 * TicketRepository、OrderTicketService 等模块都会涉及电子票查询、排序、状态优先级判断。
 * 这些不是页面逻辑，统一放在 utils 中，避免 Repository 内重复维护。
 */
export class TicketDataUtil {
  static findOrder(orderId: string): Order | undefined {
    return orderMockList.find((item: Order) => item.orderId === orderId)
  }

  static findUserOrder(userId: string, orderId: string): Order | undefined {
    return orderMockList.find((item: Order) => item.userId === userId && item.orderId === orderId)
  }

  static getTicketFolderOrders(userId: string): Order[] {
    return orderMockList
      .filter((order: Order) => {
        return order.userId === userId && TicketDataUtil.isTicketFolderOrderStatus(order.orderStatus)
      })
      .sort((a: Order, b: Order) => {
        return DateTimeUtil.toTimeMillis(b.payTime ?? b.createTime) - DateTimeUtil.toTimeMillis(a.payTime ?? a.createTime)
      })
  }

  static isTicketFolderOrderStatus(orderStatus: OrderStatus): boolean {
    return orderStatus === OrderStatus.WAIT_USE ||
      orderStatus === OrderStatus.FINISHED ||
      orderStatus === OrderStatus.REFUND_SUCCESS
  }

  static findOrderItem(orderId: string): OrderItem | undefined {
    return orderItemMockList.find((item: OrderItem) => item.orderId === orderId)
  }

  static findOrderAudience(orderAudienceId: string): OrderAudience | undefined {
    if (orderAudienceId.length === 0) {
      return undefined
    }

    return orderAudienceMockList.find((item: OrderAudience) => item.orderAudienceId === orderAudienceId)
  }

  static findTicket(ticketId: string): ElectronicTicket | undefined {
    return electronicTicketMockList.find((item: ElectronicTicket) => item.ticketId === ticketId)
  }

  static getTicketsByOrderId(orderId: string): ElectronicTicket[] {
    return electronicTicketMockList.filter((item: ElectronicTicket) => item.orderId === orderId)
  }

  static getTicketsByOrderIdAndStatus(orderId: string, ticketStatus: TicketStatus): ElectronicTicket[] {
    return electronicTicketMockList.filter((item: ElectronicTicket) => {
      return item.orderId === orderId && item.ticketStatus === ticketStatus
    })
  }

  static sortTickets(tickets: ElectronicTicket[]): ElectronicTicket[] {
    return tickets.slice().sort((a: ElectronicTicket, b: ElectronicTicket) => {
      return TicketDataUtil.compareTicketStableOrder(a, b)
    })
  }

  static findDefaultTicket(tickets: ElectronicTicket[]): ElectronicTicket | undefined {
    if (tickets.length === 0) {
      return undefined
    }

    const sortedTickets: ElectronicTicket[] = tickets.slice().sort((a: ElectronicTicket, b: ElectronicTicket) => {
      const priorityDiff: number = TicketDataUtil.getTicketStatusPriority(a.ticketStatus) - TicketDataUtil.getTicketStatusPriority(b.ticketStatus)
      if (priorityDiff !== 0) {
        return priorityDiff
      }

      return TicketDataUtil.compareTicketStableOrder(a, b)
    })

    return sortedTickets[0]
  }

  static compareTicketStableOrder(a: ElectronicTicket, b: ElectronicTicket): number {
    const orderItemDiff: number = a.orderItemId.localeCompare(b.orderItemId)
    if (orderItemDiff !== 0) {
      return orderItemDiff
    }

    return a.ticketId.localeCompare(b.ticketId)
  }

  static compareTicketFolderItem(a: TicketFolderItemVO, b: TicketFolderItemVO): number {
    const priorityDiff: number = TicketDataUtil.getTicketStatusPriority(a.ticketStatus) - TicketDataUtil.getTicketStatusPriority(b.ticketStatus)
    if (priorityDiff !== 0) {
      return priorityDiff
    }

    const timeDiff: number = DateTimeUtil.toTimeMillis(a.startTime) - DateTimeUtil.toTimeMillis(b.startTime)
    if (timeDiff !== 0) {
      return timeDiff
    }

    return a.orderId.localeCompare(b.orderId)
  }

  static getTicketStatusPriority(status: TicketStatus): number {
    if (status === TicketStatus.UNUSED) {
      return 0
    }

    if (status === TicketStatus.GENERATING) {
      return 1
    }

    if (status === TicketStatus.ERROR) {
      return 2
    }

    if (status === TicketStatus.CHECKED) {
      return 3
    }

    if (status === TicketStatus.EXPIRED) {
      return 4
    }

    return 5
  }

  static buildDisplayStatus(tickets: ElectronicTicket[]): 'UNUSED' | 'UNAVAILABLE' {
    const hasUnused: boolean = tickets.some((item: ElectronicTicket) => item.ticketStatus === TicketStatus.UNUSED)

    if (hasUnused) {
      return 'UNUSED'
    }

    return 'UNAVAILABLE'
  }
}
