import { AudienceItemVO, AudienceListPageVO } from '../model/vo/user/AudiencePageVO'
import { AddressItemVO, AddressListPageVO } from '../model/vo/user/AddressPageVO'
import { TicketSelectPageVO, TicketSkuSelectVO } from '../model/vo/performance/TicketSelectPageVO'
import { PurchaseFulfillmentOptionVO, PurchaseOptionsVO } from '../model/vo/ticketsource/PurchaseOptionVO'
import { V13AudienceEligibilityVO, V13FulfillmentOptionVO, V13PurchaseInitVO, V13SubmitOrderVO } from '../model/vo/ticketsource/PurchaseV13VO'
import { QuotedOrderCreateVO, OrderActionVO } from '../model/vo/ticketsource/OrderQuoteVO'
import { OrderTicketSelectionRequest } from '../model/vo/ticketsource/TicketSourceTypes'
import { MoneyUtil } from '../model/vo/ticketsource/MoneyVO'
import { PayMethod } from '../model/enums/PayMethod'
import { PerformanceRepository } from '../repository/PerformanceRepository'
import { AudienceRepository } from '../repository/AudienceRepository'
import { AddressRepository } from '../repository/AddressRepository'
import { TicketSourcePurchaseRepository } from '../repository/TicketSourcePurchaseRepository'
import { UserRepository } from '../repository/UserRepository'

/**
 * V1.3-B10R-5 提交订单页 VM。
 * 页面金额只按展示价 + 配置配送费计算；点击提交订单时后端再做最终实时确认、锁库存、创建订单。
 */
export class SubmitOrderViewModel {
  pageVO: TicketSelectPageVO | undefined = undefined
  selectedSku: TicketSkuSelectVO | undefined = undefined
  purchaseOptions: PurchaseOptionsVO | undefined = undefined
  fulfillmentOptions: PurchaseFulfillmentOptionVO[] = []
  selectedFulfillmentOption: PurchaseFulfillmentOptionVO | undefined = undefined

  audienceList: AudienceItemVO[] = []
  addressList: AddressItemVO[] = []
  audienceEligibility: V13AudienceEligibilityVO[] = []
  selectedAudienceIds: string[] = []
  selectedAddressId: string = ''

  createdOrder: QuotedOrderCreateVO | undefined = undefined
  purchaseInit: V13PurchaseInitVO | undefined = undefined
  estimatedTicketAmountMinor: number = 0
  estimatedDeliveryFeeMinor: number = 0
  estimatedPayAmountMinor: number = 0
  clientSubmitNo: string = ''
  priceChangedAwaitingConfirm: boolean = false

  userId: string = ''
  projectId: string = ''
  sessionId: string = ''
  skuId: string = ''
  quantity: number = 1

  isLoading: boolean = false
  isCreating: boolean = false
  isPaying: boolean = false
  errorMessage: string = ''
  actionErrorMessage: string = ''
  private inventoryChangedAfterSubmit: boolean = false

  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private audienceRepository: AudienceRepository = new AudienceRepository()
  private addressRepository: AddressRepository = new AddressRepository()
  private purchaseRepository: TicketSourcePurchaseRepository = new TicketSourcePurchaseRepository()
  private userRepository: UserRepository = new UserRepository()
  private pageNonce: string = ''

