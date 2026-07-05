import {
  TicketFolderPageVO,
  TicketFolderItemVO
} from '../model/vo/ticket/TicketFolderPageVO'

import {
  TicketDetailPageVO,
  ElectronicTicketVO
} from '../model/vo/ticket/TicketDetailPageVO'

import { Order } from '../model/entity/Order'
import { OrderItem } from '../model/entity/OrderItem'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { ElectronicTicket } from '../model/entity/ElectronicTicket'
import { OrderAudience } from '../model/entity/OrderAudience'


import { OrderStatus } from '../model/enums/OrderStatus'
import { TicketStatus } from '../model/enums/TicketStatus'
import { DateTimeUtil } from '../utils/DateTimeUtil'
import { MaskUtil } from '../utils/MaskUtil'
import { IdGenerator } from '../utils/IdGenerator'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { PerformanceDataUtil } from '../utils/PerformanceDataUtil'
import { TicketDataUtil } from '../utils/TicketDataUtil'
import { RefundDataUtil } from '../utils/RefundDataUtil'

const CUSTOMER_SERVICE_PHONE: string = '400-000-0000'

/**
 * 票夹 / 电子票 Repository。
 *
 * 对外保留票夹列表、电子票详情、Mock 出票/检票调试方法；
 * 基础查找、排序、脱敏、时间、ID、AppStorage 版本号更新统一复用 utils。
 */
export class TicketRepository {
  getTicketFolderPage(userId: string): TicketFolderPageVO {
    const tickets: TicketFolderItemVO[] = []

    TicketDataUtil.getTicketFolderOrders(userId).forEach((order: Order) => {
      const item: TicketFolderItemVO | undefined = this.buildTicketFolderItem(order)

      if (item !== undefined) {
        tickets.push(item)
      }
    })

    tickets.sort((a: TicketFolderItemVO, b: TicketFolderItemVO) => {
      return TicketDataUtil.compareTicketFolderItem(a, b)
    })

    return {
      tickets: tickets
    }
  }

  getTicketDetailPage(userId: string, orderId: string, ticketId: string | undefined = undefined): TicketDetailPageVO | undefined {
    const order: Order | undefined = TicketDataUtil.findUserOrder(userId, orderId)

    if (order === undefined) {
      return undefined
    }

    const project: PerformanceProject | undefined = PerformanceDataUtil.findProject(order.projectId)
    const session: PerformanceSession | undefined = PerformanceDataUtil.findSession(order.sessionId)
    const orderItem: OrderItem | undefined = TicketDataUtil.findOrderItem(order.orderId)

    if (project === undefined || session === undefined || orderItem === undefined) {
      return undefined
    }

    const ticketList: ElectronicTicket[] = TicketDataUtil.sortTickets(TicketDataUtil.getTicketsByOrderId(orderId))

    if (ticketList.length === 0 || !this.isValidOpenTicket(ticketList, ticketId)) {
      return undefined
    }

    return {
      posterUrl: project.posterUrl,
      projectTitle: project.title,
      startTime: session.startTime,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      tickets: this.buildElectronicTicketVOList(ticketList, orderItem),
      customerServicePhone: CUSTOMER_SERVICE_PHONE
    }
  }

  mockIssueSuccess(orderId: string): boolean {
    const order: Order | undefined = TicketDataUtil.findOrder(orderId)

    if (order === undefined || order.orderStatus !== OrderStatus.WAIT_USE) {
      return false
    }

    const tickets: ElectronicTicket[] = TicketDataUtil.getTicketsByOrderIdAndStatus(orderId, TicketStatus.GENERATING)

    if (tickets.length === 0) {
      return false
    }

    const nowTime: string = DateTimeUtil.now()

    tickets.forEach((ticket: ElectronicTicket) => {
      ticket.ticketStatus = TicketStatus.UNUSED
      ticket.qrCodeValue = IdGenerator.createQrCodeValue(ticket.ticketId)
      ticket.generateTime = nowTime
    })

    order.ticketIssuedTime = nowTime
    AppStorageVersionUtil.bumpTicketChangedVersion()

    return true
  }

