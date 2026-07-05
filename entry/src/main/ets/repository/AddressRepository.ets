import {
  AddressListPageVO,
  AddressItemVO
} from '../model/vo/user/AddressPageVO'
import { UserAddress } from '../model/entity/UserAddress'
import { userAddressMockList } from '../mock/user/UserAddressMock'
import { MaskUtil } from '../utils/MaskUtil'
import { IdGenerator } from '../utils/IdGenerator'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { UserDataUtil } from '../utils/UserDataUtil'

export interface CreateAddressRequest {
  receiverName: string
  receiverPhone: string
  province: string
  city: string
  district: string
  detailAddress: string
  isDefault: boolean
}

export interface UpdateAddressRequest {
  receiverName: string
  receiverPhone: string
  province: string
  city: string
  district: string
  detailAddress: string
  isDefault: boolean
}

/**
 获取地址列表
 获取地址详情
 新增地址
 修改地址
 删除地址
 设为默认地址
 */
export class AddressRepository {
  private lastErrorMessage: string = ''

  getLastErrorMessage(): string {
    return this.lastErrorMessage
  }

  /**
   1. 获取地址列表
   */
  getAddressList(userId: string): AddressListPageVO {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    if (normalizedUserId.length === 0) {
      const emptyResult: AddressListPageVO = {
        addresses: new Array<AddressItemVO>()
      }
      return emptyResult
    }

    this.ensureSingleDefault(normalizedUserId)

    const userAddresses: UserAddress[] = this.getUserAddresses(normalizedUserId)
    userAddresses.sort((a: UserAddress, b: UserAddress): number => {
      return this.compareDefaultFirst(a.isDefault, b.isDefault)
    })

    const addresses: AddressItemVO[] = []
    userAddresses.forEach((item: UserAddress) => {
      addresses.push(this.buildAddressItemVO(item))
    })

    const result: AddressListPageVO = {
      addresses: addresses
    }

    return result
  }

  /**
   2. 获取地址详情
   */
  getAddressDetail(userId: string, addressId: string): UserAddress | undefined {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAddressId: string = addressId.trim()

    if (normalizedUserId.length === 0 || normalizedAddressId.length === 0) {
      return undefined
    }

    return this.findAddress(normalizedUserId, normalizedAddressId)
  }

  /**
   * 3. 新增地址
   */
  createAddress(userId: string, request: CreateAddressRequest): UserAddress | undefined {
    this.lastErrorMessage = ''

    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    if (normalizedUserId.length === 0) {
      this.lastErrorMessage = '用户未登录，请先登录'
      return undefined
    }

    const receiverName: string = request.receiverName.trim()
    const receiverPhone: string = request.receiverPhone.trim()
    const province: string = request.province.trim()
    const city: string = request.city.trim()
    const district: string = request.district.trim()
    const detailAddress: string = request.detailAddress.trim()

    if (!this.validateAddressFields(receiverName, receiverPhone, province, city, district, detailAddress)) {
      return undefined
    }

    if (this.hasSameAddress(normalizedUserId, receiverName, receiverPhone, province, city, district, detailAddress)) {
      this.lastErrorMessage = '该收货地址已存在，请勿重复添加'
      return undefined
    }

    const shouldSetDefault: boolean = request.isDefault || this.getUserAddressCount(normalizedUserId) === 0
    if (shouldSetDefault) {
      this.clearDefault(normalizedUserId)
    }

    const address: UserAddress = {
      addressId: IdGenerator.createAddressId(),
      userId: normalizedUserId,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      province: province,
      city: city,
      district: district,
      detailAddress: detailAddress,
      isDefault: shouldSetDefault
    }

    userAddressMockList.push(address)
    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAddressListVersion()

    return address
  }

  /**
   * 4. 修改地址
   */
  updateAddress(userId: string, addressId: string, request: UpdateAddressRequest): UserAddress | undefined {
    this.lastErrorMessage = ''

    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAddressId: string = addressId.trim()

    if (normalizedUserId.length === 0 || normalizedAddressId.length === 0) {
      this.lastErrorMessage = '用户未登录，请先登录'
      return undefined
    }

    const address: UserAddress | undefined = this.findAddress(normalizedUserId, normalizedAddressId)
    if (address === undefined) {
      this.lastErrorMessage = '收货地址不存在'
      return undefined
    }

    const receiverName: string = request.receiverName.trim()
    const receiverPhone: string = request.receiverPhone.trim()
    const province: string = request.province.trim()
    const city: string = request.city.trim()
    const district: string = request.district.trim()
    const detailAddress: string = request.detailAddress.trim()

    if (!this.validateAddressFields(receiverName, receiverPhone, province, city, district, detailAddress)) {
      return undefined
    }

    if (this.hasSameAddress(
      normalizedUserId,
      receiverName,
      receiverPhone,
      province,
      city,
      district,
      detailAddress,
      normalizedAddressId
    )) {
      this.lastErrorMessage = '该收货地址已存在，请勿重复添加'
      return undefined
    }

    if (request.isDefault) {
      this.clearDefault(normalizedUserId)
    }

    address.receiverName = receiverName
    address.receiverPhone = receiverPhone
    address.province = province
    address.city = city
    address.district = district
    address.detailAddress = detailAddress
    address.isDefault = request.isDefault

    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAddressListVersion()

    return address
  }

