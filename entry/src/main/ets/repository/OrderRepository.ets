import { DeliveryType } from '../model/enums/DeliveryType'
import { OrderStatus } from '../model/enums/OrderStatus'
import { PayMethod } from '../model/enums/PayMethod'
import { CertificateType } from '../model/enums/CertificateType'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

import {
  SubmitOrderPageVO
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
import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { MaskUtil } from '../utils/MaskUtil'

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

type OrderTicketActionType = 'VIEW_TICKET' | 'TICKETING' | 'NONE'

interface BackendSubmitOrderPageVO {
  projectId: number | string
  sessionId: number | string
  skuId: number | string
  title: string
  venueName: string
  venueAddress: string
  startTime?: string | null
  skuName: string
  unitPrice: number
  quantity: number
  requiredAudienceCount: number
  deliveryType: string
  ticketAmount: number
  serviceFeeAmount?: number
  deliveryFeeAmount?: number
  discountAmount?: number
  totalAmount: number
  payAmount: number
  payExpireMinutes: number
  serviceTags?: ServiceTagVO[]
}

interface BackendCreateOrderResponse {
  orderId: number | string
  orderNo: string
  orderStatus: string
  payAmount: number
  payExpireTime: string
}

interface CreateOrderRequestBody {
  userId: number
  projectId: number
  sessionId: number
  skuId: number
  quantity: number
  audienceIds: number[]
  deliveryType: DeliveryType
  addressId?: number
}

interface CancelOrderRequestBody {
  userId: number
}

interface BackendOrderListPageVO {
  orders: BackendOrderListItemVO[]
  hasMore: boolean
}

interface BackendOrderListItemVO {
  orderId: number | string
  orderNo: string
  orderStatus: string
  title: string
  posterUrl: string
  startTime: string
  venueName: string
  deliveryType?: string
  deliveryMode?: string
  skuSummary?: string
  totalQuantity?: number
  payAmount: number
  actionType?: string
}

interface BackendOrderDetailVO {
  orderId: number | string
  orderNo: string
  orderStatus: string
  projectId: number | string
  sessionId: number | string
  title?: string | null
  posterUrl?: string | null
  categoryName?: string | null
  startTime?: string | null
  venueName?: string | null
  venueAddress?: string | null
  deliveryType?: string | null
  deliveryMode?: string | null
  totalAmount: number
  serviceFeeAmount?: number
  deliveryFeeAmount?: number
  payAmount: number
  payMethod?: string | null
  payExpireTime?: string | null
  payTime?: string | null
  cancelTime?: string | null
  ticketIssuedTime?: string | null
  finishTime?: string | null
  createTime?: string | null
  ticketActionType?: string | null
  defaultTicketId?: number | string | null
  items?: BackendOrderDetailItemVO[]
  orderItems?: BackendOrderDetailItemVO[]
  audiences?: BackendOrderAudienceVO[]
  address?: BackendOrderAddressVO | null
  refundRecord?: BackendRefundRecordVO | null
}

interface BackendOrderDetailItemVO {
  skuName: string
  unitPrice: number
  quantity: number
  subtotalAmount: number
}

interface BackendOrderAudienceVO {
  realName: string
  certificateType?: string
  certificateNo?: string
  phone?: string
  maskedCertificateNo?: string
  maskedPhone?: string
}

interface BackendOrderAddressVO {
  receiverName?: string | null
  receiverPhone?: string | null
  fullAddress?: string | null
  province?: string | null
  city?: string | null
  district?: string | null
  detailAddress?: string | null
}

interface BackendRefundRecordVO {
  refundAmount?: number | null
  feeAmount?: number | null
  refundTime?: string | null
}

interface CancelOrderResponse {
  success: boolean
}

/** 订单 Repository：从 SpringBoot 接口读写，不再使用 Mock。 */
export class OrderRepository {
  private lastErrorMessage: string = ''

  getLastErrorMessage(): string {
    return this.lastErrorMessage
  }

  async getSubmitOrderPage(request: ConfirmOrderRequest): Promise<SubmitOrderPageVO | undefined> {
    this.lastErrorMessage = ''
    if (request.projectId.length === 0 || request.sessionId.length === 0 || request.skuId.length === 0) {
      return undefined
    }

    const response: BackendSubmitOrderPageVO = await ApiClient.get<BackendSubmitOrderPageVO>('/api/orders/confirm', [
      new ApiQueryParam('projectId', request.projectId),
      new ApiQueryParam('sessionId', request.sessionId),
      new ApiQueryParam('skuId', request.skuId),
      new ApiQueryParam('quantity', request.quantity)
    ])

    return {
      payExpireMinutes: response.payExpireMinutes,
      performance: {
        projectId: String(response.projectId),
        sessionId: String(response.sessionId),
        projectTitle: response.title,
        venueName: response.venueName,
        venueAddress: response.venueAddress,
        startTime: response.startTime ?? ''
      },
      orderItems: [
        {
          skuId: String(response.skuId),
          skuName: response.skuName,
          unitPrice: Number(response.unitPrice),
          quantity: Number(response.quantity)
        }
      ],
      serviceTags: response.serviceTags ?? [],
      requiredAudienceCount: Number(response.requiredAudienceCount),
      priceDetail: {
        ticketAmount: Number(response.ticketAmount),
        serviceFee: Number(response.serviceFeeAmount ?? 0),
        deliveryFee: Number(response.deliveryFeeAmount ?? 0),
        discountAmount: Number(response.discountAmount ?? 0),
        totalAmount: Number(response.totalAmount),
        payAmount: Number(response.payAmount)
      },
      deliveryType: response.deliveryType as DeliveryType
    }
  }

  async createOrder(request: CreateOrderRequest): Promise<CreateOrderResponse | undefined> {
    this.lastErrorMessage = ''
    const body: CreateOrderRequestBody = {
      userId: Number(request.userId),
      projectId: Number(request.projectId),
      sessionId: Number(request.sessionId),
      skuId: Number(request.skuId),
      quantity: request.quantity,
      audienceIds: request.audienceIds.map((id: string): number => Number(id)),
      deliveryType: request.deliveryType
    }
    if (request.addressId !== undefined && request.addressId.length > 0) {
      body.addressId = Number(request.addressId)
    }

    try {
      const response: BackendCreateOrderResponse = await ApiClient.post<BackendCreateOrderResponse>('/api/orders', body)

      const result: CreateOrderResponse = {
        orderId: String(response.orderId),
        orderNo: response.orderNo,
        orderStatus: response.orderStatus as OrderStatus,
        payAmount: Number(response.payAmount),
        payExpireTime: response.payExpireTime
      }
      AppStorageVersionUtil.bumpOrderInventoryRelatedVersions()
      return result
    } catch (error) {
      this.lastErrorMessage = this.normalizeCreateOrderError(error)
      return undefined
    }
  }

  async getOrderList(
    userId: string,
    tab: OrderListTab = OrderListTab.ALL,
    pageNo: number = 1,
    pageSize: number = 10
  ): Promise<OrderListPageVO> {
    const response: BackendOrderListPageVO = await ApiClient.get<BackendOrderListPageVO>('/api/orders', [
      new ApiQueryParam('userId', userId),
      new ApiQueryParam('tab', tab),
      new ApiQueryParam('pageNo', pageNo),
      new ApiQueryParam('pageSize', pageSize)
    ])

    const orders: OrderListItemVO[] = (response.orders ?? []).map((item: BackendOrderListItemVO): OrderListItemVO => {
      return {
        orderId: String(item.orderId),
        orderNo: item.orderNo,
        orderStatus: item.orderStatus as OrderStatus,
        posterUrl: item.posterUrl,
        projectTitle: item.title,
        startTime: item.startTime,
        venueName: item.venueName,
        deliveryType: item.deliveryType ?? '',
        deliveryMode: item.deliveryMode,
        skuName: item.skuSummary ?? '',
        unitPrice: 0,
        quantity: item.totalQuantity ?? 1,
        payAmount: Number(item.payAmount),
        actionType: (item.actionType ?? 'NONE') as OrderActionType
      }
    })

    return {
      orders: orders,
      hasMore: response.hasMore
    }
  }

  async getOrderDetail(userId: string, orderId: string): Promise<OrderDetailVO | undefined> {
    if (userId.length === 0 || orderId.length === 0) {
      return undefined
    }

    const response: BackendOrderDetailVO = await ApiClient.get<BackendOrderDetailVO>('/api/orders/' + encodeURIComponent(orderId) + '/detail', [
      new ApiQueryParam('userId', userId)
    ])

    return this.mapOrderDetail(response)
  }

  async cancelOrder(userId: string, orderId: string): Promise<boolean> {
    this.lastErrorMessage = ''
    if (userId.length === 0 || orderId.length === 0) {
      this.lastErrorMessage = '订单参数不存在'
      return false
    }

    const body: CancelOrderRequestBody = {
      userId: Number(userId)
    }
    const response: CancelOrderResponse = await ApiClient.post<CancelOrderResponse>('/api/orders/' + encodeURIComponent(orderId) + '/cancel', body)

    if (response.success) {
      AppStorageVersionUtil.bumpOrderInventoryRelatedVersions()
    }
    return response.success
  }

  private normalizeCreateOrderError(error: Error | string | undefined | null): string {
    let message: string = '提交订单失败，请重新选择票档或观演人'

    if (error instanceof Error) {
      message = error.message
    } else if (error !== undefined && error !== null) {
      message = String(error)
    }

    const prefix: string = '接口返回失败：'
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length)
    }

    if (message.indexOf('同一实名信息同场次') >= 0 ||
      message.indexOf('重复购买') >= 0 ||
      message.indexOf('已经购买') >= 0) {
      return '该观演人已经购买过该场次下的票档，请更换观演人或票档'
    }

    if (message.length === 0) {
      return '提交订单失败，请重新选择票档或观演人'
    }

    return message
  }

  private mapOrderDetail(raw: BackendOrderDetailVO): OrderDetailVO {
    const items: BackendOrderDetailItemVO[] = raw.items ?? raw.orderItems ?? []
    const rawRefundRecord: BackendRefundRecordVO | null | undefined = raw.refundRecord
    const refundRecord: BackendRefundRecordVO | undefined =
      rawRefundRecord === null || rawRefundRecord === undefined ? undefined : rawRefundRecord

    return {
      orderId: String(raw.orderId),
      orderNo: raw.orderNo ?? '',
      orderStatus: raw.orderStatus as OrderStatus,
      posterUrl: raw.posterUrl ?? '',
      categoryName: raw.categoryName ?? '',
      projectTitle: raw.title ?? '',
      startTime: raw.startTime ?? '',
      venueName: raw.venueName ?? '',
      venueAddress: raw.venueAddress ?? '',
      orderItems: items.map((item: BackendOrderDetailItemVO): OrderDetailItemVO => {
        return {
          skuName: item.skuName ?? '',
          unitPrice: Number(item.unitPrice),
          quantity: Number(item.quantity),
          subtotalAmount: Number(item.subtotalAmount)
        }
      }),
      audiences: (raw.audiences ?? []).map((item: BackendOrderAudienceVO): OrderDetailAudienceVO => {
        return {
          realName: item.realName ?? '',
          maskedCertificateNo: item.maskedCertificateNo ?? this.maskCertificateNo(item.certificateNo ?? ''),
          maskedPhone: item.maskedPhone ?? this.maskPhone(item.phone ?? '')
        }
      }),
      deliveryType: this.mapDeliveryType(raw.deliveryType),
      deliveryMode: raw.deliveryMode ?? undefined,
      address: this.mapOrderAddress(raw.address),
      createTime: raw.createTime ?? '',
      payExpireTime: this.toOptionalString(raw.payExpireTime),
      payTime: this.toOptionalString(raw.payTime),
      ticketIssuedTime: this.toOptionalString(raw.ticketIssuedTime),
      cancelTime: this.toOptionalString(raw.cancelTime),
      finishTime: this.toOptionalString(raw.finishTime),
      refundTime: this.toOptionalString(refundRecord?.refundTime),
      totalAmount: Number(raw.totalAmount),
      serviceFee: Number(raw.serviceFeeAmount ?? 0),
      deliveryFee: Number(raw.deliveryFeeAmount ?? 0),
      payAmount: Number(raw.payAmount),
      payMethod: this.mapPayMethod(raw.payMethod),
      ticketActionType: (raw.ticketActionType ?? 'NONE') as OrderTicketActionType,
      defaultTicketId: this.toOptionalString(raw.defaultTicketId),
      refundAmount: this.toOptionalNumber(refundRecord?.refundAmount),
      refundFeeAmount: this.toOptionalNumber(refundRecord?.feeAmount),
      projectId: String(raw.projectId),
      sessionId: String(raw.sessionId)
    }
  }

  private mapOrderAddress(raw: BackendOrderAddressVO | undefined | null): OrderDetailAddressVO | undefined {
    if (raw === undefined || raw === null) {
      return undefined
    }

    const province: string = raw.province ?? ''
    const city: string = raw.city ?? ''
    const district: string = raw.district ?? ''
    const detailAddress: string = raw.detailAddress ?? ''
    const fullAddress: string = raw.fullAddress ?? (province + city + district + detailAddress)
    return {
      receiverName: raw.receiverName ?? '',
      receiverPhone: raw.receiverPhone ?? '',
      fullAddress: fullAddress
    }
  }

  private mapDeliveryType(deliveryType: string | undefined | null): DeliveryType {
    if (deliveryType === DeliveryType.PAPER_TICKET) {
      return DeliveryType.PAPER_TICKET
    }
    return DeliveryType.ETICKET
  }

  private toOptionalString(value: number | string | undefined | null): string | undefined {
    if (value === undefined || value === null) {
      return undefined
    }
    const text: string = String(value)
    return text.length === 0 ? undefined : text
  }

  private toOptionalNumber(value: number | undefined | null): number | undefined {
    if (value === undefined || value === null) {
      return undefined
    }
    return Number(value)
  }

  private mapPayMethod(payMethod: string | undefined | null): PayMethod | undefined {
    if (payMethod === undefined || payMethod === null || payMethod.length === 0) {
      return undefined
    }
    return payMethod as PayMethod
  }

  private maskCertificateNo(value: string): string {
    if (value.length === 0) {
      return '-'
    }
    return MaskUtil.maskCertificateNo(value)
  }

  private maskPhone(value: string): string {
    if (value.length === 0) {
      return ''
    }
    return MaskUtil.maskPhone(value)
  }
}
