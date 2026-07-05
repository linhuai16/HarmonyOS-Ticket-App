import {
  orderMockList,
  orderItemMockList,
  electronicTicketMockList,
  orderAudienceMockList,
  orderAddressMockList,
  performanceProjectMockList,
  performanceSessionMockList,
  ticketSkuMockList,
  audienceMockList,
  userAddressMockList,
  refundRecordMockList,
  categoryMockList,
  venueMockList
} from '../mock/MockIndex'

import { Order } from '../model/entity/Order'
import { OrderItem } from '../model/entity/OrderItem'
import { ElectronicTicket } from '../model/entity/ElectronicTicket'
import { OrderAudience } from '../model/entity/OrderAudience'
import { OrderAddress } from '../model/entity/OrderAddress'
import { PerformanceProject } from '../model/entity/PerformanceProject'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { TicketSku } from '../model/entity/TicketSku'
import { Audience } from '../model/entity/Audience'
import { UserAddress } from '../model/entity/UserAddress'
import { RefundRecord } from '../model/entity/RefundRecord'
import { ServiceTag } from '../model/entity/ServiceTag'
import { Category } from '../model/entity/Category'
import { Venue } from '../model/entity/Venue'

import { OrderStatus } from '../model/enums/OrderStatus'
import { DeliveryType } from '../model/enums/DeliveryType'
import { SkuStatus } from '../model/enums/SkuStatus'
import { TicketStatus } from '../model/enums/TicketStatus'

import {
  SubmitOrderPageVO,
  SubmitOrderPerformanceVO,
  SubmitOrderItemVO,
  SubmitOrderPriceDetailVO
} from '../model/vo/order/SubmitOrderPageVO'
import {
  OrderListPageVO,
  OrderListItemVO
} from '../model/vo/order/OrderListPageVO'
import {
  OrderDetailVO,
  OrderDetailItemVO,
  OrderDetailAudienceVO,
  OrderDetailAddressVO
} from '../model/vo/order/OrderDetailVO'
import { ServiceTagVO } from '../model/vo/performance/PerformanceDetailVO'
import { SessionStatus } from '../model/enums/SessionStatus'

export interface ConfirmOrderRequest {
  projectId: string
  sessionId: string
  skuId: string
  quantity: number
}

export interface CreateOrderRequest {
  userId: string
  projectId: string
  sessionId: string
  skuId: string
  quantity: number
  audienceIds: string[]
  deliveryType: DeliveryType
  addressId?: string
}

export interface CreateOrderResponse {
  orderId: string
  orderNo: string
  orderStatus: OrderStatus
  payAmount: number
  payExpireTime: string
}

export enum OrderListTab {
  ALL = 'ALL',
  WAIT_PAY = 'WAIT_PAY',
  WAIT_USE = 'WAIT_USE',
  FINISHED = 'FINISHED'
}

type OrderActionType = 'CONTINUE_PAY' | 'VIEW_TICKET' | 'TICKETING' | 'NONE'

const PAY_EXPIRE_MINUTES: number = 15
const KEY_ORDER_CHANGED_VERSION: string = 'order_changed_version'
const KEY_TICKET_CHANGED_VERSION: string = 'ticket_changed_version'
const TICKET_ISSUE_BEFORE_HOURS: number = 24 * 7

class TicketSelectionValidationResult {
  project: PerformanceProject
  session: PerformanceSession
  sku: TicketSku

  constructor(project: PerformanceProject, session: PerformanceSession, sku: TicketSku) {
    this.project = project
    this.session = session
    this.sku = sku
  }
}

/**
 * OrderRepository
 *
获取提交订单页数据
提交订单
Mock 支付成功
订单列表
订单详情
取消超时未支付订单
 * 职责：订单页 VO 聚合 + 下单校验 + 锁库存 + 创建订单相关快照。
 */
export class OrderRepository {
  private lastErrorMessage: string = ''

  getLastErrorMessage(): string {
    return this.lastErrorMessage
  }


  /**
   1. 提交订单
   */
  async getSubmitOrderPage(request: ConfirmOrderRequest): Promise<SubmitOrderPageVO | undefined> {
    const validationResult: TicketSelectionValidationResult | undefined = this.validateTicketSelection(
      request.projectId,
      request.sessionId,
      request.skuId,
      request.quantity
    )

    if (validationResult === undefined) {
      return undefined
    }

    const result: SubmitOrderPageVO = this.buildSubmitOrderPageVO(
      validationResult.project,
      validationResult.session,
      validationResult.sku,
      request.quantity
    )

    return result
  }

