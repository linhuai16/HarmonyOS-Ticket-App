import { MoneyVO } from './MoneyVO'

/** V1.2 整单退款试算前端展示模型；不允许选择单张票退款。 */
export interface RefundQuoteVO {
  refundScope: 'FULL_ORDER'
  refundable: boolean
  orderAmount: MoneyVO
  refundableAmount: MoneyVO
  serviceFee: MoneyVO
  refundableDeliveryFee: MoneyVO
  nonRefundableDeliveryFee: MoneyVO
  promotionRollbackAmount: MoneyVO
  unavailableReason: string
  quoteExpireAt: string
}
