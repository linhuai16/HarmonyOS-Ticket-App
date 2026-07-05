import {
  SubmitOrderPageVO
} from '../model/vo/order/SubmitOrderPageVO'

import {
  AudienceListPageVO,
  AudienceItemVO
} from '../model/vo/user/AudiencePageVO'

import {
  AddressListPageVO,
  AddressItemVO
} from '../model/vo/user/AddressPageVO'

import {
  OrderRepository,
  ConfirmOrderRequest,
  CreateOrderRequest,
  CreateOrderResponse
} from '../repository/OrderRepository'

import { AudienceRepository } from '../repository/AudienceRepository'
import { AddressRepository } from '../repository/AddressRepository'
import { UserRepository } from '../repository/UserRepository'
import { DeliveryType } from '../model/enums/DeliveryType'

export class SubmitOrderViewModel {
  pageVO: SubmitOrderPageVO | undefined = undefined

  audienceList: AudienceItemVO[] = []
  addressList: AddressItemVO[] = []

  userId: string = ''
  projectId: string = ''
  sessionId: string = ''
  skuId: string = ''
  quantity: number = 1

  selectedAudienceIds: string[] = []
  deliveryType: DeliveryType = DeliveryType.ETICKET
  selectedAddressId: string = ''

  isLoading: boolean = false
  isSubmitting: boolean = false
  errorMessage: string = ''
  submitErrorMessage: string = ''

  createOrderResponse: CreateOrderResponse | undefined = undefined

  private orderRepository: OrderRepository = new OrderRepository()
  private audienceRepository: AudienceRepository = new AudienceRepository()
  private addressRepository: AddressRepository = new AddressRepository()
  private userRepository: UserRepository = new UserRepository()

  async loadPage(userId: string, projectId: string, sessionId: string, skuId: string, quantity: number): Promise<void> {
    this.selectedAudienceIds = []
    this.selectedAddressId = ''
    this.createOrderResponse = undefined
    this.isLoading = true
    this.errorMessage = ''
    this.submitErrorMessage = ''

    const effectiveUserId: string = this.resolveEffectiveUserId(userId)

    this.userId = effectiveUserId
    this.projectId = projectId
    this.sessionId = sessionId
    this.skuId = skuId
    this.quantity = quantity

    const request: ConfirmOrderRequest = {
      projectId: projectId,
      sessionId: sessionId,
      skuId: skuId,
      quantity: quantity
    }

    const pageVO: SubmitOrderPageVO | undefined =
      await this.orderRepository.getSubmitOrderPage(request)

    if (pageVO === undefined) {
      this.errorMessage = '确认订单数据不存在'
      this.isLoading = false
      return
    }

    this.pageVO = pageVO
    this.deliveryType = pageVO.deliveryType

    this.loadAudienceList(effectiveUserId, true)
    this.loadAddressList(effectiveUserId, true)

    if (this.deliveryType === DeliveryType.ETICKET) {
      this.selectedAddressId = ''
    }

    this.isLoading = false
  }

  loadAudienceList(
    userId: string,
    applyDefault: boolean = true,
    preferDefaultAudience: boolean = false
  ): void {
    const audiencePageVO: AudienceListPageVO =
      this.audienceRepository.getAudienceList(userId)

    this.audienceList = audiencePageVO.audiences
    this.syncSelectedAudienceAfterListChanged(applyDefault, preferDefaultAudience)
  }

  loadAddressList(
    userId: string,
    applyDefault: boolean = true,
    preferDefaultAddress: boolean = false
  ): void {
    const addressPageVO: AddressListPageVO =
      this.addressRepository.getAddressList(userId)

    this.addressList = addressPageVO.addresses
    this.syncSelectedAddressAfterListChanged(applyDefault, preferDefaultAddress)
  }

