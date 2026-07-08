import { TicketSku } from '../../model/entity/TicketSku'

export class OrderStockService {
  lockStock(sku: TicketSku, quantity: number): void {
    sku.stockAvailable = (sku.stockAvailable === undefined ? 0 : sku.stockAvailable) - quantity
    sku.stockLocked = (sku.stockLocked === undefined ? 0 : sku.stockLocked) + quantity
  }

  releaseLockedStock(sku: TicketSku, quantity: number): void {
    const currentLocked: number = sku.stockLocked === undefined ? 0 : sku.stockLocked
    const currentAvailable: number = sku.stockAvailable === undefined ? 0 : sku.stockAvailable
    const releaseCount: number = currentLocked >= quantity ? quantity : currentLocked

    sku.stockLocked = currentLocked - releaseCount
    sku.stockAvailable = currentAvailable + releaseCount
  }

  deductLockedStockAfterPay(sku: TicketSku, quantity: number): void {
    const currentLocked: number = sku.stockLocked === undefined ? 0 : sku.stockLocked
    const deductCount: number = currentLocked >= quantity ? quantity : currentLocked

    sku.stockLocked = currentLocked - deductCount
    sku.soldCount = (sku.soldCount === undefined ? 0 : sku.soldCount) + quantity
  }
}
