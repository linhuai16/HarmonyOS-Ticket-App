import { Order } from '../../model/entity/Order'
import { OrderItem } from '../../model/entity/OrderItem'
import { OrderAudience } from '../../model/entity/OrderAudience'
import { OrderAddress } from '../../model/entity/OrderAddress'
import { PerformanceProject } from '../../model/entity/PerformanceProject'
import { PerformanceSession } from '../../model/entity/PerformanceSession'
import { TicketSku } from '../../model/entity/TicketSku'
import { ServiceTag } from '../../model/entity/ServiceTag'
import { RefundRecord } from '../../model/entity/RefundRecord'

import { DeliveryType } from '../../model/enums/DeliveryType'
import {
  SubmitOrderPageVO,
  SubmitOrderPerformanceVO,
  SubmitOrderItemVO,
  SubmitOrderPriceDetailVO
} from '../../model/vo/order/SubmitOrderPageVO'
import { OrderListItemVO } from '../../model/vo/order/OrderListPageVO'
import {
  OrderDetailVO,
  OrderDetailItemVO,
  OrderDetailAudienceVO,
  OrderDetailAddressVO
} from '../../model/vo/order/OrderDetailVO'
import { ServiceTagVO } from '../../model/vo/performance/PerformanceDetailVO'

import { OrderDataHelper } from './OrderDataHelper'
import { OrderTicketService } from './OrderTicketService'
import { PAY_EXPIRE_MINUTES } from './OrderConstants'
import { MaskUtil } from '../../utils/MaskUtil'


export class OrderMapper {
  private dataHelper: OrderDataHelper
  private ticketService: OrderTicketService

  constructor(dataHelper: OrderDataHelper, ticketService: OrderTicketService) {
    this.dataHelper = dataHelper
    this.ticketService = ticketService
  }

  buildSubmitOrderPageVO(
    project: PerformanceProject,
    session: PerformanceSession,
    sku: TicketSku,
    quantity: number
  ): SubmitOrderPageVO {
    const ticketAmount: number = sku.price * quantity

    const performance: SubmitOrderPerformanceVO = {
      projectId: project.projectId,
      sessionId: session.sessionId,
      projectTitle: project.title,
      venueName: this.dataHelper.findVenueName(session.venueId),
      venueAddress: this.dataHelper.findVenueAddress(session.venueId),
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
      deliveryType: session.deliveryType
    }

    return result
  }

  buildOrderListItemVO(order: Order): OrderListItemVO | undefined {
    const project: PerformanceProject | undefined = this.dataHelper.findProject(order.projectId)
    const session: PerformanceSession | undefined = this.dataHelper.findSession(order.sessionId)
    const orderItem: OrderItem | undefined = this.dataHelper.findOrderItem(order.orderId)

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
      venueName: this.dataHelper.findVenueName(session.venueId),
      skuName: orderItem.skuName,
      unitPrice: orderItem.unitPrice,
      quantity: orderItem.quantity,
      payAmount: order.payAmount,
      actionType: this.ticketService.buildOrderActionType(order)
    }

    return vo
  }

  buildOrderDetailVO(order: Order): OrderDetailVO | undefined {
    const project: PerformanceProject | undefined = this.dataHelper.findProject(order.projectId)
    const session: PerformanceSession | undefined = this.dataHelper.findSession(order.sessionId)
    if (project === undefined || session === undefined) {
      return undefined
    }

    const orderItems: OrderItem[] = this.dataHelper.findOrderItems(order.orderId)
    const refundRecord: RefundRecord | undefined = this.dataHelper.findRefundRecord(order.orderId)

    const result: OrderDetailVO = {
      orderId: order.orderId,
      orderNo: order.orderNo,
      orderStatus: order.orderStatus,
      posterUrl: project.posterUrl,
      categoryName: this.dataHelper.findCategoryName(project.categoryId),
      projectTitle: project.title,
      startTime: session.startTime,
      venueName: this.dataHelper.findVenueName(session.venueId),
      venueAddress: this.dataHelper.findVenueAddress(session.venueId),
      orderItems: this.buildOrderDetailItems(orderItems),
      audiences: this.buildOrderDetailAudiences(order.orderId),
      deliveryType: order.deliveryType,
      address: this.buildOrderDetailAddress(order.orderId),
      createTime: order.createTime,
      payExpireTime: order.payExpireTime,
      payTime: order.payTime,
      ticketIssuedTime: this.ticketService.buildTicketIssuedTime(order),
      cancelTime: order.cancelTime,
      finishTime: order.finishTime,
      refundTime: this.buildRefundTime(refundRecord),
      totalAmount: order.totalAmount,
      serviceFee: this.sumServiceFee(orderItems),
      deliveryFee: this.sumDeliveryFee(orderItems),
      payAmount: order.payAmount,
      payMethod: order.payMethod,
      refundAmount: refundRecord === undefined ? undefined : refundRecord.refundAmount,
      refundFeeAmount: refundRecord === undefined ? undefined : refundRecord.feeAmount,
      projectId: order.projectId,
      sessionId: order.sessionId,
      ticketActionType: this.ticketService.buildOrderDetailTicketActionType(order),
      defaultTicketId: this.ticketService.getDefaultViewTicketId(order.orderId)
    }

    return result
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
    this.dataHelper.findOrderAudiences(orderId).forEach((item: OrderAudience) => {
      const vo: OrderDetailAudienceVO = {
        realName: item.realName,
        maskedCertificateNo: MaskUtil.maskCertificateNo(item.certificateNo)
      }
      result.push(vo)
    })
    return result
  }

  private buildOrderDetailAddress(orderId: string): OrderDetailAddressVO | undefined {
    const address: OrderAddress | undefined = this.dataHelper.findOrderAddress(orderId)
    if (address === undefined) {
      return undefined
    }

    const vo: OrderDetailAddressVO = {
      receiverName: address.receiverName,
      receiverPhone: MaskUtil.maskPhone(address.receiverPhone),
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
      .sort((a: ServiceTag, b: ServiceTag) => {
        return a.sortOrder - b.sortOrder
      })
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

  private sumServiceFee(items: OrderItem[]): number {
    return 0
  }

  private sumDeliveryFee(items: OrderItem[]): number {
    return 0
  }

  private buildRefundTime(refundRecord: RefundRecord | undefined): string | undefined {
    if (refundRecord === undefined || refundRecord.status !== 'REFUND_SUCCESS') {
      return undefined
    }
    return refundRecord.refundTime
  }

}
