import { PayMethod } from '../model/enums/PayMethod'
import { MoneyUtil, MoneyVO } from '../model/vo/ticketsource/MoneyVO'
import { DeliveryQuoteVO } from '../model/vo/ticketsource/DeliveryQuoteVO'
import {
  AppliedPromotionVO,
  OrderActionVO,
  OrderQuoteVO,
  QuotedOrderCreateVO,
  SingleSkuQuoteItemVO
} from '../model/vo/ticketsource/OrderQuoteVO'
import {
  DeliveryMode,
  OrderTicketSelectionRequest,
  TicketMode,
  TicketPurchaseMode
} from '../model/vo/ticketsource/TicketSourceTypes'
import { TicketSourceOrderQuoteRequest } from '../model/vo/ticketsource/OrderRequestVO'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { TicketSourceOrderValidator } from '../utils/TicketSourceOrderValidator'
import { PurchaseFulfillmentOptionVO, PurchaseOptionsVO } from '../model/vo/ticketsource/PurchaseOptionVO'



interface BackendPurchaseOption {
  optionCode?: string | null
  ticketMode: string
  deliveryMode: string
  label?: string | null
  requiresAddress: boolean
  recommended: boolean
}

interface BackendPurchaseOptionsResult {
  projectId: number | string
  sessionId: number | string
  skuId: number | string
  saleable: boolean
  purchaseMode: string
  limitPerOrder?: number | null
  stockAvailable?: number | null
  stockExact: boolean
  options?: BackendPurchaseOption[]
  warnings?: string[]
}

interface BackendTicketSelection {
  clientTicketNo: string
  audienceId: number | string
}

interface BackendQuoteRequest {
  userId: number
  projectId: number
  sessionId: number
  skuId: number
  tickets: BackendTicketSelection[]
  purchaseMode: TicketPurchaseMode
  ticketMode: TicketMode
  deliveryMode: DeliveryMode
  addressId?: number
}

interface BackendMoney {
  amountMinor?: number | string | null
  currency?: string | null
}

interface BackendQuoteItem {
  skuId: number | string
  skuName: string
  quantity: number
  faceUnitPrice?: BackendMoney | null
  saleUnitPrice?: BackendMoney | null
  subtotalAmount?: BackendMoney | null
  tickets?: BackendTicketSelection[]
}

interface BackendPromotion {
  promotionType?: string | null
  title?: string | null
  discountAmount?: BackendMoney | null
}

interface BackendOrderQuoteResult {
  quoteId: string
  userId: number | string
  projectId: number | string
  sessionId: number | string
  purchaseMode: string
  ticketMode: string
  deliveryMode: string
  addressId?: number | string | null
  item: BackendQuoteItem
  promotions?: BackendPromotion[]
  totalTicketCount: number
  faceAmount?: BackendMoney | null
  ticketAmount?: BackendMoney | null
  discountAmount?: BackendMoney | null
  deliveryFeeAmount?: BackendMoney | null
  serviceFeeAmount?: BackendMoney | null
  payAmount?: BackendMoney | null
  expireTime?: string | null
  warnings?: string[]
}

interface BackendOrderCreateRequest {
  userId: number
  quoteId: string
}

interface BackendOrderCreateResult {
  orderId: number | string
  orderNo: string
  orderStatus: string
  paymentStatus: string
  fulfillmentMode: string
  ticketCount: number
  payAmount?: BackendMoney | null
  payExpireTime?: string | null
}

interface BackendOrderActionRequest {
  userId: number
  payMethod?: PayMethod
  reason?: string
}

interface BackendOrderActionResult {
  orderId: number | string
  orderNo: string
  orderStatus: string
  paymentStatus: string
  ticketCount: number
  operationTime?: string | null
  message?: string | null
}

/**
 * V1.2 单票档订单数据层。
 * 只调用麦麦用户侧安全 Facade；第三方 provider* 标识和结算成本不会进入鸿蒙端。
 * Repository 对页面只暴露 V1.2 模型，不暴露 providerCode/providerOrderId/providerSkuId 等第三方原始标识。
 */