  async loadPage(userId: string, projectId: string, sessionId: string, skuId: string, quantity: number): Promise<void> {
    const keepCurrentData: boolean = this.pageVO !== undefined && this.projectId === projectId &&
      this.sessionId === sessionId && this.skuId === skuId
    if (!keepCurrentData) {
      this.resetState()
    }
    this.isLoading = true
    this.errorMessage = ''
    this.userId = this.resolveEffectiveUserId(userId)
    this.projectId = projectId
    this.sessionId = sessionId
    this.skuId = skuId
    this.quantity = quantity > 0 ? quantity : 1
    this.pageNonce = String(Date.now())

    try {
      const page: TicketSelectPageVO | undefined =
        await this.performanceRepository.getTicketSelectPage(projectId, sessionId)
      if (page === undefined) throw new Error('票档页面数据不存在')
      const sku: TicketSkuSelectVO | undefined = page.skus.find((item: TicketSkuSelectVO) => item.skuId === skuId)
      if (sku === undefined) throw new Error('当前票档不存在')
      if (this.quantity > page.limitPerOrder) throw new Error('购买数量超过场次限购')
      if (sku.stockAvailable !== undefined && this.quantity > sku.stockAvailable) throw new Error('当前票档库存不足，请重新选择')

      const init: V13PurchaseInitVO = await this.purchaseRepository.initPurchase(this.userId, projectId, sessionId, skuId, this.quantity)
      if (!init.inventoryView.canContinue) {
        throw new Error(init.inventoryView.displayText.length > 0 ? init.inventoryView.displayText : '当前票档不可购买')
      }
      if (this.quantity > init.limitPerOrder) throw new Error('购买数量超过限购')
      if (init.inventoryView.availableStock !== undefined && this.quantity > init.inventoryView.availableStock) {
        throw new Error('当前票档库存不足，请重新选择')
      }

      const v13Options: PurchaseFulfillmentOptionVO[] = init.fulfillmentOptions.map(
        (item: V13FulfillmentOptionVO): PurchaseFulfillmentOptionVO => {
          return {
            optionCode: item.optionCode,
            ticketMode: item.credentialType,
            deliveryMode: item.deliveryMethod,
            label: item.displayName,
            requiresAddress: item.requiresAddress,
            recommended: item.recommended,
            deliveryFee: item.deliveryFee
          }
        }
      )
      const options: PurchaseOptionsVO = {
        projectId: init.projectId,
        sessionId: init.sessionId,
        skuId: init.skuId,
        saleable: init.inventoryView.canContinue,
        purchaseMode: init.purchaseMode,
        limitPerOrder: init.limitPerOrder,
        stockAvailable: init.inventoryView.availableStock,
        stockExact: init.inventoryView.exact,
        options: v13Options,
        warnings: []
      }

      this.pageVO = page
      this.selectedSku = sku
      this.purchaseInit = init
      this.audienceEligibility = init.audienceEligibility
      this.estimatedTicketAmountMinor = init.estimatedAmount.ticketAmount.amountMinor
      this.purchaseOptions = options
      this.fulfillmentOptions = options.options
      this.selectedFulfillmentOption = this.findRecommendedOption(options.options)
      this.refreshDeliveryFeeBySelectedOption()

      if (this.userId.length > 0) {
        await this.loadAudienceList(true, false)
        await this.loadAddressList(true, false)
      }
      this.applyAddressRequirement()
      this.updateActionHint()
    } catch (error) {
      const safeMessage: string = this.toUserSafeMessage(this.message(error, '提交订单页加载失败'))
      this.errorMessage = safeMessage
      if (safeMessage.indexOf('库存') >= 0) {
        this.inventoryChangedAfterSubmit = true
      }
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 重新拉取当前提交页所依赖的票档/库存/价格/履约方式，并尽量保留用户已经选择的观演人、地址和履约方式。
   * 用于 onPageShow 与手动刷新，避免返回上一级以后才看到后台/Provider 的最新状态。
   */
  async refreshCurrentPurchase(): Promise<void> {
    if (this.projectId.length === 0 || this.sessionId.length === 0 || this.skuId.length === 0) {
      return
    }

    const previousAudienceIds: string[] = this.selectedAudienceIds.slice()
    const previousAddressId: string = this.selectedAddressId
    const previousOptionCode: string = this.selectedFulfillmentOption?.optionCode ?? ''
    const currentUserId: string = this.resolveEffectiveUserId(this.userId)
    const projectId: string = this.projectId
    const sessionId: string = this.sessionId
    const skuId: string = this.skuId
    const quantity: number = this.quantity

    await this.loadPage(currentUserId, projectId, sessionId, skuId, quantity)
    if (this.pageVO === undefined || this.selectedSku === undefined) {
      return
    }

    if (previousOptionCode.length > 0) {
      const previousOption: PurchaseFulfillmentOptionVO | undefined = this.fulfillmentOptions.find(
        (item: PurchaseFulfillmentOptionVO) => item.optionCode === previousOptionCode)
      if (previousOption !== undefined) {
        this.selectedFulfillmentOption = previousOption
        this.refreshDeliveryFeeBySelectedOption()
      }
    }

    const validAudienceIds: string[] = this.audienceList.map((item: AudienceItemVO): string => item.audienceId)
    this.selectedAudienceIds = previousAudienceIds.filter((id: string): boolean => {
      return validAudienceIds.indexOf(id) >= 0 && this.canSelectAudience(id)
    })
    if (this.selectedAudienceIds.length > quantity) {
      this.selectedAudienceIds = this.selectedAudienceIds.slice(0, quantity)
    }

    if (previousAddressId.length > 0 && this.addressList.some((item: AddressItemVO): boolean => item.addressId === previousAddressId)) {
      this.selectedAddressId = previousAddressId
    }
    this.applyAddressRequirement()
    this.actionErrorMessage = ''
    this.updateActionHint()
  }

  async refreshAudienceList(preferDefaultAudience: boolean = false): Promise<void> {
    this.userId = this.resolveEffectiveUserId(this.userId)
    if (this.userId.length === 0) {
      this.audienceList = []
      this.selectedAudienceIds = []
      this.updateActionHint()
      return
    }
    await this.loadAudienceList(true, preferDefaultAudience)
    this.updateActionHint()
  }

  async refreshAddressList(preferDefaultAddress: boolean = false): Promise<void> {
    this.userId = this.resolveEffectiveUserId(this.userId)
    if (this.userId.length === 0) {
      this.addressList = []
      this.selectedAddressId = ''
      this.updateActionHint()
      return
    }
    await this.loadAddressList(true, preferDefaultAddress)
    this.applyAddressRequirement()
    this.updateActionHint()
  }

  selectAudience(audienceId: string): void {
    this.actionErrorMessage = ''
    if (!this.canSelectAudience(audienceId)) {
      this.actionErrorMessage = this.getAudienceDisabledReason(audienceId)
      this.updateActionHint()
      return
    }
    const index: number = this.selectedAudienceIds.indexOf(audienceId)
    if (index >= 0) {
      this.selectedAudienceIds = this.selectedAudienceIds.filter((id: string) => id !== audienceId)
      this.updateActionHint()
      return
    }
    if (this.selectedAudienceIds.length >= this.quantity) {
      this.actionErrorMessage = `最多选择 ${this.quantity} 位观演人`
      this.updateActionHint()
      return
    }
    this.selectedAudienceIds = this.selectedAudienceIds.concat([audienceId])
    this.updateActionHint()
  }

  async selectFulfillmentOption(ticketMode: string, deliveryMode: string, optionCode: string = ''): Promise<void> {
    this.actionErrorMessage = ''
    const target: PurchaseFulfillmentOptionVO | undefined = this.fulfillmentOptions.find(
      (item: PurchaseFulfillmentOptionVO) => item.ticketMode === ticketMode && item.deliveryMode === deliveryMode &&
        (optionCode.length === 0 || item.optionCode === optionCode))
    if (target === undefined) {
      this.actionErrorMessage = '当前入场/取票方式不可用'
      this.updateActionHint()
      return
    }
    this.selectedFulfillmentOption = target
    this.priceChangedAwaitingConfirm = false
    this.refreshDeliveryFeeBySelectedOption()
    this.applyAddressRequirement()
    this.updateActionHint()
  }

  async selectAddress(addressId: string): Promise<void> {
    if (!this.requiresAddress()) {
      this.selectedAddressId = ''
      this.updateActionHint()
      return
    }
    this.selectedAddressId = addressId
    this.priceChangedAwaitingConfirm = false
    this.actionErrorMessage = ''
    this.updateActionHint()
  }

  async createOrder(): Promise<QuotedOrderCreateVO | undefined> {
    this.actionErrorMessage = ''
    this.inventoryChangedAfterSubmit = false
    if (!this.validateBeforeSubmit()) {
      this.updateActionHint()
      return undefined
    }
    const option: PurchaseFulfillmentOptionVO = this.selectedFulfillmentOption as PurchaseFulfillmentOptionVO
    const tickets: OrderTicketSelectionRequest[] = this.buildTickets()
    if (this.clientSubmitNo.length === 0) {
      this.clientSubmitNo = 'APP-B10R5-' + this.pageNonce + '-' + String(Date.now())
    }
    this.isCreating = true
    try {
      const result: V13SubmitOrderVO = await this.purchaseRepository.submitOrder({
        userId: this.userId,
        projectId: this.projectId,
        sessionId: this.sessionId,
        skuId: this.skuId,
        quantity: this.quantity,
        tickets: tickets,
        fulfillmentOptionCode: option.optionCode,
        addressId: option.requiresAddress ? this.selectedAddressId : undefined,
        clientSubmitNo: this.clientSubmitNo,
        expectedPayAmountMinor: this.estimatedPayAmountMinor
      })
      if (result.priceStatus === 'CHANGED') {
        this.estimatedTicketAmountMinor = result.ticketAmount.amountMinor
        this.estimatedDeliveryFeeMinor = result.deliveryFee.amountMinor
        this.estimatedPayAmountMinor = result.payAmount.amountMinor
        this.priceChangedAwaitingConfirm = true
        this.actionErrorMessage = result.userMessage.length > 0 ? result.userMessage : '价格已更新，请确认后重新提交'
        return undefined
      }
      if (result.priceStatus !== 'CONFIRMED' || result.orderId.length === 0) {
        this.actionErrorMessage = result.userMessage.length > 0 ? result.userMessage : '订单未创建，请重新提交'
        return undefined
      }
      this.priceChangedAwaitingConfirm = false
      const created: QuotedOrderCreateVO = {
        orderId: result.orderId,
        orderNo: result.orderNo,
        orderStatus: result.orderStatus,
        paymentStatus: 'UNPAID',
        fulfillmentMode: 'TICKET_SOURCE',
        ticketCount: this.quantity,
        payAmount: result.payAmount,
        payExpireTime: result.reservationExpireAt
      }
      this.createdOrder = created
      return created
    } catch (error) {
      const message: string = this.message(error, '提交订单失败')
      const safeMessage: string = this.toUserSafeMessage(message)
      this.actionErrorMessage = safeMessage
      if (safeMessage.indexOf('库存') >= 0) {
        this.inventoryChangedAfterSubmit = true
        this.clientSubmitNo = ''
      }
      return undefined
    } finally {
      this.isCreating = false
      this.updateActionHint()
    }
  }

  async payCreatedOrder(payMethod: PayMethod): Promise<OrderActionVO | undefined> {
    if (this.createdOrder === undefined) {
      this.actionErrorMessage = '待支付订单不存在'
      return undefined
    }
    this.isPaying = true
    try {
      const paid: V13SubmitOrderVO = await this.purchaseRepository.payOrder(this.createdOrder.orderId, this.userId, payMethod)
      return {
        orderId: paid.orderId,
        orderNo: paid.orderNo,
        orderStatus: paid.orderStatus,
        paymentStatus: paid.orderStatus === 'WAIT_USE' ? 'PAID' : 'UNKNOWN',
        ticketCount: this.quantity,
        operationTime: '',
        message: paid.userMessage
      }
    } catch (error) {
      this.actionErrorMessage = this.toUserSafeMessage(this.message(error, '支付失败'))
      return undefined
    } finally {
      this.isPaying = false
    }
  }

  consumeInventoryChangedAfterSubmit(): boolean {
    const changed: boolean = this.inventoryChangedAfterSubmit
    this.inventoryChangedAfterSubmit = false
    return changed
  }

  canAttemptSubmit(): boolean {
    return !this.isCreating && this.pageVO !== undefined && this.selectedSku !== undefined
  }

  canCreateOrder(): boolean {
    return this.getSubmitDisabledReason().length === 0
  }

  getSubmitDisabledReason(): string {
    if (this.isCreating) return '订单正在提交，请勿重复操作'
    if (this.pageVO === undefined || this.selectedSku === undefined) return '订单信息未加载完成'
    if (!this.isLogin()) return '请先登录后再购票'
    if (this.selectedFulfillmentOption === undefined) return '请选择入场/取票方式'
    if (this.selectedAudienceIds.length !== this.quantity) return '观演人未选无法下单'
    for (let index: number = 0; index < this.selectedAudienceIds.length; index++) {
      const audienceId: string = this.selectedAudienceIds[index]
      if (!this.canSelectAudience(audienceId)) return this.getAudienceDisabledReason(audienceId)
    }
    if (this.hasDuplicatedSelectedAudience()) return '同一观演人不能绑定两张票'
    if (this.requiresAddress() && this.selectedAddressId.length === 0) return '快递票还未添加收货人信息，无法下单'
    return ''
  }

  requiresAddress(): boolean {
    return this.selectedFulfillmentOption?.requiresAddress ?? false
  }

  isAudienceSelected(audienceId: string): boolean {
    return this.selectedAudienceIds.indexOf(audienceId) >= 0
  }

  isAudienceDisabled(audienceId: string): boolean {
    return !this.canSelectAudience(audienceId)
  }

  getAudienceDisabledReason(audienceId: string): string {
    const eligibility: V13AudienceEligibilityVO | undefined = this.audienceEligibility.find(
      (item: V13AudienceEligibilityVO) => item.audienceId === audienceId)
    if (eligibility !== undefined && !eligibility.canSelect) {
      return eligibility.disabledReason.length > 0 ? eligibility.disabledReason : '当前观演人不可选择'
    }
    return '当前观演人不可选择'
  }

  isAddressSelected(addressId: string): boolean {
    return this.selectedAddressId === addressId
  }

  isFulfillmentSelected(item: PurchaseFulfillmentOptionVO): boolean {
    if (this.selectedFulfillmentOption === undefined) return false
    return this.selectedFulfillmentOption.optionCode === item.optionCode
  }

  getAudienceSelectText(): string {
    return `已选择 ${this.selectedAudienceIds.length}/${this.quantity} 位`
  }

  getReferencePriceText(): string {
    if (this.selectedSku === undefined) return '待确认'
    return '¥' + this.selectedSku.price.toFixed(2)
  }

  getTicketAmountText(): string {
    return MoneyUtil.format({ amountMinor: this.estimatedTicketAmountMinor, currency: 'CNY' })
  }

  getDeliveryFeeText(): string {
    return MoneyUtil.format({ amountMinor: this.estimatedDeliveryFeeMinor, currency: 'CNY' })
  }

  getPayAmountText(): string {
    return MoneyUtil.format({ amountMinor: this.estimatedPayAmountMinor, currency: 'CNY' })
  }

  getPriceTipText(): string {
    if (this.priceChangedAwaitingConfirm) return '价格已更新，请核对新的票款、快递费和合计后重新提交'
    return '页面金额为展示价预估，提交订单时以系统最终确认金额为准'
  }

  isLogin(): boolean {
    return this.userRepository.isLogin() && this.resolveEffectiveUserId(this.userId).length > 0
  }

  private async loadAudienceList(applyDefault: boolean, preferDefault: boolean): Promise<void> {
    const page: AudienceListPageVO = await this.audienceRepository.getAudienceList(this.userId)
    this.audienceList = page.audiences
    const validIds: string[] = this.audienceList.map((item: AudienceItemVO) => item.audienceId)
    this.selectedAudienceIds = this.selectedAudienceIds.filter((id: string) => validIds.indexOf(id) >= 0 && this.canSelectAudience(id))
    if (this.selectedAudienceIds.length > this.quantity) this.selectedAudienceIds = this.selectedAudienceIds.slice(0, this.quantity)
    if (applyDefault && (preferDefault || this.selectedAudienceIds.length === 0)) {
      const defaultAudience: AudienceItemVO | undefined = this.audienceList.find(
        (item: AudienceItemVO) => item.isDefault && this.canSelectAudience(item.audienceId))
      if (defaultAudience !== undefined) this.selectedAudienceIds = [defaultAudience.audienceId]
    }
  }

  private async loadAddressList(applyDefault: boolean, preferDefault: boolean): Promise<void> {
    const page: AddressListPageVO = await this.addressRepository.getAddressList(this.userId)
    this.addressList = page.addresses
    const exists: boolean = this.addressList.some((item: AddressItemVO) => item.addressId === this.selectedAddressId)
    if (!exists) this.selectedAddressId = ''
    if (applyDefault && (preferDefault || this.selectedAddressId.length === 0)) {
      const defaultAddress: AddressItemVO | undefined = this.addressList.find((item: AddressItemVO) => item.isDefault)
      if (defaultAddress !== undefined) this.selectedAddressId = defaultAddress.addressId
    }
  }

  private findRecommendedOption(options: PurchaseFulfillmentOptionVO[]): PurchaseFulfillmentOptionVO | undefined {
    const recommended: PurchaseFulfillmentOptionVO | undefined = options.find((item: PurchaseFulfillmentOptionVO) => item.recommended)
    return recommended ?? options[0]
  }

  private applyAddressRequirement(): void {
    if (!this.requiresAddress()) {
      this.selectedAddressId = ''
      return
    }
    if (this.selectedAddressId.length > 0) return
    const defaultAddress: AddressItemVO | undefined = this.addressList.find((item: AddressItemVO) => item.isDefault)
    if (defaultAddress !== undefined) this.selectedAddressId = defaultAddress.addressId
  }

  private validateBeforeSubmit(): boolean {
    const reason: string = this.getSubmitDisabledReason()
    if (reason.length > 0) {
      this.actionErrorMessage = reason.indexOf('请选择') >= 0 && reason.indexOf('观演人') >= 0 ? '观演人未选无法下单' : reason
      return false
    }
    return true
  }

  private buildTickets(): OrderTicketSelectionRequest[] {
    return this.selectedAudienceIds.map((audienceId: string, index: number): OrderTicketSelectionRequest => {
      return {
        clientTicketNo: 'B10R2-' + this.pageNonce + '-' + String(index + 1) + '-' + audienceId,
        audienceId: audienceId
      }
    })
  }

  private refreshDeliveryFeeBySelectedOption(): void {
    this.estimatedDeliveryFeeMinor = this.selectedFulfillmentOption?.deliveryFee.amountMinor ?? 0
    this.refreshEstimatedPayAmount()
  }

  private refreshEstimatedPayAmount(): void {
    this.estimatedPayAmountMinor = this.estimatedTicketAmountMinor + this.estimatedDeliveryFeeMinor
  }

  private canSelectAudience(audienceId: string): boolean {
    const eligibility: V13AudienceEligibilityVO | undefined = this.audienceEligibility.find(
      (item: V13AudienceEligibilityVO) => item.audienceId === audienceId)
    return eligibility === undefined || eligibility.canSelect
  }

  private hasDuplicatedSelectedAudience(): boolean {
    const ids: string[] = []
    for (let index: number = 0; index < this.selectedAudienceIds.length; index++) {
      const id: string = this.selectedAudienceIds[index]
      if (ids.indexOf(id) >= 0) return true
      ids.push(id)
    }
    return false
  }

  private updateActionHint(): void {
    if (this.actionErrorMessage.length > 0) return
    const reason: string = this.getSubmitDisabledReason()
    this.actionErrorMessage = reason
  }

  private resetState(): void {
    this.pageVO = undefined
    this.selectedSku = undefined
    this.purchaseOptions = undefined
    this.fulfillmentOptions = []
    this.selectedFulfillmentOption = undefined
    this.audienceList = []
    this.addressList = []
    this.audienceEligibility = []
    this.selectedAudienceIds = []
    this.selectedAddressId = ''
    this.createdOrder = undefined
    this.purchaseInit = undefined
    this.estimatedTicketAmountMinor = 0
    this.estimatedDeliveryFeeMinor = 0
    this.estimatedPayAmountMinor = 0
    this.clientSubmitNo = ''
    this.priceChangedAwaitingConfirm = false
    this.errorMessage = ''
    this.actionErrorMessage = ''
    this.inventoryChangedAfterSubmit = false
  }

  private resolveEffectiveUserId(userId: string = ''): string {
    const normalized: string = userId.trim()
    return normalized.length > 0 ? normalized : this.userRepository.getCurrentUserId().trim()
  }

  private message(error: Object, fallback: string): string {
    return error instanceof Error ? error.message : fallback
  }

  private toUserSafeMessage(message: string): string {
    let safeMessage: string = message.trim()
    const apiPrefix: string = '接口返回失败：'
    if (safeMessage.startsWith(apiPrefix)) {
      safeMessage = safeMessage.substring(apiPrefix.length).trim()
    }
    if (safeMessage.startsWith('接口返回失败，')) {
      safeMessage = safeMessage.substring('接口返回失败，'.length).trim()
    }

    return safeMessage.replace(/第三方票源/g, '票务系统')
      .replace(/第三方/g, '票务系统')
      .replace(/provider/gi, 'system')
      .replace(/adapter/gi, 'system')
      .replace(/MOCK-SKU-[A-Za-z0-9-]+/g, '当前票档')
      .replace(/MOCK[A-Za-z0-9_-]*/g, '票务系统')
  }
}
