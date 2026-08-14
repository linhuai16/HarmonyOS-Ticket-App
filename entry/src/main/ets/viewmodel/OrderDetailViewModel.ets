import {
  OrderDetailVO
} from '../model/vo/order/OrderDetailVO'
import { OrderStatus } from '../model/enums/OrderStatus'
import { PayMethod } from '../model/enums/PayMethod'

import {
  OrderRepository
} from '../repository/OrderRepository'
import { PayRepository } from '../repository/PayRepository'
import { RefundRepository } from '../repository/RefundRepository'
import { RefundProgressVO } from '../model/vo/ticketsource/RefundProgressVO'

export interface TicketDetailJumpParams {
  userId: string
  orderId: string
  ticketId?: string
}
export interface RefundApplyJumpParams {
  userId: string
  orderId: string
}

/**
   加载订单详情
   查看电子票
   判断是否可退款
   构造退款申请页跳转参数
 */
export class OrderDetailViewModel {
  orderDetailVO: OrderDetailVO | undefined = undefined

  userId: string = ''
  orderId: string = ''

  isLoading: boolean = false
  errorMessage: string = ''
  refundProgress: RefundProgressVO | undefined = undefined
  refundProgressErrorMessage: string = ''

  private orderRepository: OrderRepository = new OrderRepository()
  private payRepository: PayRepository = new PayRepository()
  private refundRepository: RefundRepository = new RefundRepository()

  async loadPage(userId: string, orderId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.refundProgress = undefined
    this.refundProgressErrorMessage = ''

    this.userId = userId
    this.orderId = orderId

    const detail: OrderDetailVO | undefined =
      await this.orderRepository.getOrderDetail(userId, orderId)

    if (detail === undefined) {
      this.errorMessage = '订单详情不存在'
      this.orderDetailVO = undefined
      this.isLoading = false
      return
    }

    this.orderDetailVO = detail

    if (detail.orderStatus === OrderStatus.REFUNDING || detail.orderStatus === OrderStatus.REFUND_SUCCESS) {
      try {
        this.refundProgress = await this.refundRepository.getRefundProgress(userId, orderId)
      } catch (error) {
        this.refundProgress = undefined
        this.refundProgressErrorMessage = error instanceof Error ? error.message : '退款进度暂时无法获取'
      }
    }

    this.isLoading = false
  }

  async reload(): Promise<void> {
    if (this.userId.length === 0 || this.orderId.length === 0) {
      return
    }

    await this.loadPage(this.userId, this.orderId)
  }

  canPayOrder(): boolean {
    if (this.orderDetailVO === undefined) {
      return false
    }

    return this.orderDetailVO.orderStatus === OrderStatus.WAIT_PAY
  }

  async payOrder(payMethod: PayMethod): Promise<boolean> {
    if (!this.canPayOrder()) {
      this.errorMessage = '当前订单不可支付'
      return false
    }

    const payResponse = await this.payRepository.mockPaySuccess(this.orderId, payMethod, this.userId)
    if (payResponse === undefined) {
      this.errorMessage = '支付失败，请确认订单是否超时'
      await this.reload()
      return false
    }

    await this.reload()
    return true
  }

  canCancelOrder(): boolean {
    if (this.orderDetailVO === undefined) {
      return false
    }

    return this.orderDetailVO.orderStatus === OrderStatus.WAIT_PAY
  }

  async cancelOrder(): Promise<boolean> {
    if (!this.canCancelOrder()) {
      this.errorMessage = '当前订单不可取消'
      return false
    }

    const success: boolean = await this.orderRepository.cancelOrder(this.userId, this.orderId)
    if (!success) {
      this.errorMessage = this.orderRepository.getLastErrorMessage()
      return false
    }

    await this.reload()
    return true
  }

  canViewTicket(): boolean {
    if (this.orderDetailVO === undefined) {
      return false
    }

    return this.orderDetailVO.ticketActionType === 'VIEW_TICKET'
  }
  isTicketing(): boolean {
    if (this.orderDetailVO === undefined) {
      return false
    }

    return this.orderDetailVO.ticketActionType === 'TICKETING'
  }

  buildTicketDetailJumpParams(): TicketDetailJumpParams | undefined {
    if (!this.canViewTicket() || this.orderDetailVO === undefined) {
      return undefined
    }

    return {
      userId: this.userId,
      orderId: this.orderId,
      ticketId: this.orderDetailVO.defaultTicketId
    }
  }

  canRefund(): boolean {
    if (this.orderDetailVO === undefined) {
      return false
    }

    return this.orderDetailVO.orderStatus === OrderStatus.WAIT_USE
  }

  clearError(): void {
    this.errorMessage = ''
  }

  buildRefundApplyJumpParams(): RefundApplyJumpParams | undefined {
    if (!this.canRefund()) {
      this.errorMessage = '当前订单不可申请退款'
      return undefined
    }

    const params: RefundApplyJumpParams = {
      userId: this.userId,
      orderId: this.orderId
    }

    return params
  }
}
