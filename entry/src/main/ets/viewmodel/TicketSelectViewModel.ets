import {
  TicketSelectPageVO,
  TicketSkuSelectVO
} from '../model/vo/performance/TicketSelectPageVO'

import { PerformanceRepository } from '../repository/PerformanceRepository'
import { SkuStatus } from '../model/enums/SkuStatus'

export interface TicketSelectConfirmParams {
  projectId: string
  sessionId: string
  skuId: string
  quantity: number
}

export class TicketSelectViewModel {
  pageVO: TicketSelectPageVO | undefined = undefined

  projectId: string = ''
  selectedSessionId: string = ''
  selectedSkuId: string = ''

  quantity: number = 1
  totalAmount: number = 0

  isLoading: boolean = false
  errorMessage: string = ''

  private performanceRepository: PerformanceRepository = new PerformanceRepository()

  async loadPage(projectId: string, selectedSessionId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    this.projectId = projectId
    this.selectedSessionId = selectedSessionId
    this.selectedSkuId = ''
    this.quantity = 1
    this.totalAmount = 0

    try {
      const pageVO: TicketSelectPageVO | undefined =
        await this.performanceRepository.getTicketSelectPage(projectId, selectedSessionId)

      if (pageVO === undefined) {
        this.errorMessage = '票档数据不存在'
        return
      }

      this.pageVO = pageVO
      this.selectedSessionId = pageVO.session.sessionId
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '票档数据加载失败'
    } finally {
      this.isLoading = false
    }
  }

  selectSku(skuId: string): void {
    if (this.pageVO === undefined) {
      return
    }

    this.errorMessage = ''

    if (this.selectedSkuId === skuId) {
      this.selectedSkuId = ''
      this.quantity = 1
      this.totalAmount = 0
      return
    }

    const sku: TicketSkuSelectVO | undefined = this.findSku(skuId)

    if (sku === undefined) {
      this.errorMessage = '票档不存在'
      return
    }

    if (!this.canBuySku(sku)) {
      return
    }

    this.selectedSkuId = sku.skuId
    this.quantity = 1
    this.updateTotalAmount()
  }

  increaseQuantity(): void {
    if (this.selectedSkuId.length === 0) {
      return
    }

    const maxCount: number = this.getMaxBuyCount()

    if (this.quantity >= maxCount) {
      return
    }

    this.quantity++
    this.updateTotalAmount()
  }

  decreaseQuantity(): void {
    if (this.quantity <= 1) {
      return
    }

    this.quantity--
    this.updateTotalAmount()
  }

  setQuantity(quantity: number): void {
    if (this.selectedSkuId.length === 0) {
      return
    }

    const maxCount: number = this.getMaxBuyCount()

    if (quantity < 1) {
      this.quantity = 1
    } else if (quantity > maxCount) {
      this.quantity = maxCount
    } else {
      this.quantity = quantity
    }

    this.updateTotalAmount()
  }

  canConfirm(): boolean {
    if (this.pageVO === undefined) {
      return false
    }

    if (this.selectedSessionId.length === 0 || this.selectedSkuId.length === 0) {
      return false
    }

    const sku: TicketSkuSelectVO | undefined = this.findSku(this.selectedSkuId)

    if (sku === undefined) {
      return false
    }

    if (!this.canBuySku(sku)) {
      return false
    }

    return this.quantity >= 1 && this.quantity <= this.getMaxBuyCount()
  }

  buildConfirmParams(): TicketSelectConfirmParams | undefined {
    if (!this.canConfirm()) {
      return undefined
    }

    const params: TicketSelectConfirmParams = {
      projectId: this.projectId,
      sessionId: this.selectedSessionId,
      skuId: this.selectedSkuId,
      quantity: this.quantity
    }

    return params
  }

  getSelectedSkuName(): string {
    const sku: TicketSkuSelectVO | undefined = this.findSku(this.selectedSkuId)
    return sku?.skuName ?? ''
  }

  getTotalAmount(): number {
    return this.totalAmount
  }

  canIncreaseQuantity(): boolean {
    return this.selectedSkuId.length > 0 && this.quantity < this.getMaxBuyCount()
  }

  canDecreaseQuantity(): boolean {
    return this.selectedSkuId.length > 0 && this.quantity > 1
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private updateTotalAmount(): void {
    const sku: TicketSkuSelectVO | undefined = this.findSku(this.selectedSkuId)

    if (sku === undefined) {
      this.totalAmount = 0
      return
    }

    this.totalAmount = sku.price * this.quantity
  }

  private findSku(skuId: string): TicketSkuSelectVO | undefined {
    if (this.pageVO === undefined) {
      return undefined
    }

    return this.pageVO.skus.find((item: TicketSkuSelectVO) => {
      return item.skuId === skuId
    })
  }

  private getMaxBuyCount(): number {
    if (this.pageVO === undefined) {
      return 1
    }

    const sku: TicketSkuSelectVO | undefined = this.findSku(this.selectedSkuId)

    if (sku === undefined) {
      return 1
    }

    // V1.2: 未返回精确库存不等于售罄。未知库存时仅受场次限购约束，最终由第三方计价/建单确认。
    if (sku.stockAvailable === undefined) {
      return this.pageVO.limitPerOrder
    }

    if (sku.stockAvailable < this.pageVO.limitPerOrder) {
      return sku.stockAvailable
    }

    return this.pageVO.limitPerOrder
  }

  private canBuySku(sku: TicketSkuSelectVO): boolean {
    if (sku.skuStatus !== SkuStatus.ON_SALE && sku.skuStatus !== SkuStatus.PRESALE) {
      return false
    }

    // undefined 表示第三方未知精确库存，不得按 0 或售罄处理。
    return sku.stockAvailable === undefined || sku.stockAvailable > 0
  }
}
