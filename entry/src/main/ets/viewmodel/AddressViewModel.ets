import {
  AddressListPageVO,
  AddressItemVO
} from '../model/vo/user/AddressPageVO'

import { UserAddress } from '../model/entity/UserAddress'
import { UserDataUtil } from '../utils/UserDataUtil'
import { AddressRegionUtil, AddressStandardCodes } from '../utils/AddressRegionUtil'

import {
  AddressRepository,
  CreateAddressRequest,
  UpdateAddressRequest
} from '../repository/AddressRepository'

export class AddressViewModel {
  addressList: AddressItemVO[] = []
  addressDetail: UserAddress | undefined = undefined

  userId: string = ''
  addressId: string = ''

  receiverName: string = ''
  receiverPhone: string = ''
  province: string = ''
  city: string = ''
  district: string = ''
  detailAddress: string = ''
  isDefault: boolean = false

  isLoading: boolean = false
  errorMessage: string = ''

  private addressRepository: AddressRepository = new AddressRepository()

  async loadList(userId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.userId = userId

    try {
      const pageVO: AddressListPageVO = await this.addressRepository.getAddressList(userId)
      this.addressList = pageVO.addresses
      this.isLoading = false
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '地址列表加载失败'
      this.isLoading = false
    }
  }

  async loadDetail(userId: string, addressId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.userId = userId
    this.addressId = addressId

    try {
      const detail: UserAddress | undefined = await this.addressRepository.getAddressDetail(userId, addressId)
      if (detail === undefined) {
        this.errorMessage = '收货地址不存在'
        this.isLoading = false
        return
      }
      this.addressDetail = detail
      this.applyDetail(detail)
      this.isLoading = false
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '收货地址加载失败'
      this.isLoading = false
    }
  }

  async createAddress(): Promise<boolean> {
    if (this.userId.length === 0) {
      this.errorMessage = '用户未登录，请先登录'
      return false
    }
    if (!this.validateForm()) {
      return false
    }

    const request: CreateAddressRequest = this.buildCreateRequest()
    try {
      const address: UserAddress | undefined = await this.addressRepository.createAddress(this.userId, request)
      if (address === undefined) {
        const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
        this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '新增地址失败，请检查收货人信息'
        return false
      }
      await this.loadList(this.userId)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '新增地址失败'
      return false
    }
  }

  async updateAddress(): Promise<boolean> {
    if (this.userId.length === 0) {
      this.errorMessage = '用户未登录，请先登录'
      return false
    }
    if (this.addressId.length === 0) {
      this.errorMessage = '地址ID不能为空'
      return false
    }
    if (!this.validateForm()) {
      return false
    }

    const request: UpdateAddressRequest = this.buildUpdateRequest()
    try {
      const address: UserAddress | undefined = await this.addressRepository.updateAddress(this.userId, this.addressId, request)
      if (address === undefined) {
        const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
        this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '修改地址失败，请检查收货人信息'
        return false
      }
      this.addressDetail = address
      await this.loadList(this.userId)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '修改地址失败'
      return false
    }
  }

  async deleteAddress(addressId: string): Promise<boolean> {
    try {
      const success: boolean = await this.addressRepository.deleteAddress(this.userId, addressId)
      if (!success) {
        const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
        this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '删除地址失败'
        return false
      }
      await this.loadList(this.userId)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '删除地址失败'
      return false
    }
  }

  async setDefaultAddress(addressId: string): Promise<boolean> {
    try {
      const success: boolean = await this.addressRepository.setDefaultAddress(this.userId, addressId)
      if (!success) {
        const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
        this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '设置默认地址失败'
        return false
      }
      await this.loadList(this.userId)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '设置默认地址失败'
      return false
    }
  }

  resetForm(userId: string): void {
    this.userId = userId
    this.addressId = ''
    this.addressDetail = undefined
    this.receiverName = ''
    this.receiverPhone = ''
    this.province = ''
    this.city = ''
    this.district = ''
    this.detailAddress = ''
    this.isDefault = false
    this.errorMessage = ''
  }

  canSave(): boolean {
    return UserDataUtil.isValidPersonName(this.receiverName) &&
      UserDataUtil.isValidPhone(this.receiverPhone) &&
      this.province.trim().length > 0 &&
      this.city.trim().length > 0 &&
      this.district.trim().length > 0 &&
      this.detailAddress.trim().length > 0
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private buildCreateRequest(): CreateAddressRequest {
    const codes: AddressStandardCodes | undefined = AddressRegionUtil.resolveStandardCodes(this.province, this.city, this.district)
    return {
      receiverName: this.receiverName.trim(),
      receiverPhone: this.receiverPhone.trim(),
      countryCode: codes?.countryCode,
      provinceCode: codes?.provinceCode,
      cityCode: codes?.cityCode,
      areaCode: codes?.areaCode,
      province: this.province.trim(),
      city: this.city.trim(),
      district: this.district.trim(),
      detailAddress: this.detailAddress.trim(),
      isDefault: this.isDefault
    }
  }

  private buildUpdateRequest(): UpdateAddressRequest {
    const codes: AddressStandardCodes | undefined = AddressRegionUtil.resolveStandardCodes(this.province, this.city, this.district)
    return {
      receiverName: this.receiverName.trim(),
      receiverPhone: this.receiverPhone.trim(),
      countryCode: codes?.countryCode,
      provinceCode: codes?.provinceCode,
      cityCode: codes?.cityCode,
      areaCode: codes?.areaCode,
      province: this.province.trim(),
      city: this.city.trim(),
      district: this.district.trim(),
      detailAddress: this.detailAddress.trim(),
      isDefault: this.isDefault
    }
  }

  private applyDetail(detail: UserAddress): void {
    this.receiverName = detail.receiverName
    this.receiverPhone = detail.receiverPhone
    this.province = detail.province
    this.city = detail.city
    this.district = detail.district
    this.detailAddress = detail.detailAddress
    this.isDefault = detail.isDefault
  }

  private validateForm(): boolean {
    if (!UserDataUtil.isValidPersonName(this.receiverName)) {
      this.errorMessage = '收货人姓名格式不正确'
      return false
    }
    if (!UserDataUtil.isValidPhone(this.receiverPhone)) {
      this.errorMessage = '手机号格式不正确'
      return false
    }
    if (this.province.trim().length === 0) {
      this.errorMessage = '请选择省份'
      return false
    }
    if (this.city.trim().length === 0) {
      this.errorMessage = '请选择城市'
      return false
    }
    if (this.district.trim().length === 0) {
      this.errorMessage = '请选择区县'
      return false
    }
    if (this.detailAddress.trim().length === 0) {
      this.errorMessage = '请输入详细地址'
      return false
    }
    if (AddressRegionUtil.resolveStandardCodes(this.province, this.city, this.district) === undefined) {
      this.errorMessage = '省市区行政区编码无效，请重新选择'
      return false
    }
    this.errorMessage = ''
    return true
  }
}
