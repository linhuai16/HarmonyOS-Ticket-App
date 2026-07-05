import { Audience } from '../../model/entity/Audience'
import { UserAddress } from '../../model/entity/UserAddress'
import { OrderAudience } from '../../model/entity/OrderAudience'
import { OrderAddress } from '../../model/entity/OrderAddress'
import { OrderDataHelper } from './OrderDataHelper'
import { IdGenerator } from '../../utils/IdGenerator'

export class OrderSnapshotService {
  private dataHelper: OrderDataHelper

  constructor(dataHelper: OrderDataHelper) {
    this.dataHelper = dataHelper
  }

  createAudienceSnapshots(orderId: string, audiences: Audience[]): void {
    audiences.forEach((audience: Audience, index: number) => {
      const snapshot: OrderAudience = {
        orderAudienceId: IdGenerator.createOrderAudienceId(index),
        orderId: orderId,
        realName: audience.realName,
        certificateType: audience.certificateType,
        certificateNo: audience.certificateNo,
        phone: audience.phone
      }
      this.dataHelper.getOrderAudienceStore().push(snapshot)
    })
  }

  createAddressSnapshot(orderId: string, address: UserAddress): void {
    const snapshot: OrderAddress = {
      orderAddressId: IdGenerator.createOrderAddressId(),
      orderId: orderId,
      receiverName: address.receiverName,
      receiverPhone: address.receiverPhone,
      province: address.province,
      city: address.city,
      district: address.district,
      detailAddress: address.detailAddress
    }
    this.dataHelper.getOrderAddressStore().push(snapshot)
  }
}