  mockIssueFailed(orderId: string, reason: string = '出票接口异常，系统已发起原路退款'): boolean {
    const order: Order | undefined = TicketDataUtil.findOrder(orderId)

    if (order === undefined || order.orderStatus !== OrderStatus.WAIT_USE) {
      return false
    }

    const tickets: ElectronicTicket[] = TicketDataUtil.getTicketsByOrderId(orderId)

    if (tickets.length === 0) {
      return false
    }

    const nowTime: string = DateTimeUtil.now()

    tickets.forEach((ticket: ElectronicTicket) => {
      ticket.ticketStatus = TicketStatus.EXPIRED
      ticket.expireTime = nowTime
      ticket.abnormalReason = reason
    })

    order.orderStatus = OrderStatus.REFUND_SUCCESS
    this.createSystemRefundRecord(order, nowTime)
    AppStorageVersionUtil.bumpTicketChangedVersion()

    return true
  }

  mockCheckTicket(ticketId: string): boolean {
    const ticket: ElectronicTicket | undefined = TicketDataUtil.findTicket(ticketId)

    if (ticket === undefined || ticket.ticketStatus !== TicketStatus.UNUSED) {
      return false
    }

    ticket.ticketStatus = TicketStatus.CHECKED
    ticket.checkTime = DateTimeUtil.now()
    AppStorageVersionUtil.bumpTicketChangedVersion()

    return true
  }

  mockExpireUnusedTickets(orderId: string): boolean {
    const tickets: ElectronicTicket[] = TicketDataUtil.getTicketsByOrderIdAndStatus(orderId, TicketStatus.UNUSED)

    if (tickets.length === 0) {
      return false
    }

    const nowTime: string = DateTimeUtil.now()

    tickets.forEach((ticket: ElectronicTicket) => {
      ticket.ticketStatus = TicketStatus.EXPIRED
      ticket.expireTime = nowTime
    })

    AppStorageVersionUtil.bumpTicketChangedVersion()

    return true
  }

  private createSystemRefundRecord(order: Order, refundTime: string): void {
    RefundDataUtil.upsertRefundSuccessRecord(order, refundTime)
  }

  private buildTicketFolderItem(order: Order): TicketFolderItemVO | undefined {
    const project: PerformanceProject | undefined = PerformanceDataUtil.findProject(order.projectId)
    const session: PerformanceSession | undefined = PerformanceDataUtil.findSession(order.sessionId)
    const orderItem: OrderItem | undefined = TicketDataUtil.findOrderItem(order.orderId)

    if (project === undefined || session === undefined || orderItem === undefined) {
      return undefined
    }

    const tickets: ElectronicTicket[] = TicketDataUtil.getTicketsByOrderId(order.orderId)

    if (tickets.length === 0) {
      return undefined
    }

    const defaultTicket: ElectronicTicket | undefined = TicketDataUtil.findDefaultTicket(tickets)

    if (defaultTicket === undefined) {
      return undefined
    }

    return {
      orderId: order.orderId,
      ticketId: defaultTicket.ticketId,
      posterUrl: project.posterUrl,
      projectTitle: project.title,
      startTime: session.startTime,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      ticketCount: tickets.length,
      skuName: orderItem.skuName,
      displayStatus: TicketDataUtil.buildDisplayStatus(tickets),
      ticketStatus: defaultTicket.ticketStatus
    }
  }

  private buildElectronicTicketVOList(tickets: ElectronicTicket[], orderItem: OrderItem): ElectronicTicketVO[] {
    const sortedTickets: ElectronicTicket[] = TicketDataUtil.sortTickets(tickets)
    const ticketTotal: number = sortedTickets.length

    return sortedTickets.map((ticket: ElectronicTicket, index: number): ElectronicTicketVO => {
      const audience: OrderAudience | undefined = TicketDataUtil.findOrderAudience(ticket.orderAudienceId)

      return {
        ticketId: ticket.ticketId,
        ticketStatus: ticket.ticketStatus,
        ticketIndex: index + 1,
        ticketTotal: ticketTotal,
        qrCodeValue: ticket.qrCodeValue,
        skuName: orderItem.skuName,
        seatInfo: ticket.seatInfo,
        audienceName: audience === undefined ? '观演人信息异常' : audience.realName,
        certificateType: audience?.certificateType,
        maskedCertificateNo: audience === undefined ? '-' : MaskUtil.maskCertificateNo(audience.certificateNo),
        abnormalReason: ticket.abnormalReason
      }
    })
  }

  private isValidOpenTicket(tickets: ElectronicTicket[], ticketId: string | undefined): boolean {
    if (ticketId === undefined || ticketId.length === 0) {
      return true
    }

    const existTicket: ElectronicTicket | undefined = tickets.find((item: ElectronicTicket) => item.ticketId === ticketId)
    return existTicket !== undefined
  }
}