  /**
   2. 创建订单
   */
  async createOrder(request: CreateOrderRequest): Promise<CreateOrderResponse | undefined> {
    const validationResult: TicketSelectionValidationResult | undefined = this.validateTicketSelection(
      request.projectId,
      request.sessionId,
      request.skuId,
      request.quantity
    )

    if (validationResult === undefined) {
      return undefined
    }

    const project: PerformanceProject = validationResult.project
    const session: PerformanceSession = validationResult.session
    const sku: TicketSku = validationResult.sku

    if (request.deliveryType !== session.deliveryType) {
      this.lastErrorMessage = '配送方式与当前场次不匹配'
      return undefined
    }

    if (request.audienceIds.length !== request.quantity) {
      this.lastErrorMessage = '请选择与购票数量一致的观演人'
      return undefined
    }

    const audiences: Audience[] = this.findAudiences(request.userId, request.audienceIds)
    if (audiences.length !== request.quantity) {
      this.lastErrorMessage = '观演人信息不存在，请重新选择观演人'
      return undefined
    }

    if (this.hasDuplicateCertificateInSameOrderScope(request.userId, request.projectId, request.sessionId, request.skuId, audiences)) {
      this.lastErrorMessage = '当前观演人已购买过该演出的当前场次当前票档，请更换观演人'
      return undefined
    }

    let address: UserAddress | undefined = undefined
    if (request.deliveryType === DeliveryType.PAPER_TICKET) {
      if (request.addressId === undefined || request.addressId.length === 0) {
        this.lastErrorMessage = '请选择收货地址'
        return undefined
      }
      address = this.findAddress(request.userId, request.addressId)
      if (address === undefined) {
        this.lastErrorMessage = '收货地址不存在，请重新选择地址'
        return undefined
      }
    }

    this.lockStock(sku, request.quantity)

    const nowTime: string = this.getNowTime()
    const payExpireTime: string = this.addMinutes(nowTime, PAY_EXPIRE_MINUTES)
    const orderId: string = this.createOrderId()
    const orderNo: string = this.createOrderNo()
    const ticketAmount: number = sku.price * request.quantity

    const order: Order = {
      orderId: orderId,
      orderNo: orderNo,
      userId: request.userId,
      projectId: project.projectId,
      sessionId: session.sessionId,
      orderStatus: OrderStatus.WAIT_PAY,
      totalAmount: ticketAmount,
      payAmount: ticketAmount,
      deliveryType: request.deliveryType,
      createTime: nowTime,
      payExpireTime: payExpireTime,
    }
    orderMockList.push(order)

    const orderItem: OrderItem = {
      orderItemId: this.createOrderItemId(),
      orderId: orderId,
      skuId: sku.skuId,
      skuName: sku.skuName,
      unitPrice: sku.price,
      quantity: request.quantity,
      subtotalAmount: ticketAmount,
    }
    orderItemMockList.push(orderItem)

    this.createOrderAudienceSnapshots(orderId, audiences)

    if (request.deliveryType === DeliveryType.PAPER_TICKET && address !== undefined) {
      this.createOrderAddressSnapshot(orderId, address)
    }

    const response: CreateOrderResponse = {
      orderId: order.orderId,
      orderNo: order.orderNo,
      orderStatus: order.orderStatus,
      payAmount: order.payAmount,
      payExpireTime: order.payExpireTime === undefined ? '' : order.payExpireTime
    }

    this.bumpOrderChangedVersion()
    return response
  }

  /**
   3. 订单列表
   */
  async getOrderList(
    userId: string,
    tab: OrderListTab = OrderListTab.ALL,
    pageNo: number = 1,
    pageSize: number = 10
  ): Promise<OrderListPageVO> {
    this.cancelExpiredWaitPayOrders()  //取消超时未支付订单
    this.issueDueTicketsForUser(userId)

    const startIndex: number = (pageNo - 1) * pageSize
    const orders: Order[] = orderMockList
      .filter((item: Order) => item.userId === userId)
      .filter((item: Order) => this.matchOrderListTab(item, tab))
      .sort((a: Order, b: Order) => this.toTimeMillis(b.createTime) - this.toTimeMillis(a.createTime))

    const pageOrders: Order[] = orders.slice(startIndex, startIndex + pageSize)
    const itemList: OrderListItemVO[] = []



    pageOrders.forEach((order: Order) => {
      const item: OrderListItemVO | undefined = this.buildOrderListItemVO(order)
      if (item !== undefined) {
        itemList.push(item)
      }
    })

    const result: OrderListPageVO = {
      orders: itemList,
      hasMore: startIndex + pageSize < orders.length
    }
    return result
  }