  selectAudience(audienceId: string): void {
    if (this.pageVO === undefined) {
      return
    }

    this.submitErrorMessage = ''

    const existIndex: number = this.selectedAudienceIds.indexOf(audienceId)

    if (existIndex >= 0) {
      this.selectedAudienceIds = this.selectedAudienceIds.filter((selectedAudienceId: string) => {
        return selectedAudienceId !== audienceId
      })
      return
    }

    if (this.pageVO.requiredAudienceCount === 1) {
      this.selectedAudienceIds = [audienceId]
      return
    }

    if (this.selectedAudienceIds.length >= this.pageVO.requiredAudienceCount) {
      this.submitErrorMessage = `最多选择 ${this.pageVO.requiredAudienceCount} 位观演人`
      return
    }

    this.selectedAudienceIds = this.selectedAudienceIds.concat([audienceId])
  }
  //同步观演人列表变化后的选择状态
  private syncSelectedAudienceAfterListChanged(
    applyDefault: boolean,
    preferDefaultAudience: boolean
  ): void {
    const validAudienceIds: string[] = this.audienceList.map((item: AudienceItemVO) => item.audienceId)

    this.selectedAudienceIds = this.selectedAudienceIds.filter((audienceId: string) => {
      return validAudienceIds.indexOf(audienceId) >= 0
    })

    if (this.pageVO === undefined) {
      return
    }

    const requiredCount: number = this.pageVO.requiredAudienceCount

    if (requiredCount <= 0) {
      this.selectedAudienceIds = []
      return
    }

    if (this.selectedAudienceIds.length > requiredCount) {
      this.selectedAudienceIds = this.selectedAudienceIds.slice(0, requiredCount)
    }

    if (!applyDefault) {
      return
    }

    const defaultAudience: AudienceItemVO | undefined =
      this.audienceList.find((item: AudienceItemVO) => item.isDefault)

    if (defaultAudience === undefined) {
      return
    }

    if (preferDefaultAudience || this.selectedAudienceIds.length === 0) {
      if (requiredCount === 1) {
        this.selectedAudienceIds = [defaultAudience.audienceId]
        return
      }

      const remainSelectedIds: string[] = this.selectedAudienceIds.filter((audienceId: string) => {
        return audienceId !== defaultAudience.audienceId
      })

      this.selectedAudienceIds = [defaultAudience.audienceId]
        .concat(remainSelectedIds)
        .slice(0, requiredCount)
    }
  }

  private applyDeliveryTypeFromPageVO(): void {
    if (this.pageVO === undefined) {
      this.deliveryType = DeliveryType.ETICKET
      this.selectedAddressId = ''
      return
    }

    this.deliveryType = this.pageVO.deliveryType

    if (this.deliveryType === DeliveryType.ETICKET) {
      this.selectedAddressId = ''
      return
    }

    if (this.deliveryType === DeliveryType.PAPER_TICKET) {
      this.applyDefaultAddressSelection()
    }
  }


  selectAddress(addressId: string): void {
    this.submitErrorMessage = ''
    this.selectedAddressId = addressId
  }

  /**
   * 同步地址列表变化后的选中状态
   *
   * 场景：
   * 1. 从地址新增页返回提交订单页后，地址列表刷新；
   * 2. 新增地址被设为默认地址时，需要优先选中新默认地址；
   * 3. 如果原来选中的地址已经不存在，需要清空选中；
   * 4. 如果当前订单是电子票，不需要地址，直接清空 selectedAddressId。
   */
  private syncSelectedAddressAfterListChanged(
    applyDefault: boolean,
    preferDefaultAddress: boolean
  ): void {
    if (this.deliveryType !== DeliveryType.PAPER_TICKET) {
      this.selectedAddressId = ''
      return
    }

    const selectedAddress: AddressItemVO | undefined =
      this.addressList.find((item: AddressItemVO) => {
        return item.addressId === this.selectedAddressId
      })

    if (selectedAddress === undefined) {
      this.selectedAddressId = ''
    }

    if (!applyDefault) {
      return
    }

    const defaultAddress: AddressItemVO | undefined =
      this.addressList.find((item: AddressItemVO) => {
        return item.isDefault
      })

    if (defaultAddress === undefined) {
      return
    }

    if (preferDefaultAddress || this.selectedAddressId.length === 0) {
      this.selectedAddressId = defaultAddress.addressId
    }
  }

  //默认地址选择方法
  private applyDefaultAddressSelection(): void {
    if (this.deliveryType !== DeliveryType.PAPER_TICKET) {
      return
    }

    if (this.selectedAddressId.length > 0) {
      return
    }

    const defaultAddress: AddressItemVO | undefined =
      this.addressList.find((item: AddressItemVO) => item.isDefault)

    if (defaultAddress !== undefined) {
      this.selectedAddressId = defaultAddress.addressId
    }
  }

  canSubmit(): boolean {
    if (this.pageVO === undefined) {
      return false
    }

    if (this.selectedAudienceIds.length !== this.pageVO.requiredAudienceCount) {
      return false
    }

    if (this.deliveryType === DeliveryType.PAPER_TICKET && this.selectedAddressId.length === 0) {
      return false
    }
    return true
  }
  private validateBeforeSubmit(): boolean {
    if (this.pageVO === undefined) {
      this.submitErrorMessage = '订单数据不存在'
      return false
    }

    if (this.selectedAudienceIds.length !== this.pageVO.requiredAudienceCount) {
      this.submitErrorMessage = '请选择观演人'
      return false
    }

    if (this.deliveryType === DeliveryType.PAPER_TICKET && this.selectedAddressId.length === 0) {
      this.submitErrorMessage = '请选择收货地址'
      return false
    }

    this.submitErrorMessage = ''
    return true
  }


