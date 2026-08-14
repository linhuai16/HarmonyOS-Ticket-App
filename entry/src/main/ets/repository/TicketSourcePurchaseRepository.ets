import { PayMethod } from '../model/enums/PayMethod'
import { MoneyVO } from '../model/vo/ticketsource/MoneyVO'
import {
  V13AudienceEligibilityVO,
  V13EstimatedAmountVO,
  V13FulfillmentOptionVO,
  V13InventoryViewVO,
  V13PurchaseInitVO,
  V13SubmitOrderRequestVO,
  V13SubmitOrderVO
} from '../model/vo/ticketsource/PurchaseV13VO'
import {
  DeliveryMode,
  OrderTicketSelectionRequest,
  TicketMode,
  TicketPurchaseMode
} from '../model/vo/ticketsource/TicketSourceTypes'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { TicketSourceOrderValidator } from '../utils/TicketSourceOrderValidator'

interface BackendMoney { amountMinor?: number | string | null; currency?: string | null }
interface BackendV13Option {
  optionCode: string
  displayName: string
  credentialType: string
  deliveryMethod: string
  requiresAddress: boolean
  requiresDynamicRefresh: boolean
  recommended: boolean
  deliveryFee?: BackendMoney | null
  userTips?: string[]
}
interface BackendV13AudienceEligibility {
  audienceId: number | string
  canSelect: boolean
  disabledReason?: string | null
}
interface BackendV13Inventory {
  stockState: string
  availableStock?: number | null
  exact: boolean
  displayText: string
  canContinue: boolean
}
interface BackendV13Estimated {
  priceStatus: string
  ticketAmount?: BackendMoney | null
  deliveryFee?: BackendMoney | null
  payAmount?: BackendMoney | null
  displayText: string
}
interface BackendV13Init {
  userId?: number | string | null
  projectId: number | string
  sessionId: number | string
  skuId: number | string
  skuName: string
  quantity: number
  limitPerOrder?: number | null
  inventoryView: BackendV13Inventory
  purchaseMode: string
  fulfillmentOptions?: BackendV13Option[]
  estimatedAmount: BackendV13Estimated
  audienceEligibility?: BackendV13AudienceEligibility[]
  notices?: string[]
}
interface BackendV13TicketSubmit { clientTicketNo: string; audienceId: number }
interface BackendV13SubmitRequest {
  userId: number
  projectId: number
  sessionId: number
  skuId: number
  quantity: number
  tickets: BackendV13TicketSubmit[]
  fulfillmentOptionCode: string
  addressId?: number
  clientSubmitNo: string
  expectedPayAmountMinor: number
}
interface BackendV13SubmitResult {
  orderId?: number | string | null
  orderNo?: string | null
  orderStatus?: string | null
  priceStatus: string
  ticketAmount?: BackendMoney | null
  deliveryFee?: BackendMoney | null
  payAmount?: BackendMoney | null
  reservationExpireAt?: string | null
  paymentButtonText?: string | null
  userMessage?: string | null
}
interface BackendV13PayRequest {
  userId: number
  payMethod: PayMethod
}

/** V1.3-B10R-5 真实购票交互数据层：页面只提交订单一次，不暴露 quoteId/provider*。 */
export class TicketSourcePurchaseRepository {
  async initPurchase(userId: string, projectId: string, sessionId: string, skuId: string, quantity: number): Promise<V13PurchaseInitVO> {
    const params: ApiQueryParam[] = [
      new ApiQueryParam('projectId', projectId),
      new ApiQueryParam('sessionId', sessionId),
      new ApiQueryParam('skuId', skuId),
      new ApiQueryParam('quantity', String(quantity))
    ]
    if (userId.trim().length > 0) {
      params.push(new ApiQueryParam('userId', userId.trim()))
    }
    const raw: BackendV13Init = await ApiClient.get<BackendV13Init>('/api/ticket-source/purchase/v13/init', params)
    if (String(raw.projectId) !== projectId || String(raw.sessionId) !== sessionId || String(raw.skuId) !== skuId) {
      throw new Error('购买初始化结果与当前票档不一致')
    }
    const options: V13FulfillmentOptionVO[] = (raw.fulfillmentOptions ?? []).map((item: BackendV13Option): V13FulfillmentOptionVO => {
      return {
        optionCode: item.optionCode,
        displayName: item.displayName,
        credentialType: this.requireTicketMode(item.credentialType),
        deliveryMethod: this.requireDeliveryMode(item.deliveryMethod),
        requiresAddress: item.requiresAddress,
        requiresDynamicRefresh: item.requiresDynamicRefresh,
        recommended: item.recommended,
        deliveryFee: this.money(item.deliveryFee),
        userTips: item.userTips ?? []
      }
    })
    if (options.length === 0) throw new Error('当前票档没有可用入场/取票方式')
    return {
      userId: raw.userId === undefined || raw.userId === null ? undefined : String(raw.userId),
      projectId: String(raw.projectId),
      sessionId: String(raw.sessionId),
      skuId: String(raw.skuId),
      skuName: raw.skuName,
      quantity: Number(raw.quantity),
      limitPerOrder: raw.limitPerOrder ?? 1,
      inventoryView: this.mapInventory(raw.inventoryView),
      purchaseMode: this.requirePurchaseMode(raw.purchaseMode),
      fulfillmentOptions: options,
      estimatedAmount: this.mapEstimated(raw.estimatedAmount),
      audienceEligibility: this.mapAudienceEligibility(raw.audienceEligibility ?? []),
      notices: raw.notices ?? []
    }
  }

