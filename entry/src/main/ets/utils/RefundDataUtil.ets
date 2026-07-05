import { Order } from '../model/entity/Order'
import { RefundRecord } from '../model/entity/RefundRecord'
import { RefundRule, RefundStage } from '../model/entity/RefundRule'
import { refundRuleMock } from '../mock/order/RefundRuleMock'
import { refundRecordMockList } from '../mock/order/RefundRecordMock'
import { RefundType } from '../model/enums/RefundType'
import { DateTimeUtil } from './DateTimeUtil'
import { IdGenerator } from './IdGenerator'

export interface RefundAmountResult {
  feeAmount: number
  refundAmount: number
}

/**
 * 退款数据工具。
 *
 * 说明：
 * 退款规则查找、手续费计算、退款记录创建/更新会被主动退款和系统退款共同使用，
 * 放在 utils 中，避免 RefundRepository 与 TicketRepository 重复维护退款记录逻辑。
 */
export class RefundDataUtil {
  static findRefundRule(projectId: string): RefundRule | undefined {
    return refundRuleMock.find((item: RefundRule) => item.projectId === projectId)
  }

  static findRefundRecord(refundId: string): RefundRecord | undefined {
    return refundRecordMockList.find((item: RefundRecord) => item.refundId === refundId)
  }

  static findRefundRecordByOrderId(orderId: string): RefundRecord | undefined {
    return refundRecordMockList.find((item: RefundRecord) => item.orderId === orderId)
  }

  static getRefundRecords(orderId: string): RefundRecord[] {
    return refundRecordMockList.filter((item: RefundRecord) => item.orderId === orderId)
  }

  static calculateFeeRate(rule: RefundRule, startTime: string): number | undefined {
    if (rule.refundType === RefundType.NO_REFUND) {
      return undefined
    }

    if (rule.stages === undefined || rule.stages.length === 0) {
      return 0
    }

    const beforeStartHours: number = RefundDataUtil.getBeforeStartHours(startTime)
    const sortedStages: RefundStage[] = rule.stages
      .slice()
      .sort((a: RefundStage, b: RefundStage) => b.beforeStartHours - a.beforeStartHours)

    for (let i = 0; i < sortedStages.length; i++) {
      const stage: RefundStage = sortedStages[i]
      if (beforeStartHours >= stage.beforeStartHours) {
        return stage.feeRate
      }
    }

    return undefined
  }

  static calculateRefundAmount(payAmount: number, feeRate: number): RefundAmountResult {
    const feeAmount: number = RefundDataUtil.formatAmount(payAmount * feeRate)
    const refundAmount: number = RefundDataUtil.formatAmount(payAmount - feeAmount)

    return {
      feeAmount: feeAmount,
      refundAmount: refundAmount
    }
  }

  static createRefundingRecord(orderId: string, refundAmount: number, feeAmount: number): RefundRecord {
    const refundRecord: RefundRecord = {
      refundId: IdGenerator.createRefundId(),
      orderId: orderId,
      refundAmount: refundAmount,
      feeAmount: feeAmount,
      status: 'REFUNDING'
    }

    refundRecordMockList.push(refundRecord)
    return refundRecord
  }

  static upsertRefundSuccessRecord(order: Order, refundTime: string, refundAmount?: number, feeAmount: number = 0): RefundRecord {
    const realRefundAmount: number = refundAmount ?? order.payAmount
    const existRecord: RefundRecord | undefined = RefundDataUtil.findRefundRecordByOrderId(order.orderId)

    if (existRecord !== undefined) {
      existRecord.refundAmount = realRefundAmount
      existRecord.feeAmount = feeAmount
      existRecord.refundTime = refundTime
      existRecord.status = 'REFUND_SUCCESS'
      return existRecord
    }

    const refundRecord: RefundRecord = {
      refundId: IdGenerator.createRefundId(),
      orderId: order.orderId,
      refundAmount: realRefundAmount,
      feeAmount: feeAmount,
      status: 'REFUND_SUCCESS',
      refundTime: refundTime
    }

    refundRecordMockList.push(refundRecord)
    return refundRecord
  }

  static formatAmount(value: number): number {
    return Math.round(value * 100) / 100
  }

  private static getBeforeStartHours(startTime: string): number {
    const nowTime: number = new Date().getTime()
    const start: number = DateTimeUtil.toTimeMillis(startTime)

    return Math.floor((start - nowTime) / 1000 / 60 / 60)
  }
}
