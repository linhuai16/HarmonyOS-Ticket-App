import { RefundApplyPageVO } from '../model/vo/order/RefundApplyPageVO'

import {
  RefundRepository,
  RefundOrderRequest,
  RefundOrderResponse
} from '../repository/RefundRepository'

export class RefundApplyViewModel {
  pageVO: RefundApplyPageVO | undefined = undefined
  refundResponse: RefundOrderResponse | undefined = undefined

  userId: string = ''
  orderId: string = ''
  reason: string = ''

  isLoading: boolean = false
  isSubmitting: boolean = false
  errorMessage: string = ''

  private refundRepository: RefundRepository = new RefundRepository()

  async loadPage(userId: string, orderId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    this.orderId = orderId

    try {
      const pageVO: RefundApplyPageVO | undefined =
        await this.refundRepository.getRefundApplyPage(userId, orderId)

      if (pageVO === undefined) {
        this.errorMessage = '退款申请数据不存在'
        return
      }

      this.pageVO = pageVO
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '退款申请数据加载失败'
    } finally {
      this.isLoading = false
    }
  }

  changeReason(reason: string): void {
    this.reason = reason
  }

  canSubmit(): boolean {
    if (this.pageVO === undefined) {
      return false
    }

    return this.pageVO.canRefund
  }

  async submitRefund(): Promise<RefundOrderResponse | undefined> {
    if (!this.canSubmit()) {
      this.errorMessage = '当前订单不支持退款'
      return undefined
    }

    this.isSubmitting = true
    this.errorMessage = ''

    const request: RefundOrderRequest = {
      userId: this.userId,
      reason: this.reason.length === 0 ? undefined : this.reason
    }

    const response: RefundOrderResponse | undefined =
      await this.refundRepository.refundOrder(this.orderId, request)

    if (response === undefined) {
      this.errorMessage = '退款申请失败'
      this.isSubmitting = false
      return undefined
    }

    this.refundResponse = response
    this.isSubmitting = false

    return response
  }

  clearError(): void {
    this.errorMessage = ''
  }
}