  async submitOrder(request: V13SubmitOrderRequestVO): Promise<V13SubmitOrderVO> {
    TicketSourceOrderValidator.validateSubmitTickets(request.tickets, request.quantity)
    const body: BackendV13SubmitRequest = {
      userId: Number(request.userId),
      projectId: Number(request.projectId),
      sessionId: Number(request.sessionId),
      skuId: Number(request.skuId),
      quantity: request.quantity,
      tickets: request.tickets.map((ticket: OrderTicketSelectionRequest): BackendV13TicketSubmit => {
        return { clientTicketNo: ticket.clientTicketNo.trim(), audienceId: Number(ticket.audienceId) }
      }),
      fulfillmentOptionCode: request.fulfillmentOptionCode.trim(),
      clientSubmitNo: request.clientSubmitNo.trim(),
      expectedPayAmountMinor: request.expectedPayAmountMinor
    }
    if (request.addressId !== undefined && request.addressId.length > 0) body.addressId = Number(request.addressId)
    const raw: BackendV13SubmitResult = await ApiClient.post<BackendV13SubmitResult>('/api/ticket-source/purchase/v13/submit', body)
    const mapped: V13SubmitOrderVO = this.mapSubmit(raw)
    if (mapped.priceStatus === 'CONFIRMED' && mapped.orderId.length > 0) {
      AppStorageVersionUtil.bumpOrderInventoryRelatedVersions()
    }
    return mapped
  }

  async payOrder(orderId: string, userId: string, payMethod: PayMethod): Promise<V13SubmitOrderVO> {
    const body: BackendV13PayRequest = {
      userId: Number(userId),
      payMethod: payMethod
    }
    const raw: BackendV13SubmitResult = await ApiClient.post<BackendV13SubmitResult>(
      '/api/ticket-source/purchase/v13/orders/' + encodeURIComponent(orderId) + '/pay',
      body
    )
    AppStorageVersionUtil.bumpOrderTicketRelatedVersions()
    return this.mapSubmit(raw)
  }

  private mapInventory(raw: BackendV13Inventory): V13InventoryViewVO {
    return {
      stockState: raw.stockState,
      availableStock: raw.availableStock === undefined || raw.availableStock === null ? undefined : Number(raw.availableStock),
      exact: raw.exact,
      displayText: raw.displayText,
      canContinue: raw.canContinue
    }
  }

  private mapEstimated(raw: BackendV13Estimated): V13EstimatedAmountVO {
    return {
      priceStatus: 'ESTIMATED',
      ticketAmount: this.money(raw.ticketAmount),
      deliveryFee: this.money(raw.deliveryFee),
      payAmount: this.money(raw.payAmount),
      displayText: raw.displayText
    }
  }

  private mapAudienceEligibility(raw: BackendV13AudienceEligibility[]): V13AudienceEligibilityVO[] {
    return raw.map((item: BackendV13AudienceEligibility): V13AudienceEligibilityVO => {
      return {
        audienceId: String(item.audienceId),
        canSelect: item.canSelect,
        disabledReason: item.disabledReason ?? ''
      }
    })
  }

  private mapSubmit(raw: BackendV13SubmitResult): V13SubmitOrderVO {
    const priceStatus: 'CONFIRMED' | 'CHANGED' | 'EXPIRED' | 'FAILED' = this.requirePriceStatus(raw.priceStatus)
    return {
      orderId: raw.orderId === undefined || raw.orderId === null ? '' : String(raw.orderId),
      orderNo: raw.orderNo ?? '',
      orderStatus: raw.orderStatus ?? '',
      priceStatus: priceStatus,
      ticketAmount: this.money(raw.ticketAmount),
      deliveryFee: this.money(raw.deliveryFee),
      payAmount: this.money(raw.payAmount),
      reservationExpireAt: raw.reservationExpireAt ?? '',
      paymentButtonText: raw.paymentButtonText ?? '立即支付',
      userMessage: raw.userMessage ?? ''
    }
  }

  private requirePurchaseMode(value: string): TicketPurchaseMode {
    if (value === 'SYSTEM_ASSIGN' || value === 'GENERAL_ADMISSION') return value
    throw new Error('服务端返回了未知购买模式，已拒绝继续下单')
  }

  private requireTicketMode(value: string): TicketMode {
    switch (value) {
      case 'STATIC_QR': case 'DYNAMIC_QR': case 'ID_CARD': case 'EXCHANGE_CODE':
      case 'SMS_CODE': case 'URL': case 'TEXT': case 'PAPER_TICKET':
        return value
      default:
        throw new Error('服务端返回了未知票凭证类型，已拒绝继续下单')
    }
  }

  private requireDeliveryMode(value: string): DeliveryMode {
    switch (value) {
      case 'PAPERLESS': case 'EXPRESS': case 'SELF_PICKUP':
        return value
      default:
        throw new Error('服务端返回了未知配送方式，已拒绝继续下单')
    }
  }

  private requirePriceStatus(value: string): 'CONFIRMED' | 'CHANGED' | 'EXPIRED' | 'FAILED' {
    if (value === 'CONFIRMED' || value === 'CHANGED' || value === 'EXPIRED' || value === 'FAILED') return value
    throw new Error('服务端返回了未知价格状态')
  }

  private money(raw: BackendMoney | undefined | null): MoneyVO {
    if (raw === undefined || raw === null) return { amountMinor: 0, currency: 'CNY' }
    return { amountMinor: Number(raw.amountMinor ?? 0), currency: raw.currency ?? 'CNY' }
  }
}
