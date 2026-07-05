import { Order } from '../model/entity/Order'
import { OrderItem } from '../model/entity/OrderItem'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { RefundRecord } from '../model/entity/RefundRecord'
import { RefundRule } from '../model/entity/RefundRule'
import { TicketSku } from '../model/entity/TicketSku'
import { OrderStatus } from '../model/enums/OrderStatus'
import { RefundType } from '../model/enums/RefundType'
import { TicketStatus } from '../model/enums/TicketStatus'
import { RefundApplyPageVO } from '../model/vo/order/RefundApplyPageVO'
import { DateTimeUtil } from '../utils/DateTimeUtil'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { PerformanceDataUtil } from '../utils/PerformanceDataUtil'
import { TicketDataUtil } from '../utils/TicketDataUtil'
import {
  RefundAmountResult,
  RefundDataUtil
} from '../utils/RefundDataUtil'

export interface RefundOrderRequest {
  userId: string
  reason?: string
  tickets?: string[]
}

export interface RefundOrderResponse {
  refundId: string
  status: 'REFUNDING'
  expectedRefundAmount: number
}

/**
 * 退款 Repository。
 *
 * 对外保留退款申请页、提交退款、模拟退款成功、退款规则/记录查询；
 * 退款规则查找、手续费计算、退款记录写入复用 RefundDataUtil，
 * 项目/场次/场馆/票档等基础数据查找复用 PerformanceDataUtil / TicketDataUtil。
 */
export class RefundRepository {
  refundOrder(orderId: string, request: RefundOrderRequest): RefundOrderResponse | undefined {
    const order: Order | undefined = TicketDataUtil.findUserOrder(request.userId, orderId)

    if (order === undefined || order.orderStatus !== OrderStatus.WAIT_USE) {
      return undefined
    }

    const refundAmountResult: RefundAmountResult | undefined = this.calculateRefundAmount(order)

    if (refundAmountResult === undefined) {
      return undefined
    }

    const refundRecord: RefundRecord = RefundDataUtil.createRefundingRecord(
      order.orderId,
      refundAmountResult.refundAmount,
      refundAmountResult.feeAmount
    )

    order.orderStatus = OrderStatus.REFUNDING
    this.expireRefundTickets(order.orderId, request.tickets)
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()

    return {
      refundId: refundRecord.refundId,
      status: 'REFUNDING',
      expectedRefundAmount: refundRecord.refundAmount
    }
  }

  getRefundApplyPage(userId: string, orderId: string): RefundApplyPageVO | undefined {
    const order: Order | undefined = TicketDataUtil.findUserOrder(userId, orderId)

    if (order === undefined) {
      return undefined
    }

    const session: PerformanceSession | undefined = PerformanceDataUtil.findSession(order.sessionId)
    const project: PerformanceProject | undefined = PerformanceDataUtil.findProject(order.projectId)
    const orderItem: OrderItem | undefined = TicketDataUtil.findOrderItem(order.orderId)

    if (session === undefined || project === undefined || orderItem === undefined) {
      return undefined
    }

    const sku: TicketSku | undefined = PerformanceDataUtil.findSku(orderItem.skuId)

    if (sku === undefined) {
      return undefined
    }

    const rule: RefundRule | undefined = RefundDataUtil.findRefundRule(order.projectId)

    if (rule === undefined) {
      return undefined
    }

    const feeRate: number | undefined = RefundDataUtil.calculateFeeRate(rule, session.startTime)
    const canRefund: boolean = this.canRefundOrder(order, rule, feeRate)
    const amountResult: RefundAmountResult = canRefund ?
      RefundDataUtil.calculateRefundAmount(order.payAmount, feeRate ?? 0) :
      { feeAmount: 0, refundAmount: 0 }

    return {
      orderId: order.orderId,
      projectTitle: project.title,
      posterUrl: project.posterUrl,
      startTime: session.startTime,
      venueName: PerformanceDataUtil.getVenueName(session.venueId),
      venueAddress: PerformanceDataUtil.getVenueAddress(session.venueId),
      skuName: orderItem.skuName,
      quantity: orderItem.quantity,
      payAmount: order.payAmount,
      estimatedRefundAmount: amountResult.refundAmount,
      feeAmount: amountResult.feeAmount,
      refundType: rule.refundType,
      refundRuleText: rule.ruleText,
      canRefund: canRefund
    }
  }

  mockRefundSuccess(refundId: string): boolean {
    const refundRecord: RefundRecord | undefined = RefundDataUtil.findRefundRecord(refundId)

    if (refundRecord === undefined) {
      return false
    }

    const order: Order | undefined = TicketDataUtil.findOrder(refundRecord.orderId)

    if (order === undefined) {
      return false
    }

    const refundTime: string = DateTimeUtil.now()
    refundRecord.status = 'REFUND_SUCCESS'
    refundRecord.refundTime = refundTime

    order.orderStatus = OrderStatus.REFUND_SUCCESS
    this.expireRefundTickets(order.orderId)
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()

    return true
  }

  getRefundRule(projectId: string, _sessionId?: string): RefundRule | undefined {
    return RefundDataUtil.findRefundRule(projectId)
  }

  getRefundRecords(orderId: string): RefundRecord[] {
    return RefundDataUtil.getRefundRecords(orderId)
  }

  private calculateRefundAmount(order: Order): RefundAmountResult | undefined {
    const session: PerformanceSession | undefined = PerformanceDataUtil.findSession(order.sessionId)

    if (session === undefined) {
      return undefined
    }

    const rule: RefundRule | undefined = RefundDataUtil.findRefundRule(order.projectId)

    if (rule === undefined || rule.refundType === RefundType.NO_REFUND) {
      return undefined
    }

    const feeRate: number | undefined = RefundDataUtil.calculateFeeRate(rule, session.startTime)

    if (feeRate === undefined) {
      return undefined
    }

    return RefundDataUtil.calculateRefundAmount(order.payAmount, feeRate)
  }

  private canRefundOrder(order: Order, rule: RefundRule, feeRate: number | undefined): boolean {
    return order.orderStatus === OrderStatus.WAIT_USE &&
      rule.refundType !== RefundType.NO_REFUND &&
      feeRate !== undefined
  }

  private expireRefundTickets(orderId: string, ticketIds?: string[]): void {
    const nowTime: string = DateTimeUtil.now()

    TicketDataUtil.getTicketsByOrderId(orderId).forEach((ticket) => {
      const matchTicket: boolean = ticketIds === undefined || ticketIds.includes(ticket.ticketId)

      if (matchTicket) {
        ticket.ticketStatus = TicketStatus.EXPIRED
        ticket.expireTime = nowTime
      }
    })
  }
}
