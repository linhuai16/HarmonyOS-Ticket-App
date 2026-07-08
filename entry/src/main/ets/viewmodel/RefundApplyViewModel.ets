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

  loadPage(userId: string, orderId: string): void {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    this.orderId = orderId
    this.reason = ''
    this.refundResponse = undefined

    const pageVO: RefundApplyPageVO | undefined =
      this.refundRepository.getRefundApplyPage(userId, orderId)

    if (pageVO === undefined) {
      this.errorMessage = '退款申请数据不存在'
      this.isLoading = false
      return
    }

    this.pageVO = pageVO
    this.isLoading = false
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

  submitRefund(): RefundOrderResponse | undefined {
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
      this.refundRepository.refundOrder(this.orderId, request)

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