  /**
   4.  订单详情
   */
  async getOrderDetail(userId: string, orderId: string): Promise<OrderDetailVO | undefined> {
    this.cancelOrderIfExpired(orderId)  //取消 超时未支付

    const order: Order | undefined = orderMockList.find((item: Order) => {
      return item.userId === userId && item.orderId === orderId
    })


    if (order === undefined) {
      return undefined
    }

    if (this.issueDueTicketsForOrder(order)) {
      this.bumpOrderChangedVersion()
      this.bumpTicketChangedVersion()
    }

    const project: PerformanceProject | undefined = this.findProject(order.projectId)
    const session: PerformanceSession | undefined = this.findSession(order.sessionId)
    if (project === undefined || session === undefined) {
      return undefined
    }

    const orderItems: OrderItem[] = orderItemMockList.filter((item: OrderItem) => item.orderId === order.orderId)

    const result: OrderDetailVO = {
      orderId: order.orderId,
      orderNo: order.orderNo,
      orderStatus: order.orderStatus,
      posterUrl: project.posterUrl,
      categoryName: this.getCategoryName(project.categoryId),
      projectTitle: project.title,
      startTime: session.startTime,
      venueName: this.getVenueName(session.venueId),
      venueAddress: this.getVenueAddress(session.venueId),
      orderItems: this.buildOrderDetailItems(orderItems),
      audiences: this.buildOrderDetailAudiences(order.orderId),
      deliveryType: order.deliveryType,
      address: this.buildOrderDetailAddress(order.orderId),
      createTime: order.createTime,
      payExpireTime: order.payExpireTime,
      payTime: order.payTime,
      ticketIssuedTime: this.buildTicketIssuedTime(order),
      cancelTime: order.cancelTime,
      finishTime: order.finishTime,
      refundTime: this.getRefundTime(order.orderId),
      totalAmount: order.totalAmount,
      serviceFee: this.sumServiceFee(orderItems),
      deliveryFee: this.sumDeliveryFee(orderItems),
      payAmount: order.payAmount,
      payMethod: order.payMethod,
      refundAmount: this.getRefundAmount(order.orderId),
      refundFeeAmount: this.getRefundFeeAmount(order.orderId),
      projectId: order.projectId,
      sessionId: order.sessionId,
      ticketActionType: this.buildOrderDetailTicketActionType(order),
      defaultTicketId: this.getDefaultViewTicketId(order.orderId)
    }

    return result
  }

  /**
   * 主动取消待支付订单
   */
  async cancelOrder(userId: string, orderId: string): Promise<boolean> {
    this.lastErrorMessage = ''

    const order: Order | undefined = orderMockList.find((item: Order) => {
      return item.userId === userId && item.orderId === orderId
    })

    if (order === undefined) {
      this.lastErrorMessage = '订单不存在'
      return false
    }

    if (order.orderStatus !== OrderStatus.WAIT_PAY) {
      this.lastErrorMessage = '当前订单不可取消'
      return false
    }

    return this.cancelWaitPayOrder(order)
  }

  /**
   5. 取消 超时未支付订单 方法
   */
  cancelExpiredWaitPayOrders(): number {
    let cancelCount: number = 0
    const nowTime: number = new Date().getTime()

    orderMockList.forEach((order: Order) => {
      if (order.orderStatus !== OrderStatus.WAIT_PAY) {
        return
      }

      if (order.payExpireTime === undefined || order.payExpireTime.length === 0) {
        return
      }

      const expireTime: number = this.toTimeMillis(order.payExpireTime)

      if (expireTime <= nowTime) {
        const success: boolean = this.cancelWaitPayOrder(order)
        if (success) {
          cancelCount++
        }
      }
    })

    return cancelCount
  }

  cancelOrderIfExpired(orderId: string): boolean {
    const order: Order | undefined = orderMockList.find((item: Order) => {
      return item.orderId === orderId
    })

    if (order === undefined) {
      return false
    }

    if (order.orderStatus !== OrderStatus.WAIT_PAY) {
      return false
    }

    if (order.payExpireTime === undefined || order.payExpireTime.length === 0) {
      return false
    }

    const nowTime: number = new Date().getTime()
    const expireTime: number = this.toTimeMillis(order.payExpireTime)

    if (expireTime > nowTime) {
      return false
    }

    return this.cancelWaitPayOrder(order)
  }