export class TicketSourceOrderRepository {
  async getPurchaseOptions(projectId: string, sessionId: string, skuId: string): Promise<PurchaseOptionsVO> {
    if (projectId.trim().length === 0 || sessionId.trim().length === 0 || skuId.trim().length === 0) {
      throw new Error('projectId/sessionId/skuId不能为空')
    }
    const raw: BackendPurchaseOptionsResult = await ApiClient.get<BackendPurchaseOptionsResult>(
      '/api/ticket-source/orders/v12/purchase-options',
      [
        new ApiQueryParam('projectId', projectId),
        new ApiQueryParam('sessionId', sessionId),
        new ApiQueryParam('skuId', skuId)
      ]
    )
    if (String(raw.projectId) !== projectId || String(raw.sessionId) !== sessionId || String(raw.skuId) !== skuId) {
      throw new Error('履约选项与当前单票档不一致')
    }
    const options: PurchaseFulfillmentOptionVO[] = (raw.options ?? []).map(
      (item: BackendPurchaseOption): PurchaseFulfillmentOptionVO => {
        return {
          optionCode: item.optionCode ?? item.ticketMode + '_' + item.deliveryMode,
          ticketMode: this.requireTicketMode(item.ticketMode),
          deliveryMode: this.requireDeliveryMode(item.deliveryMode),
          label: item.label ?? '',
          requiresAddress: item.requiresAddress,
          recommended: item.recommended
        }
      })
    return {
      projectId: String(raw.projectId),
      sessionId: String(raw.sessionId),
      skuId: String(raw.skuId),
      saleable: raw.saleable,
      purchaseMode: this.requirePurchaseMode(raw.purchaseMode),
      limitPerOrder: raw.limitPerOrder ?? 1,
      stockAvailable: raw.stockAvailable === undefined || raw.stockAvailable === null ? undefined : Number(raw.stockAvailable),
      stockExact: raw.stockExact,
      options: options,
      warnings: raw.warnings ?? []
    }
  }
  async quoteOrder(request: TicketSourceOrderQuoteRequest): Promise<OrderQuoteVO> {
    TicketSourceOrderValidator.validateQuoteRequest(request)

    const body: BackendQuoteRequest = {
      userId: Number(request.userId),
      projectId: Number(request.projectId),
      sessionId: Number(request.sessionId),
      skuId: Number(request.skuId),
      tickets: request.tickets.map((ticket: OrderTicketSelectionRequest): BackendTicketSelection => {
        return {
          clientTicketNo: ticket.clientTicketNo.trim(),
          audienceId: Number(ticket.audienceId)
        }
      }),
      purchaseMode: request.purchaseMode ?? 'SYSTEM_ASSIGN',
      ticketMode: request.ticketMode,
      deliveryMode: request.deliveryMode
    }
    if (request.addressId !== undefined && request.addressId.length > 0) {
      body.addressId = Number(request.addressId)
    }

    const response: BackendOrderQuoteResult =
      await ApiClient.post<BackendOrderQuoteResult>('/api/ticket-source/orders/v12/quote', body)

    return this.mapQuote(request, response)
  }

  async createOrder(userId: string, quoteId: string): Promise<QuotedOrderCreateVO> {
    if (userId.trim().length === 0 || quoteId.trim().length === 0) {
      throw new Error('userId和quoteId不能为空')
    }
    const body: BackendOrderCreateRequest = {
      userId: Number(userId),
      quoteId: quoteId.trim()
    }
    const response: BackendOrderCreateResult = await ApiClient.post<BackendOrderCreateResult>(
      '/api/ticket-source/orders/v12',
      body
    )

    AppStorageVersionUtil.bumpOrderInventoryRelatedVersions()
    return {
      orderId: String(response.orderId),
      orderNo: response.orderNo,
      orderStatus: response.orderStatus,
      paymentStatus: response.paymentStatus,
      fulfillmentMode: response.fulfillmentMode,
      ticketCount: Number(response.ticketCount),
      payAmount: this.money(response.payAmount),
      payExpireTime: response.payExpireTime ?? ''
    }
  }

  async payOrder(orderId: string, userId: string, payMethod: PayMethod): Promise<OrderActionVO> {
    return this.action(orderId, userId, '/pay', payMethod, '')
  }

  async cancelOrder(orderId: string, userId: string, reason: string = ''): Promise<OrderActionVO> {
    return this.action(orderId, userId, '/cancel', undefined, reason)
  }

  private async action(orderId: string, userId: string, suffix: string,
    payMethod: PayMethod | undefined, reason: string): Promise<OrderActionVO> {
    if (orderId.trim().length === 0 || userId.trim().length === 0) {
      throw new Error('orderId和userId不能为空')
    }
    const body: BackendOrderActionRequest = {
      userId: Number(userId)
    }
    if (payMethod !== undefined) {
      body.payMethod = payMethod
    }
    if (reason.trim().length > 0) {
      body.reason = reason.trim()
    }
    const response: BackendOrderActionResult = await ApiClient.post<BackendOrderActionResult>(
      '/api/ticket-source/orders/v12/' + encodeURIComponent(orderId) + suffix,
      body
    )
    if (suffix === '/pay') {
      AppStorageVersionUtil.bumpOrderTicketRelatedVersions()
    } else {
      AppStorageVersionUtil.bumpOrderInventoryRelatedVersions()
    }
    return {
      orderId: String(response.orderId),
      orderNo: response.orderNo,
      orderStatus: response.orderStatus,
      paymentStatus: response.paymentStatus,
      ticketCount: Number(response.ticketCount),
      operationTime: response.operationTime ?? '',
      message: response.message ?? ''
    }
  }

