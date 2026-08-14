import { MoneyUtil, MoneyVO } from '../model/vo/ticketsource/MoneyVO'
import { RefundQuoteVO } from '../model/vo/ticketsource/RefundQuoteVO'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'

interface BackendMoney {
  amountMinor?: number | string | null
  currency?: string | null
}

interface BackendRefundQuote {
  refundScope: string
  refundable: boolean
  orderAmount?: BackendMoney | null
  refundableAmount?: BackendMoney | null
  serviceFee?: BackendMoney | null
  refundableDeliveryFee?: BackendMoney | null
  nonRefundableDeliveryFee?: BackendMoney | null
  promotionRollbackAmount?: BackendMoney | null
  unavailableReason?: string | null
  quoteExpireAt?: string | null
}

/**
 * 第三方整单退款只读计价数据层。
 * 真正“申请退款”仍走 RefundRepository 的麦麦审核流程，客户端不能直接提交 provider refund quote。
 */
export class TicketSourceRefundRepository {
  async getFullOrderRefundQuote(orderId: string, userId: string): Promise<RefundQuoteVO> {
    const raw: BackendRefundQuote = await ApiClient.get<BackendRefundQuote>(
      '/api/ticket-source/orders/v12/' + encodeURIComponent(orderId) + '/refund-quote',
      [new ApiQueryParam('userId', userId)]
    )
    if (raw.refundScope !== 'FULL_ORDER') {
      throw new Error('当前客户端只支持整单退款')
    }
    return {
      refundScope: 'FULL_ORDER',
      refundable: raw.refundable === true,
      orderAmount: this.money(raw.orderAmount),
      refundableAmount: this.money(raw.refundableAmount),
      serviceFee: this.money(raw.serviceFee),
      refundableDeliveryFee: this.money(raw.refundableDeliveryFee),
      nonRefundableDeliveryFee: this.money(raw.nonRefundableDeliveryFee),
      promotionRollbackAmount: this.money(raw.promotionRollbackAmount),
      unavailableReason: raw.unavailableReason ?? '',
      quoteExpireAt: raw.quoteExpireAt ?? ''
    }
  }

  private money(raw: BackendMoney | undefined | null): MoneyVO {
    if (raw === undefined || raw === null) {
      return MoneyUtil.zero()
    }
    return MoneyUtil.fromMinor(raw.amountMinor, raw.currency ?? 'CNY')
  }
}
