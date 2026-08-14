import {
  AddressListPageVO,
  AddressItemVO
} from '../model/vo/user/AddressPageVO'
import { UserAddress } from '../model/entity/UserAddress'
import { ApiClient } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

export interface CreateAddressRequest {
  countryCode?: string | null
  provinceCode?: string | null
  cityCode?: string | null
  areaCode?: string | null
  receiverName?: string | null
  receiverPhone?: string | null
  province?: string | null
  city?: string | null
  district?: string | null
  detailAddress?: string | null
  isDefault?: boolean | null
}

export interface UpdateAddressRequest {
  countryCode?: string | null
  provinceCode?: string | null
  cityCode?: string | null
  areaCode?: string | null
  receiverName?: string | null
  receiverPhone?: string | null
  province?: string | null
  city?: string | null
  district?: string | null
  detailAddress?: string | null
  isDefault?: boolean | null
}

interface BackendAddressItemVO {
  addressId: number | string
  receiverName?: string | null
  maskedReceiverPhone?: string | null
  fullAddress?: string | null
  isDefault?: boolean | null
}

interface BackendAddressDetailVO {
  countryCode?: string | null
  provinceCode?: string | null
  cityCode?: string | null
  areaCode?: string | null
  addressId: number | string
  receiverName?: string | null
  receiverPhone?: string | null
  province?: string | null
  city?: string | null
  district?: string | null
  detailAddress?: string | null
  isDefault?: boolean | null
}

interface BackendAddressListPageVO {
  addresses: BackendAddressItemVO[]
}

interface OperateResponse {
  success: boolean
}

/** 收货地址 Repository：从 SpringBoot 接口读写，不再使用 Mock。 */
export class AddressRepository {
  private lastErrorMessage: string = ''

  getLastErrorMessage(): string {
    return this.lastErrorMessage
  }

  async getAddressList(userId: string): Promise<AddressListPageVO> {
    this.lastErrorMessage = ''
    if (userId.length === 0) {
      return { addresses: [] }
    }

    const response: BackendAddressListPageVO =
      await ApiClient.get<BackendAddressListPageVO>('/api/users/' + encodeURIComponent(userId) + '/addresses')

    return {
      addresses: (response.addresses ?? []).map((item: BackendAddressItemVO): AddressItemVO => {
        return {
          addressId: String(item.addressId),
          receiverName: item.receiverName ?? '',
          maskedReceiverPhone: item.maskedReceiverPhone ?? '',
          fullAddress: item.fullAddress ?? '',
          isDefault: item.isDefault === true
        }
      })
    }
  }

  async getAddressDetail(userId: string, addressId: string): Promise<UserAddress | undefined> {
    this.lastErrorMessage = ''
    if (userId.length === 0 || addressId.length === 0) {
      return undefined
    }

    const response: BackendAddressDetailVO =
      await ApiClient.get<BackendAddressDetailVO>('/api/users/' + encodeURIComponent(userId) + '/addresses/' + encodeURIComponent(addressId))

    return this.mapAddressDetail(userId, response)
  }

  async createAddress(userId: string, request: CreateAddressRequest): Promise<UserAddress | undefined> {
    this.lastErrorMessage = ''
    if (userId.length === 0) {
      return undefined
    }

    const response: BackendAddressDetailVO =
      await ApiClient.post<BackendAddressDetailVO>('/api/users/' + encodeURIComponent(userId) + '/addresses', request)

    const address: UserAddress = this.mapAddressDetail(userId, response)
    AppStorageVersionUtil.bumpAddressListVersion()
    return address
  }

  async updateAddress(userId: string, addressId: string, request: UpdateAddressRequest): Promise<UserAddress | undefined> {
    this.lastErrorMessage = ''
    if (userId.length === 0 || addressId.length === 0) {
      return undefined
    }

    const response: BackendAddressDetailVO =
      await ApiClient.put<BackendAddressDetailVO>('/api/users/' + encodeURIComponent(userId) + '/addresses/' + encodeURIComponent(addressId), request)

    const address: UserAddress = this.mapAddressDetail(userId, response)
    AppStorageVersionUtil.bumpAddressListVersion()
    return address
  }

  async deleteAddress(userId: string, addressId: string): Promise<boolean> {
    this.lastErrorMessage = ''
    if (userId.length === 0 || addressId.length === 0) {
      return false
    }

    const response: OperateResponse =
      await ApiClient.delete<OperateResponse>('/api/users/' + encodeURIComponent(userId) + '/addresses/' + encodeURIComponent(addressId))

    if (response.success) AppStorageVersionUtil.bumpAddressListVersion()
    return response.success
  }

  async setDefaultAddress(userId: string, addressId: string): Promise<boolean> {
    this.lastErrorMessage = ''
    if (userId.length === 0 || addressId.length === 0) {
      return false
    }

    const response: OperateResponse =
      await ApiClient.put<OperateResponse>('/api/users/' + encodeURIComponent(userId) + '/addresses/' + encodeURIComponent(addressId) + '/default')

    if (response.success) AppStorageVersionUtil.bumpAddressListVersion()
    return response.success
  }

  private mapAddressDetail(userId: string, raw: BackendAddressDetailVO): UserAddress {
    return {
      addressId: String(raw.addressId),
      userId: userId,
      receiverName: raw.receiverName ?? '',
      receiverPhone: raw.receiverPhone ?? '',
      countryCode: raw.countryCode ?? '',
      provinceCode: raw.provinceCode ?? '',
      cityCode: raw.cityCode ?? '',
      areaCode: raw.areaCode ?? '',
      province: raw.province ?? '',
      city: raw.city ?? '',
      district: raw.district ?? '',
      detailAddress: raw.detailAddress ?? '',
      isDefault: raw.isDefault === true
    }
  }
}
