import { RefundType } from '../model/enums/RefundType'
import { RefundStatus } from '../model/enums/RefundStatus'
import { RefundApplyPageVO } from '../model/vo/order/RefundApplyPageVO'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { RefundProgressVO } from '../model/vo/ticketsource/RefundProgressVO'

export interface RefundOrderRequest {
  userId: string
  reason?: string
}

export interface RefundOrderResponse {
  refundId: string
  status: RefundStatus
  expectedRefundAmount: number
}

export interface MockRefundSuccessResponse {
  success: boolean
  refundId: string
  refundStatus: RefundStatus
  refundTime?: string
}

interface BackendRefundApplyPageVO {
  orderId?: number | string
  orderNo?: string
  projectId?: number | string
  sessionId?: number | string

  // 后端退款确认接口历史版本里存在 title / projectTitle、expectedRefundAmount / estimatedRefundAmount 两种命名。
  // 这里统一兼容，避免字段名轻微变化导致退款申请页空白。
  title?: string
  projectTitle?: string
  posterUrl?: string
  startTime?: string
  venueName?: string
  venueAddress?: string
  skuName?: string
  quantity?: number
  payAmount?: number
  feeRate?: number
  feeAmount?: number
  refundFeeAmount?: number
  expectedRefundAmount?: number
  estimatedRefundAmount?: number
  refundType?: string
  refundRuleText?: string
  canRefund?: boolean
}

interface BackendRefundOrderResponse {
  refundId: number | string
  status: string
  expectedRefundAmount: number
}

interface BackendMockRefundSuccessResponse {
  success: boolean
  refundId: number | string
  refundStatus: string
  refundTime?: string
}


interface BackendRefundProgress {
  refundId: number | string
  orderId: number | string
  refundStatus: string
  refundAmount?: number | string | null
  feeAmount?: number | string | null
  applyTime?: string | null
  refundTime?: string | null
  failReason?: string | null
}
interface RefundOrderRequestBody {
  userId: number
  reason?: string
}

/** 退款 Repository：从 SpringBoot 退款接口读写，不再使用 Mock 数据。 */
export class RefundRepository {
  async getRefundApplyPage(userId: string, orderId: string): Promise<RefundApplyPageVO | undefined> {
    if (userId.length === 0 || orderId.length === 0) {
      return undefined
    }

    const response: BackendRefundApplyPageVO =
      await ApiClient.get<BackendRefundApplyPageVO>('/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/refund-confirm', [
        new ApiQueryParam('userId', userId)
      ])

    const refundType: string = this.safeString(response.refundType, RefundType.CONDITIONAL_REFUND)

    return {
      orderId: this.safeString(response.orderId, orderId),
      projectTitle: this.safeString(response.title ?? response.projectTitle),
      posterUrl: this.safeString(response.posterUrl),
      startTime: this.safeString(response.startTime),
      venueName: this.safeString(response.venueName),
      venueAddress: this.safeString(response.venueAddress),
      skuName: this.safeString(response.skuName),
      quantity: this.safeNumber(response.quantity),
      payAmount: this.safeNumber(response.payAmount),
      estimatedRefundAmount: this.safeNumber(response.expectedRefundAmount ?? response.estimatedRefundAmount),
      feeAmount: this.safeNumber(response.feeAmount ?? response.refundFeeAmount),
      refundType: refundType as RefundType,
      refundRuleText: this.safeString(response.refundRuleText),
      canRefund: response.canRefund === true
    }
  }

  private safeString(value: string | number | undefined | null, defaultValue: string = ''): string {
    if (value === undefined || value === null) {
      return defaultValue
    }
    return String(value)
  }

  private safeNumber(value: number | string | undefined | null, defaultValue: number = 0): number {
    if (value === undefined || value === null) {
      return defaultValue
    }

    const numberValue: number = Number(value)
    if (numberValue !== numberValue) {
      return defaultValue
    }

    return numberValue
  }

  async refundOrder(orderId: string, request: RefundOrderRequest): Promise<RefundOrderResponse | undefined> {
    if (orderId.length === 0 || request.userId.length === 0) {
      return undefined
    }

    const body: RefundOrderRequestBody = {
      userId: Number(request.userId)
    }
    if (request.reason !== undefined && request.reason.length > 0) {
      body.reason = request.reason
    }
    const response: BackendRefundOrderResponse =
      await ApiClient.post<BackendRefundOrderResponse>('/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/refunds', body)

    AppStorageVersionUtil.bumpRefundRelatedVersions()

    return {
      refundId: String(response.refundId),
      status: response.status as RefundStatus,
      expectedRefundAmount: Number(response.expectedRefundAmount)
    }
  }

  async getRefundProgress(userId: string, orderId: string): Promise<RefundProgressVO | undefined> {
    if (userId.length === 0 || orderId.length === 0) {
      return undefined
    }
    const raw: BackendRefundProgress = await ApiClient.get<BackendRefundProgress>(
      '/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/refund-progress',
      [new ApiQueryParam('userId', userId)]
    )
    return {
      refundId: String(raw.refundId),
      orderId: String(raw.orderId),
      refundStatus: raw.refundStatus as RefundStatus,
      refundAmount: this.safeNumber(raw.refundAmount),
      feeAmount: this.safeNumber(raw.feeAmount),
      applyTime: raw.applyTime ?? undefined,
      refundTime: raw.refundTime ?? undefined,
      failReason: raw.failReason ?? undefined
    }
  }

  async mockRefundSuccess(refundId: string): Promise<MockRefundSuccessResponse | undefined> {
    if (refundId.length === 0) {
      return undefined
    }

    const response: BackendMockRefundSuccessResponse =
      await ApiClient.post<BackendMockRefundSuccessResponse>('/api/mock/refunds/' + encodeURIComponent(refundId) + '/success')

    AppStorageVersionUtil.bumpRefundRelatedVersions()

    return {
      success: response.success,
      refundId: String(response.refundId),
      refundStatus: response.refundStatus as RefundStatus,
      refundTime: response.refundTime
    }
  }
}
