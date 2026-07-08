import {
  OrderDetailVO,
  OrderDetailItemVO
} from '../model/vo/order/OrderDetailVO'

import { PayRepository } from '../repository/PayRepository'
import { OrderRepository } from '../repository/OrderRepository'
import { PayMethod } from '../model/enums/PayMethod'
import { OrderStatus } from '../model/enums/OrderStatus'

import {
  PaySuccessPageVO,
  PaySuccessPerformanceVO
} from '../model/vo/order/PaySuccessPageVO'

export class PaySuccessViewModel {
  orderDetailVO: OrderDetailVO | undefined = undefined
  paySuccessVO: PaySuccessPageVO | undefined = undefined

  userId: string = ''
  orderId: string = ''

  isLoading: boolean = false
  errorMessage: string = ''

  private payRepository: PayRepository = new PayRepository()
  private orderRepository: OrderRepository = new OrderRepository()

  async loadPaySuccess(
    userId: string,
    orderId: string,
    payMethod: PayMethod = PayMethod.ALIPAY
  ): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.orderDetailVO = undefined
    this.paySuccessVO = undefined

    this.userId = userId
    this.orderId = orderId

    let orderDetail: OrderDetailVO | undefined =
      await this.orderRepository.getOrderDetail(userId, orderId)

    if (orderDetail === undefined) {
      this.errorMessage = '支付完成数据不存在'
      this.isLoading = false
      return
    }

    if (orderDetail.orderStatus === OrderStatus.WAIT_PAY) {
      const payResponse = this.payRepository.mockPaySuccess(orderId, payMethod)
      if (payResponse === undefined) {
        this.errorMessage = '支付失败，请确认订单是否超时'
        this.orderDetailVO = orderDetail
        this.isLoading = false
        return
      }

      orderDetail = await this.orderRepository.getOrderDetail(userId, orderId)
    }

    if (orderDetail === undefined) {
      this.errorMessage = '支付完成数据不存在'
      this.isLoading = false
      return
    }

    this.orderDetailVO = orderDetail
    this.paySuccessVO = this.buildPaySuccessDisplayVO(orderDetail)

    this.isLoading = false
  }

  async reload(): Promise<void> {
    if (this.userId.length === 0 || this.orderId.length === 0) {
      return
    }

    const orderDetail: OrderDetailVO | undefined =
      await this.orderRepository.getOrderDetail(this.userId, this.orderId)

    if (orderDetail === undefined) {
      this.errorMessage = '支付完成数据不存在'
      return
    }

    this.orderDetailVO = orderDetail
    this.paySuccessVO = this.buildPaySuccessDisplayVO(orderDetail)
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private buildPaySuccessDisplayVO(orderDetail: OrderDetailVO): PaySuccessPageVO {
    const firstItem: OrderDetailItemVO | undefined = orderDetail.orderItems.length > 0 ?
      orderDetail.orderItems[0] :
      undefined

    const performance: PaySuccessPerformanceVO = {
      posterUrl: orderDetail.posterUrl,
      categoryName: orderDetail.categoryName,
      projectTitle: orderDetail.projectTitle,
      startTime: orderDetail.startTime,
      venueAddress: orderDetail.venueAddress
    }

    const displayVO: PaySuccessPageVO = {
      orderId: orderDetail.orderId,
      orderNo: orderDetail.orderNo,
      payAmount: orderDetail.payAmount,
      performance: performance,
      skuName: firstItem === undefined ? '' : firstItem.skuName,
      deliveryType: orderDetail.deliveryType,
      payMethod: orderDetail.payMethod
    }

    return displayVO
  }
}