  private mapQuote(request: TicketSourceOrderQuoteRequest, raw: BackendOrderQuoteResult): OrderQuoteVO {
    const responseSkuId: string = String(raw.item.skuId)
    const responsePurchaseMode: TicketPurchaseMode = this.requirePurchaseMode(raw.purchaseMode)
    const responseTicketMode: TicketMode = this.requireTicketMode(raw.ticketMode)
    const responseDeliveryMode: DeliveryMode = this.requireDeliveryMode(raw.deliveryMode)
    const requestPurchaseMode: TicketPurchaseMode = request.purchaseMode ?? 'SYSTEM_ASSIGN'
    if (String(raw.userId) !== request.userId || String(raw.projectId) !== request.projectId ||
      String(raw.sessionId) !== request.sessionId || responseSkuId !== request.skuId ||
      responsePurchaseMode !== requestPurchaseMode || responseTicketMode !== request.ticketMode ||
      responseDeliveryMode !== request.deliveryMode || Number(raw.item.quantity) !== request.tickets.length ||
      Number(raw.totalTicketCount) !== request.tickets.length) {
      throw new Error('计价结果与V1.2单票档逐票请求不一致')
    }

    const tickets: OrderTicketSelectionRequest[] = (raw.item.tickets ?? []).map((item: BackendTicketSelection): OrderTicketSelectionRequest => {
      return { clientTicketNo: item.clientTicketNo, audienceId: String(item.audienceId) }
    })
    if (tickets.length !== request.tickets.length || !this.sameTickets(request.tickets, tickets)) {
      throw new Error('计价结果逐票身份与请求不一致')
    }

    const item: SingleSkuQuoteItemVO = {
      skuId: responseSkuId,
      skuName: raw.item.skuName,
      quantity: Number(raw.item.quantity),
      faceUnitPrice: this.money(raw.item.faceUnitPrice),
      saleUnitPrice: this.money(raw.item.saleUnitPrice),
      subtotalAmount: this.money(raw.item.subtotalAmount),
      tickets: tickets
    }

    const warnings: string[] = raw.warnings ?? []
    const delivery: DeliveryQuoteVO = {
      deliveryMode: responseDeliveryMode,
      addressId: raw.addressId === undefined || raw.addressId === null ? undefined : String(raw.addressId),
      deliveryFee: this.money(raw.deliveryFeeAmount),
      warnings: warnings
    }
    const promotions: AppliedPromotionVO[] = (raw.promotions ?? []).map((promotion: BackendPromotion): AppliedPromotionVO => {
      return {
        promotionType: promotion.promotionType ?? '',
        title: promotion.title ?? '',
        discountAmount: this.money(promotion.discountAmount)
      }
    })

    return {
      quoteId: raw.quoteId,
      userId: String(raw.userId),
      projectId: String(raw.projectId),
      sessionId: String(raw.sessionId),
      purchaseMode: raw.purchaseMode as TicketPurchaseMode,
      ticketMode: raw.ticketMode as TicketMode,
      deliveryMode: responseDeliveryMode,
      item: item,
      totalTicketCount: Number(raw.totalTicketCount),
      faceAmount: this.money(raw.faceAmount),
      ticketAmount: this.money(raw.ticketAmount),
      discountAmount: this.money(raw.discountAmount),
      deliveryFeeAmount: this.money(raw.deliveryFeeAmount),
      serviceFeeAmount: this.money(raw.serviceFeeAmount),
      payAmount: this.money(raw.payAmount),
      expireTime: raw.expireTime ?? '',
      delivery: delivery,
      promotions: promotions,
      warnings: warnings
    }
  }

  private requirePurchaseMode(value: string): TicketPurchaseMode {
    if (value === 'SYSTEM_ASSIGN' || value === 'GENERAL_ADMISSION') return value
    throw new Error('服务端返回了未知购买模式，已拒绝继续下单')
  }

  private requireTicketMode(value: string): TicketMode {
    switch (value) {
      case 'STATIC_QR':
      case 'DYNAMIC_QR':
      case 'ID_CARD':
      case 'EXCHANGE_CODE':
      case 'SMS_CODE':
      case 'URL':
      case 'TEXT':
      case 'PAPER_TICKET':
        return value
      default:
        throw new Error('服务端返回了未知票凭证类型，已拒绝继续下单')
    }
  }

  private requireDeliveryMode(value: string): DeliveryMode {
    switch (value) {
      case 'PAPERLESS':
      case 'EXPRESS':
      case 'SELF_PICKUP':
        return value
      default:
        throw new Error('服务端返回了未知配送方式，已拒绝继续下单')
    }
  }

  private sameTickets(expected: OrderTicketSelectionRequest[], actual: OrderTicketSelectionRequest[]): boolean {
    if (expected.length !== actual.length) return false
    const expectedKeys: string[] = expected.map((item: OrderTicketSelectionRequest): string =>
      item.clientTicketNo.trim() + '|' + item.audienceId.trim()).sort()
    const actualKeys: string[] = actual.map((item: OrderTicketSelectionRequest): string =>
      item.clientTicketNo.trim() + '|' + item.audienceId.trim()).sort()
    for (let index: number = 0; index < expectedKeys.length; index++) {
      if (expectedKeys[index] !== actualKeys[index]) return false
    }
    return true
  }

  private money(raw: BackendMoney | undefined | null): MoneyVO {
    if (raw === undefined || raw === null) {
      return MoneyUtil.zero()
    }
    return MoneyUtil.fromMinor(raw.amountMinor, raw.currency ?? 'CNY')
  }

}