  /**
   5. 删除地址
   */
  deleteAddress(userId: string, addressId: string): boolean {
    this.lastErrorMessage = ''

    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAddressId: string = addressId.trim()

    if (normalizedUserId.length === 0 || normalizedAddressId.length === 0) {
      this.lastErrorMessage = '用户未登录，请先登录'
      return false
    }

    const index: number = userAddressMockList.findIndex((item: UserAddress): boolean => {
      return item.userId === normalizedUserId && item.addressId === normalizedAddressId
    })

    if (index < 0) {
      this.lastErrorMessage = '收货地址不存在'
      return false
    }

    const isDefault: boolean = userAddressMockList[index].isDefault
    userAddressMockList.splice(index, 1)

    if (isDefault) {
      this.resetFirstAsDefault(normalizedUserId)
    }

    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAddressListVersion()

    return true
  }

  /**
   6. 设为默认地址
   */
  setDefaultAddress(userId: string, addressId: string): boolean {
    this.lastErrorMessage = ''

    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAddressId: string = addressId.trim()

    if (normalizedUserId.length === 0 || normalizedAddressId.length === 0) {
      this.lastErrorMessage = '用户未登录，请先登录'
      return false
    }

    const address: UserAddress | undefined = this.findAddress(normalizedUserId, normalizedAddressId)
    if (address === undefined) {
      this.lastErrorMessage = '收货地址不存在'
      return false
    }

    this.clearDefault(normalizedUserId)
    address.isDefault = true
    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAddressListVersion()

    return true
  }

  private buildAddressItemVO(item: UserAddress): AddressItemVO {
    const vo: AddressItemVO = {
      addressId: item.addressId,
      receiverName: item.receiverName,
      maskedReceiverPhone: MaskUtil.maskPhone(item.receiverPhone),
      fullAddress: UserDataUtil.buildFullAddress(item),
      isDefault: item.isDefault
    }

    return vo
  }

  private getUserAddresses(userId: string): UserAddress[] {
    const addresses: UserAddress[] = []
    userAddressMockList.forEach((item: UserAddress) => {
      if (item.userId === userId) {
        addresses.push(item)
      }
    })
    return addresses
  }

  private getUserAddressCount(userId: string): number {
    let count: number = 0
    userAddressMockList.forEach((item: UserAddress) => {
      if (item.userId === userId) {
        count++
      }
    })
    return count
  }

  private findAddress(userId: string, addressId: string): UserAddress | undefined {
    return userAddressMockList.find((item: UserAddress): boolean => {
      return item.userId === userId && item.addressId === addressId
    })
  }

  private validateAddressFields(
    receiverName: string,
    receiverPhone: string,
    province: string,
    city: string,
    district: string,
    detailAddress: string
  ): boolean {
    const errorMessage: string = UserDataUtil.getAddressValidateError(
      receiverName,
      receiverPhone,
      province,
      city,
      district,
      detailAddress
    )

    if (errorMessage.length > 0) {
      this.lastErrorMessage = errorMessage
      return false
    }

    this.lastErrorMessage = ''
    return true
  }

  private hasSameAddress(
    userId: string,
    receiverName: string,
    receiverPhone: string,
    province: string,
    city: string,
    district: string,
    detailAddress: string,
    ignoreAddressId: string = ''
  ): boolean {
    return userAddressMockList.some((item: UserAddress): boolean => {
      if (item.userId !== userId) {
        return false
      }

      if (ignoreAddressId.length > 0 && item.addressId === ignoreAddressId) {
        return false
      }

      return UserDataUtil.isSameAddress(
        item,
        receiverName,
        receiverPhone,
        province,
        city,
        district,
        detailAddress
      )
    })
  }

  private compareDefaultFirst(leftIsDefault: boolean, rightIsDefault: boolean): number {
    if (leftIsDefault && !rightIsDefault) {
      return -1
    }

    if (!leftIsDefault && rightIsDefault) {
      return 1
    }

    return 0
  }

  private clearDefault(userId: string): void {
    userAddressMockList.forEach((item: UserAddress) => {
      if (item.userId === userId) {
        item.isDefault = false
      }
    })
  }

  private resetFirstAsDefault(userId: string): void {
    const first: UserAddress | undefined = userAddressMockList.find((item: UserAddress): boolean => {
      return item.userId === userId
    })

    if (first !== undefined) {
      first.isDefault = true
    }
  }

  private ensureSingleDefault(userId: string): void {
    const addresses: UserAddress[] = this.getUserAddresses(userId)
    if (addresses.length === 0) {
      return
    }

    let activeDefaultAddressId: string = ''
    addresses.forEach((item: UserAddress) => {
      if (item.isDefault) {
        activeDefaultAddressId = item.addressId
      }
    })

    if (activeDefaultAddressId.length === 0) {
      activeDefaultAddressId = addresses[0].addressId
    }

    addresses.forEach((item: UserAddress) => {
      item.isDefault = item.addressId === activeDefaultAddressId
    })
  }
}
