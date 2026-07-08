import { Order } from '../model/entity/Order'
import { OrderItem } from '../model/entity/OrderItem'
import { TicketSku } from '../model/entity/TicketSku'
import { ElectronicTicket } from '../model/entity/ElectronicTicket'
import { OrderAudience } from '../model/entity/OrderAudience'

import { OrderStatus } from '../model/enums/OrderStatus'
import { PayMethod } from '../model/enums/PayMethod'
import { TicketStatus } from '../model/enums/TicketStatus'

import { DateTimeUtil } from '../utils/DateTimeUtil'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { IdGenerator } from '../utils/IdGenerator'

import { OrderDataHelper } from './order/OrderDataHelper'
import { OrderStockService } from './order/OrderStockService'
import { OrderTicketService } from './order/OrderTicketService'

export interface MockPaySuccessResponse {
  orderId: string
  orderNo: string
  orderStatus: OrderStatus
  payAmount: number
  payTime: string
}

/**
 * 支付 Repository。
 * 支付成功后：订单变 WAIT_USE，库存从锁定转已售，创建电子票，初始状态 GENERATING。
 *
 * 说明：支付本身只保留对外入口；订单查询、库存扣减、到期出票复用订单模块已有服务，避免重复维护。
 */
export class PayRepository {
  private dataHelper: OrderDataHelper = new OrderDataHelper()
  private stockService: OrderStockService = new OrderStockService()
  private ticketService: OrderTicketService = new OrderTicketService(this.dataHelper)

  mockPaySuccess(orderId: string, payMethod: PayMethod = PayMethod.ALIPAY): MockPaySuccessResponse | undefined {
    const order: Order | undefined = this.dataHelper.findOrderById(orderId)
    if (order === undefined || order.orderStatus !== OrderStatus.WAIT_PAY) {
      return undefined
    }

    if (this.isOrderExpired(order)) {
      return undefined
    }

    const orderItem: OrderItem | undefined = this.dataHelper.findOrderItem(orderId)
    if (orderItem === undefined) {
      return undefined
    }

    const sku: TicketSku | undefined = this.dataHelper.findSku(orderItem.skuId)
    if (sku === undefined) {
      return undefined
    }

    this.stockService.deductLockedStockAfterPay(sku, orderItem.quantity)

    const nowTime: string = DateTimeUtil.now()
    order.orderStatus = OrderStatus.WAIT_USE
    order.payMethod = payMethod
    order.payTime = nowTime

    let ticketChanged: boolean = this.createElectronicTickets(order, orderItem)
    if (this.ticketService.issueDueTicketsForOrder(order)) {
      ticketChanged = true
    }

    if (ticketChanged) {
      AppStorageVersionUtil.bumpTicketChangedVersion()
    }

    AppStorageVersionUtil.bumpOrderChangedVersion()

    const result: MockPaySuccessResponse = {
      orderId: order.orderId,
      orderNo: order.orderNo,
      orderStatus: order.orderStatus,
      payAmount: order.payAmount,
      payTime: nowTime
    }
    return result
  }

  private isOrderExpired(order: Order): boolean {
    if (order.payExpireTime === undefined || order.payExpireTime.length === 0) {
      return false
    }

    return DateTimeUtil.toTimeMillis(order.payExpireTime) <= new Date().getTime()
  }

  private createElectronicTickets(order: Order, orderItem: OrderItem): boolean {
    const existTickets: ElectronicTicket[] = this.dataHelper.findTickets(order.orderId)
    if (existTickets.length > 0) {
      return false
    }

    const orderAudiences: OrderAudience[] = this.dataHelper.findOrderAudiences(order.orderId)
      .sort((a: OrderAudience, b: OrderAudience) => a.orderAudienceId.localeCompare(b.orderAudienceId))

    if (orderAudiences.length < orderItem.quantity) {
      return false
    }

    for (let i = 0; i < orderItem.quantity; i++) {
      const ticket: ElectronicTicket = {
        ticketId: IdGenerator.createTicketId(i + 1),
        orderId: order.orderId,
        orderItemId: orderItem.orderItemId,
        orderAudienceId: orderAudiences[i].orderAudienceId,
        ticketStatus: TicketStatus.GENERATING,
        seatInfo: this.createMockSeatInfo(i)
      }
      this.dataHelper.getTicketStore().push(ticket)
    }

    return true
  }

  private createMockSeatInfo(index: number): string {
    const seatNo: number = 16 + index
    return `内场 A3 区 8 排 ${seatNo} 座`
  }
}
