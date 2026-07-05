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
} from '../../mock/MockIndex'

import { Order } from '../../model/entity/Order'
import { OrderItem } from '../../model/entity/OrderItem'
import { ElectronicTicket } from '../../model/entity/ElectronicTicket'
import { OrderAudience } from '../../model/entity/OrderAudience'
import { OrderAddress } from '../../model/entity/OrderAddress'
import { PerformanceProject } from '../../model/entity/PerformanceProject'
import { PerformanceSession } from '../../model/entity/PerformanceSession'
import { TicketSku } from '../../model/entity/TicketSku'
import { Audience } from '../../model/entity/Audience'
import { UserAddress } from '../../model/entity/UserAddress'
import { RefundRecord } from '../../model/entity/RefundRecord'
import { Category } from '../../model/entity/Category'
import { Venue } from '../../model/entity/Venue'
import { OrderStatus } from '../../model/enums/OrderStatus'

export class OrderDataHelper {
  findProject(projectId: string): PerformanceProject | undefined {
    return performanceProjectMockList.find((item: PerformanceProject) => item.projectId === projectId)
  }

  findSession(sessionId: string): PerformanceSession | undefined {
    return performanceSessionMockList.find((item: PerformanceSession) => item.sessionId === sessionId)
  }

  findCategoryName(categoryId: string): string {
    const category: Category | undefined = categoryMockList.find((item: Category) => item.categoryId === categoryId)
    return category?.categoryName ?? ''
  }

  findVenue(venueId: string): Venue | undefined {
    return venueMockList.find((item: Venue) => item.venueId === venueId)
  }

  findVenueName(venueId: string): string {
    const venue: Venue | undefined = this.findVenue(venueId)
    return venue?.venueName ?? ''
  }

  findVenueAddress(venueId: string): string {
    const venue: Venue | undefined = this.findVenue(venueId)
    return venue?.address ?? ''
  }

  findSku(skuId: string): TicketSku | undefined {
    return ticketSkuMockList.find((item: TicketSku) => item.skuId === skuId)
  }

  findOrder(userId: string, orderId: string): Order | undefined {
    return orderMockList.find((item: Order) => item.userId === userId && item.orderId === orderId)
  }

  findOrderById(orderId: string): Order | undefined {
    return orderMockList.find((item: Order) => item.orderId === orderId)
  }

  findOrderItem(orderId: string): OrderItem | undefined {
    return orderItemMockList.find((item: OrderItem) => item.orderId === orderId)
  }

  findOrderItems(orderId: string): OrderItem[] {
    return orderItemMockList.filter((item: OrderItem) => item.orderId === orderId)
  }

  findAudiences(userId: string, audienceIds: string[]): Audience[] {
    return audienceMockList.filter((item: Audience) => {
      return item.userId === userId && audienceIds.indexOf(item.audienceId) >= 0
    })
  }

  findAddress(userId: string, addressId: string): UserAddress | undefined {
    return userAddressMockList.find((item: UserAddress) => {
      return item.userId === userId && item.addressId === addressId
    })
  }

  findOrderAddress(orderId: string): OrderAddress | undefined {
    return orderAddressMockList.find((item: OrderAddress) => item.orderId === orderId)
  }

  findOrderAudiences(orderId: string): OrderAudience[] {
    return orderAudienceMockList.filter((item: OrderAudience) => item.orderId === orderId)
  }

  findTickets(orderId: string): ElectronicTicket[] {
    return electronicTicketMockList.filter((item: ElectronicTicket) => item.orderId === orderId)
  }

  findRefundRecord(orderId: string): RefundRecord | undefined {
    return refundRecordMockList.find((item: RefundRecord) => item.orderId === orderId)
  }

  findUserOrders(userId: string): Order[] {
    return orderMockList.filter((item: Order) => item.userId === userId)
  }

  findActiveOrders(userId: string, projectId: string, sessionId: string): Order[] {
    return orderMockList.filter((order: Order) => {
      return order.userId === userId &&
        order.projectId === projectId &&
        order.sessionId === sessionId &&
        order.orderStatus !== OrderStatus.CANCELED &&
        order.orderStatus !== OrderStatus.REFUND_SUCCESS
    })
  }

  addOrder(order: Order): void {
    orderMockList.push(order)
  }

  addOrderItem(item: OrderItem): void {
    orderItemMockList.push(item)
  }

  getOrderListStore(): Order[] {
    return orderMockList
  }

  getOrderItemStore(): OrderItem[] {
    return orderItemMockList
  }

  getTicketStore(): ElectronicTicket[] {
    return electronicTicketMockList
  }

  getOrderAudienceStore(): OrderAudience[] {
    return orderAudienceMockList
  }

  getOrderAddressStore(): OrderAddress[] {
    return orderAddressMockList
  }
}