  private cancelWaitPayOrder(order: Order): boolean {
    const orderItems: OrderItem[] = orderItemMockList.filter((item: OrderItem) => {
      return item.orderId === order.orderId
    })

    if (orderItems.length === 0) {
      order.orderStatus = OrderStatus.CANCELED
      order.cancelTime = this.getNowTime()
      this.bumpOrderChangedVersion()
      return true
    }

    orderItems.forEach((item: OrderItem) => {
      const sku: TicketSku | undefined = this.findSku(item.skuId)

      if (sku !== undefined) {
        this.releaseLockedStock(sku, item.quantity)
      }
    })

    order.orderStatus = OrderStatus.CANCELED
    order.cancelTime = this.getNowTime()
    this.bumpOrderChangedVersion()

    return true
  }
  //释放锁定库存
  private releaseLockedStock(sku: TicketSku, quantity: number): void {
    const currentLocked: number = sku.stockLocked === undefined ? 0 : sku.stockLocked
    const currentAvailable: number = sku.stockAvailable === undefined ? 0 : sku.stockAvailable

    const releaseCount: number = currentLocked >= quantity ? quantity : currentLocked

    sku.stockLocked = currentLocked - releaseCount
    sku.stockAvailable = currentAvailable + releaseCount
  }


  /**
   *
   为了显示 查看电子票 按钮，需要获得电子票状态
   */
  private buildOrderDetailTicketActionType(order: Order): 'VIEW_TICKET' | 'TICKETING' | 'NONE' {
    if (order.orderStatus !== OrderStatus.WAIT_USE) {
      return 'NONE'
    }

    const tickets: ElectronicTicket[] = electronicTicketMockList.filter((item: ElectronicTicket) => {
      return item.orderId === order.orderId
    })

    const hasUnused: boolean = tickets.some((item: ElectronicTicket) => {
      return item.ticketStatus === TicketStatus.UNUSED
    })

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

  private getDefaultViewTicketId(orderId: string): string | undefined {
    const ticket: ElectronicTicket | undefined = electronicTicketMockList.find((item: ElectronicTicket) => {
      return item.orderId === orderId && item.ticketStatus === TicketStatus.UNUSED
    })

    return ticket?.ticketId
  }

  async getOrdersByUserId(userId: string): Promise<Order[]> {
    return orderMockList.filter((item: Order) => item.userId === userId)
  }


  async getOrdersByStatus(userId: string, orderStatus?: OrderStatus): Promise<Order[]> {
    const orders: Order[] = orderMockList.filter((item: Order) => item.userId === userId)
    if (orderStatus === undefined) {
      return orders
    }
    return orders.filter((item: Order) => item.orderStatus === orderStatus)
  }

  async getOrderById(orderId: string): Promise<Order | undefined> {
    return orderMockList.find((item: Order) => item.orderId === orderId)
  }

  async getOrderItems(orderId: string): Promise<OrderItem[]> {
    return orderItemMockList.filter((item: OrderItem) => item.orderId === orderId)
  }

  async getOrderAudiences(orderId: string): Promise<OrderAudience[]> {
    return orderAudienceMockList.filter((item: OrderAudience) => item.orderId === orderId)
  }

  async getElectronicTickets(orderId: string): Promise<ElectronicTicket[]> {
    return electronicTicketMockList.filter((item: ElectronicTicket) => item.orderId === orderId)
  }

  async getFirstElectronicTicket(orderId: string): Promise<ElectronicTicket | undefined> {
    return electronicTicketMockList.find((item: ElectronicTicket) => item.orderId === orderId)
  }

  /**
   * 订单页也需要遵守出票真实状态流转：开演前一周出票。
   * 否则订单详情/列表中的“出票中/查看电子票”状态可能与票夹页不同步。
   */
  private issueDueTicketsForUser(userId: string): void {
    let changed: boolean = false

    orderMockList
      .filter((order: Order) => {
        return order.userId === userId && order.orderStatus === OrderStatus.WAIT_USE
      })
      .forEach((order: Order) => {
        if (this.issueDueTicketsForOrder(order)) {
          changed = true
        }
      })

    if (changed) {
      this.bumpOrderChangedVersion()
      this.bumpTicketChangedVersion()
    }
  }

  private issueDueTicketsForOrder(order: Order): boolean {
    if (order.orderStatus !== OrderStatus.WAIT_USE) {
      return false
    }

    const session: PerformanceSession | undefined = this.findSession(order.sessionId)

    if (session === undefined) {
      return false
    }

    const expectedIssueTime: string = this.buildExpectedIssueTime(session)
    if (this.toTimeMillis(expectedIssueTime) > new Date().getTime()) {
      return false
    }

    const generatingTickets: ElectronicTicket[] = electronicTicketMockList.filter((item: ElectronicTicket) => {
      return item.orderId === order.orderId && item.ticketStatus === TicketStatus.GENERATING
    })

    if (generatingTickets.length === 0) {
      return false
    }

    const nowTime: string = this.getNowTime()

    generatingTickets.forEach((ticket: ElectronicTicket) => {
      ticket.ticketStatus = TicketStatus.UNUSED
      ticket.qrCodeValue = this.createQrCodeValue(ticket.ticketId)
      ticket.generateTime = nowTime
    })

    order.ticketIssuedTime = nowTime
    return true
  }

  private createQrCodeValue(ticketId: string): string {
    return `MM_TICKET_QR_CODE_${ticketId}_${new Date().getTime()}`
  }

  private bumpTicketChangedVersion(): void {
    const currentVersion: number | undefined = AppStorage.get<number>(KEY_TICKET_CHANGED_VERSION)
    AppStorage.setOrCreate(KEY_TICKET_CHANGED_VERSION, (currentVersion ?? 0) + 1)
  }

  private buildOrderListItemVO(order: Order): OrderListItemVO | undefined {
    const project: PerformanceProject | undefined = this.findProject(order.projectId)
    const session: PerformanceSession | undefined = this.findSession(order.sessionId)
    const orderItem: OrderItem | undefined = orderItemMockList.find((item: OrderItem) => item.orderId === order.orderId)

    if (project === undefined || session === undefined || orderItem === undefined) {
      return undefined
    }

    const vo: OrderListItemVO = {
      orderId: order.orderId,
      orderNo: order.orderNo,
      orderStatus: order.orderStatus,
      posterUrl: project.posterUrl,
      projectTitle: project.title,
      startTime: session.startTime,
      venueName: this.getVenueName(session.venueId),
      skuName: orderItem.skuName,
      unitPrice: orderItem.unitPrice,
      quantity: orderItem.quantity,
      payAmount: order.payAmount,
      actionType: this.buildOrderActionType(order)
    }
    return vo
  }

  private getCategoryName(categoryId: string): string {
    const category: Category | undefined = categoryMockList.find((item: Category) => {
      return item.categoryId === categoryId
    })

    return category?.categoryName ?? ''
  }

  private getVenueName(venueId: string): string {
    const venue: Venue | undefined = venueMockList.find((item: Venue) => {
      return item.venueId === venueId
    })

    return venue?.venueName ?? ''
  }

  private getVenueAddress(venueId: string): string {
    const venue: Venue | undefined = venueMockList.find((item: Venue) => {
      return item.venueId === venueId
    })

    return venue?.address ?? ''
  }

  private buildOrderActionType(order: Order): OrderActionType {
    if (order.orderStatus === OrderStatus.WAIT_PAY) {
      return 'CONTINUE_PAY'
    }

    if (order.orderStatus === OrderStatus.WAIT_USE) {
      const tickets: ElectronicTicket[] = electronicTicketMockList.filter((item: ElectronicTicket) => {
        return item.orderId === order.orderId
      })

      const hasUnused: boolean = tickets.some((item: ElectronicTicket) => item.ticketStatus === TicketStatus.UNUSED)
      if (hasUnused) {
        return 'VIEW_TICKET'
      }

      const hasGenerating: boolean = tickets.some((item: ElectronicTicket) => {
        return item.ticketStatus === TicketStatus.GENERATING || item.ticketStatus === TicketStatus.ERROR
      })
      if (hasGenerating) {
        return 'TICKETING'
      }
    }

    return 'NONE'
  }

  private buildOrderDetailItems(items: OrderItem[]): OrderDetailItemVO[] {
    const result: OrderDetailItemVO[] = []
    items.forEach((item: OrderItem) => {
      const vo: OrderDetailItemVO = {
        skuName: item.skuName,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        subtotalAmount: item.subtotalAmount
      }
      result.push(vo)
    })
    return result
  }

  private buildOrderDetailAudiences(orderId: string): OrderDetailAudienceVO[] {
    const result: OrderDetailAudienceVO[] = []
    orderAudienceMockList
      .filter((item: OrderAudience) => item.orderId === orderId)
      .forEach((item: OrderAudience) => {
        const vo: OrderDetailAudienceVO = {
          realName: item.realName,
          maskedCertificateNo: this.maskCertificateNo(item.certificateNo),
          maskedPhone: item.phone === undefined ? undefined : this.maskPhone(item.phone)
        }
        result.push(vo)
      })
    return result
  }

  private buildOrderDetailAddress(orderId: string): OrderDetailAddressVO | undefined {
    const address: OrderAddress | undefined = orderAddressMockList.find((item: OrderAddress) => item.orderId === orderId)
    if (address === undefined) {
      return undefined
    }

    const vo: OrderDetailAddressVO = {
      receiverName: address.receiverName,
      receiverPhone: this.maskPhone(address.receiverPhone),
      fullAddress: `${address.province}${address.city}${address.district}${address.detailAddress}`
    }
    return vo
  }

  private buildServiceTagVOList(tags?: ServiceTag[]): ServiceTagVO[] {
    const result: ServiceTagVO[] = []
    if (tags === undefined) {
      return result
    }

    tags
      .slice()
      .sort((a: ServiceTag, b: ServiceTag) => a.sortOrder - b.sortOrder)
      .forEach((tag: ServiceTag) => {
        const vo: ServiceTagVO = {
          tagId: tag.tagId,
          tagName: tag.tagName,
          iconUrl: tag.iconUrl,
          description: tag.description
        }
        result.push(vo)
      })
    return result
  }

  /**
   * 统一校验当前选择的演出/场次/票档是否仍然可买。
   *
   * 说明：提交订单页展示后，Mock 库存、票档状态、场次状态仍可能被其他操作改变，
   * 所以 createOrder 不能依赖页面加载时的旧结果，必须在真正锁库存前再次校验。
   */
  private validateTicketSelection(
    projectId: string,
    sessionId: string,
    skuId: string,
    quantity: number
  ): TicketSelectionValidationResult | undefined {
    this.lastErrorMessage = ''

    if (quantity <= 0) {
      this.lastErrorMessage = '购票数量不正确'
      return undefined
    }

    const project: PerformanceProject | undefined = this.findProject(projectId)
    const session: PerformanceSession | undefined = this.findSession(sessionId)
    const sku: TicketSku | undefined = this.findSku(skuId)

    if (project === undefined || session === undefined || sku === undefined) {
      this.lastErrorMessage = '订单数据不存在，请重新选择票档'
      return undefined
    }

    if (session.projectId !== projectId) {
      this.lastErrorMessage = '场次与当前演出不匹配，请重新选择场次'
      return undefined
    }

    if (sku.projectId !== projectId || sku.sessionId !== sessionId) {
      this.lastErrorMessage = '票档与当前场次不匹配，请重新选择票档'
      return undefined
    }

    if (!this.canBuySession(session)) {
      this.lastErrorMessage = '当前场次不可购买'
      return undefined
    }

    if (quantity > session.limitPerOrder) {
      this.lastErrorMessage = `每单最多购买 ${session.limitPerOrder} 张`
      return undefined
    }

    if (!this.canBuySku(sku, quantity)) {
      this.lastErrorMessage = '票档不可购买或库存不足，请重新选择票档'
      return undefined
    }

    return new TicketSelectionValidationResult(project, session, sku)
  }

  private buildSubmitOrderPageVO(
    project: PerformanceProject,
    session: PerformanceSession,
    sku: TicketSku,
    quantity: number
  ): SubmitOrderPageVO {
    const deliveryType: DeliveryType = session.deliveryType
    const ticketAmount: number = sku.price * quantity

    const performance: SubmitOrderPerformanceVO = {
      projectId: project.projectId,
      sessionId: session.sessionId,
      projectTitle: project.title,
      venueName: this.getVenueName(session.venueId),
      venueAddress: this.getVenueAddress(session.venueId),
      startTime: session.startTime
    }

    const orderItem: SubmitOrderItemVO = {
      skuId: sku.skuId,
      skuName: sku.skuName,
      unitPrice: sku.price,
      quantity: quantity
    }

    const priceDetail: SubmitOrderPriceDetailVO = {
      ticketAmount: ticketAmount,
      serviceFee: 0,
      deliveryFee: 0,
      discountAmount: 0,
      totalAmount: ticketAmount,
      payAmount: ticketAmount
    }

    const result: SubmitOrderPageVO = {
      payExpireMinutes: PAY_EXPIRE_MINUTES,
      performance: performance,
      orderItems: [orderItem],
      serviceTags: this.buildServiceTagVOList(project.serviceTags),
      requiredAudienceCount: quantity,
      priceDetail: priceDetail,
      deliveryType: deliveryType
    }

    return result
  }

  private canBuySession(session: PerformanceSession): boolean {
    return session.sessionStatus === SessionStatus.ON_SALE || session.sessionStatus === SessionStatus.PRESALE
  }

  private canBuySku(sku: TicketSku, quantity: number): boolean {
    if (sku.skuStatus !== SkuStatus.ON_SALE && sku.skuStatus !== SkuStatus.PRESALE) {
      return false
    }

    if ((sku.stockAvailable === undefined ? 0 : sku.stockAvailable) < quantity) {
      return false
    }


    return true
  }

  private lockStock(sku: TicketSku, quantity: number): void {
    sku.stockAvailable = (sku.stockAvailable === undefined ? 0 : sku.stockAvailable) - quantity
    sku.stockLocked = (sku.stockLocked === undefined ? 0 : sku.stockLocked) + quantity
  }

  private createOrderAudienceSnapshots(orderId: string, audiences: Audience[]): void {
    audiences.forEach((audience: Audience, index: number) => {
      const snapshot: OrderAudience = {
        orderAudienceId: this.createOrderAudienceId(index),
        orderId: orderId,
        realName: audience.realName,
        certificateType: audience.certificateType,
        certificateNo: audience.certificateNo,
        phone: audience.phone
      }
      orderAudienceMockList.push(snapshot)
    })
  }

  private createOrderAddressSnapshot(orderId: string, address: UserAddress): void {
    const snapshot: OrderAddress = {
      orderAddressId: this.createOrderAddressId(),
      orderId: orderId,
      receiverName: address.receiverName,
      receiverPhone: address.receiverPhone,
      province: address.province,
      city: address.city,
      district: address.district,
      detailAddress: address.detailAddress
    }
    orderAddressMockList.push(snapshot)
  }

  private hasDuplicateCertificateInSameOrderScope(
    userId: string,
    projectId: string,
    sessionId: string,
    skuId: string,
    audiences: Audience[]
  ): boolean {
    const certificateNoList: string[] = audiences.map((item: Audience) => item.certificateNo)

    const validOrders: Order[] = orderMockList.filter((order: Order) => {
      return order.userId === userId &&
        order.projectId === projectId &&
        order.sessionId === sessionId &&
        order.orderStatus !== OrderStatus.CANCELED &&
        order.orderStatus !== OrderStatus.REFUND_SUCCESS
    })

    for (let i = 0; i < validOrders.length; i++) {
      const order: Order = validOrders[i]

      const hasSameSku: boolean = orderItemMockList.some((item: OrderItem) => {
        return item.orderId === order.orderId && item.skuId === skuId
      })

      if (!hasSameSku) {
        continue
      }

      const snapshots: OrderAudience[] = orderAudienceMockList.filter((item: OrderAudience) => {
        return item.orderId === order.orderId
      })

      for (let j = 0; j < snapshots.length; j++) {
        if (certificateNoList.indexOf(snapshots[j].certificateNo) >= 0) {
          return true
        }
      }
    }

    return false
  }

  private matchOrderListTab(order: Order, tab: OrderListTab): boolean {
    if (tab === OrderListTab.ALL) {
      return true
    }
    if (tab === OrderListTab.WAIT_PAY) {
      return order.orderStatus === OrderStatus.WAIT_PAY
    }
    if (tab === OrderListTab.WAIT_USE) {
      return order.orderStatus === OrderStatus.WAIT_USE
    }
    if (tab === OrderListTab.FINISHED) {
      return order.orderStatus === OrderStatus.FINISHED
    }
    return true
  }

  private findProject(projectId: string): PerformanceProject | undefined {
    return performanceProjectMockList.find((item: PerformanceProject) => item.projectId === projectId)
  }

  private findSession(sessionId: string): PerformanceSession | undefined {
    return performanceSessionMockList.find((item: PerformanceSession) => item.sessionId === sessionId)
  }

  private findSku(skuId: string): TicketSku | undefined {
    return ticketSkuMockList.find((item: TicketSku) => item.skuId === skuId)
  }

  private findAudiences(userId: string, audienceIds: string[]): Audience[] {
    return audienceMockList.filter((item: Audience) => {
      return item.userId === userId && audienceIds.indexOf(item.audienceId) >= 0
    })
  }

  private findAddress(userId: string, addressId: string): UserAddress | undefined {
    return userAddressMockList.find((item: UserAddress) => {
      return item.userId === userId && item.addressId === addressId
    })
  }

  private buildTicketIssuedTime(order: Order): string | undefined {
    if (order.ticketIssuedTime !== undefined) {
      return order.ticketIssuedTime
    }

    const ticket: ElectronicTicket | undefined = electronicTicketMockList.find((item: ElectronicTicket) => {
      return item.orderId === order.orderId &&
        item.generateTime !== undefined &&
        (item.ticketStatus === TicketStatus.UNUSED || item.ticketStatus === TicketStatus.CHECKED || item.ticketStatus === TicketStatus.EXPIRED)
    })

    return ticket === undefined ? undefined : ticket.generateTime
  }

  private sumServiceFee(items: OrderItem[]): number {
    return 0
  }

  private sumDeliveryFee(items: OrderItem[]): number {
    return 0
  }

  private getRefundAmount(orderId: string): number | undefined {
    const record: RefundRecord | undefined = refundRecordMockList.find((item: RefundRecord) => item.orderId === orderId)
    return record === undefined ? undefined : record.refundAmount
  }

  private getRefundFeeAmount(orderId: string): number | undefined {
    const record: RefundRecord | undefined = refundRecordMockList.find((item: RefundRecord) => item.orderId === orderId)
    return record === undefined ? undefined : record.feeAmount
  }

  private getRefundTime(orderId: string): string | undefined {
    const record: RefundRecord | undefined = refundRecordMockList.find((item: RefundRecord) => item.orderId === orderId)
    if (record === undefined || record.status !== 'REFUND_SUCCESS') {
      return undefined
    }
    return record.refundTime
  }

  private buildExpectedIssueTime(session: PerformanceSession): string {
    const time: number = this.toTimeMillis(session.startTime) - TICKET_ISSUE_BEFORE_HOURS * 60 * 60 * 1000
    return this.formatTime(new Date(time))
  }

  private maskCertificateNo(certificateNo: string): string {
    if (certificateNo.length <= 7) {
      return certificateNo
    }
    return `${certificateNo.substring(0, 3)}***********${certificateNo.substring(certificateNo.length - 4)}`
  }

  private maskPhone(phone: string): string {
    if (phone.length !== 11) {
      return phone
    }
    return `${phone.substring(0, 3)}****${phone.substring(7)}`
  }

  private bumpOrderChangedVersion(): void {
    const currentVersion: number | undefined = AppStorage.get<number>(KEY_ORDER_CHANGED_VERSION)
    AppStorage.setOrCreate(KEY_ORDER_CHANGED_VERSION, (currentVersion ?? 0) + 1)
  }

  private createOrderId(): string {
    return `order_${new Date().getTime()}_${Math.floor(Math.random() * 1000)}`
  }

  private createOrderNo(): string {
    return `MM${new Date().getTime()}${Math.floor(Math.random() * 1000)}`
  }

  private createOrderItemId(): string {
    return `order_item_${new Date().getTime()}_${Math.floor(Math.random() * 1000)}`
  }

  private createOrderAudienceId(index: number): string {
    return `order_aud_${new Date().getTime()}_${index}_${Math.floor(Math.random() * 1000)}`
  }

  private createOrderAddressId(): string {
    return `order_addr_${new Date().getTime()}_${Math.floor(Math.random() * 1000)}`
  }

  private getNowTime(): string {
    return this.formatTime(new Date())
  }

  private addMinutes(time: string, minutes: number): string {
    const date: Date = new Date(this.toTimeMillis(time) + minutes * 60 * 1000)
    return this.formatTime(date)
  }

  private formatTime(date: Date): string {
    const year: number = date.getFullYear()
    const month: string = this.pad(date.getMonth() + 1)
    const day: string = this.pad(date.getDate())
    const hour: string = this.pad(date.getHours())
    const minute: string = this.pad(date.getMinutes())
    const second: string = this.pad(date.getSeconds())
    return `${year}-${month}-${day} ${hour}:${minute}:${second}`
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`
  }

  private toTimeMillis(time: string): number {
    if (time.length === 0) {
      return 0
    }
    return new Date(time.replace(' ', 'T')).getTime()
  }
}

export const orderRepository = new OrderRepository()
