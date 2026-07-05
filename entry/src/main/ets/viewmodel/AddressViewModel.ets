import {
  AddressListPageVO,
  AddressItemVO
} from '../model/vo/user/AddressPageVO'

import { UserAddress } from '../model/entity/UserAddress'
import { UserDataUtil } from '../utils/UserDataUtil'

import {
  AddressRepository,
  CreateAddressRequest,
  UpdateAddressRequest
} from '../repository/AddressRepository'

/**
 * 地址列表页 + 创建/编辑地址页
    地址列表
    新增地址
    编辑地址
    删除地址
    设为默认地址
    地址表单校验
 */
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

  loadList(userId: string): void {
    this.isLoading = true
    this.errorMessage = ''
    this.userId = userId

    const pageVO: AddressListPageVO = this.addressRepository.getAddressList(userId)
    this.addressList = pageVO.addresses

    this.isLoading = false
  }

  loadDetail(userId: string, addressId: string): void {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    this.addressId = addressId

    const detail: UserAddress | undefined =
      this.addressRepository.getAddressDetail(userId, addressId)

    if (detail === undefined) {
      this.errorMessage = '收货地址不存在'
      this.isLoading = false
      return
    }

    this.addressDetail = detail
    this.applyDetail(detail)

    this.isLoading = false
  }

  createAddress(): boolean {
    if (this.userId.length === 0) {
      this.errorMessage = '用户未登录，请先登录'
      return false
    }

    if (!this.validateForm()) {
      return false
    }

    const request: CreateAddressRequest = {
      receiverName: this.receiverName.trim(),
      receiverPhone: this.receiverPhone.trim(),
      province: this.province.trim(),
      city: this.city.trim(),
      district: this.district.trim(),
      detailAddress: this.detailAddress.trim(),
      isDefault: this.isDefault
    }

    const address: UserAddress | undefined =
      this.addressRepository.createAddress(this.userId, request)

    if (address === undefined) {
      const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
      this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '新增地址失败，请检查收货人信息'
      return false
    }

    this.loadList(this.userId)
    return true
  }

  updateAddress(): boolean {
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

    const request: UpdateAddressRequest = {
      receiverName: this.receiverName.trim(),
      receiverPhone: this.receiverPhone.trim(),
      province: this.province.trim(),
      city: this.city.trim(),
      district: this.district.trim(),
      detailAddress: this.detailAddress.trim(),
      isDefault: this.isDefault
    }

    const address: UserAddress | undefined =
      this.addressRepository.updateAddress(this.userId, this.addressId, request)

    if (address === undefined) {
      const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
      this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '修改地址失败，请检查收货人信息'
      return false
    }

    this.addressDetail = address
    this.loadList(this.userId)
    return true
  }

  deleteAddress(addressId: string): boolean {
    const success: boolean =
      this.addressRepository.deleteAddress(this.userId, addressId)

    if (!success) {
      const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
      this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '删除地址失败'
      return false
    }

    this.loadList(this.userId)
    return true
  }

  setDefaultAddress(addressId: string): boolean {
    const success: boolean =
      this.addressRepository.setDefaultAddress(this.userId, addressId)

    if (!success) {
      const repositoryErrorMessage: string = this.addressRepository.getLastErrorMessage()
      this.errorMessage = repositoryErrorMessage.length > 0 ? repositoryErrorMessage : '设置默认地址失败'
      return false
    }

    this.loadList(this.userId)
    return true
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

    this.errorMessage = ''
    return true
  }
}