  async submitOrder(): Promise<CreateOrderResponse | undefined> {
    const effectiveUserId: string = this.resolveEffectiveUserId(this.userId)
    if (effectiveUserId.length === 0 || !this.userRepository.isLogin()) {
      this.submitErrorMessage = '请先登录后再提交订单'
      return undefined
    }
    this.userId = effectiveUserId

    if (!this.validateBeforeSubmit()) {
      return undefined
    }

    this.isSubmitting = true
    this.errorMessage = ''

    const request: CreateOrderRequest = {
      userId: this.userId,
      projectId: this.projectId,
      sessionId: this.sessionId,
      skuId: this.skuId,
      quantity: this.quantity,
      audienceIds: this.selectedAudienceIds,
      deliveryType: this.deliveryType,
      addressId: this.selectedAddressId.length === 0 ? undefined : this.selectedAddressId
    }

    const response: CreateOrderResponse | undefined =
      await this.orderRepository.createOrder(request)

    if (response === undefined) {
      const repositoryErrorMessage: string = this.orderRepository.getLastErrorMessage()
      this.errorMessage = repositoryErrorMessage.length > 0 ?
        repositoryErrorMessage :
        '提交订单失败，请重新选择票档或观演人'
      this.isSubmitting = false
      return undefined
    }

    this.createOrderResponse = response
    this.isSubmitting = false
    return response
  }

  refreshAudienceList(preferDefaultAudience: boolean = false): void {
    const effectiveUserId: string = this.resolveEffectiveUserId(this.userId)
    this.userId = effectiveUserId

    if (effectiveUserId.length === 0) {
      this.audienceList = []
      this.selectedAudienceIds = []
      return
    }

    this.loadAudienceList(effectiveUserId, true, preferDefaultAudience)
  }
  //判断观演人是否选中
  isAudienceSelected(audienceId: string): boolean {
    return this.selectedAudienceIds.indexOf(audienceId) >= 0
  }
  //观演人选择数量文案
  getAudienceSelectText(): string {
    if (this.pageVO === undefined) {
      return ''
    }

    return `已选择 ${this.selectedAudienceIds.length}/${this.pageVO.requiredAudienceCount} 位`
  }

  //刷新地址方法
  refreshAddressList(preferDefaultAddress: boolean = false): void {
    const effectiveUserId: string = this.resolveEffectiveUserId(this.userId)
    this.userId = effectiveUserId

    if (effectiveUserId.length === 0) {
      this.addressList = []
      this.selectedAddressId = ''
      return
    }

    this.loadAddressList(effectiveUserId, true, preferDefaultAddress)
  }
  //地址是否选中判断
  isAddressSelected(addressId: string): boolean {
    return this.selectedAddressId === addressId
  }
  //获取当前选中地址方法
  getSelectedAddress(): AddressItemVO | undefined {
    return this.addressList.find((item: AddressItemVO) => item.addressId === this.selectedAddressId)
  }


  //是否展示地址区域
  shouldShowAddressArea(): boolean {
    return this.deliveryType === DeliveryType.PAPER_TICKET
  }
  //配送方式文案
  getDeliveryTypeText(): string {
    if (this.deliveryType === DeliveryType.PAPER_TICKET) {
      return '快递票'
    }

    return '电子票'
  }
  //配送方式提示
  getDeliveryTipText(): string {
    if (this.deliveryType === DeliveryType.PAPER_TICKET) {
      return '实体票将通过快递配送，请选择收货地址'
    }

    return '支付成功后，无需取票，前往票夹查看入场凭证'
  }
  // 是否还能继续选择观演人
  canSelectMoreAudience(): boolean {
    if (this.pageVO === undefined) {
      return false
    }

    return this.selectedAudienceIds.length < this.pageVO.requiredAudienceCount
  }

  private resolveEffectiveUserId(userId: string = ''): string {
    const normalizedUserId: string = userId.trim()
    if (normalizedUserId.length > 0) {
      return normalizedUserId
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  isLogin(): boolean {
    return this.userRepository.isLogin()
  }

  clearError(): void {
    this.errorMessage = ''
  }
}