/**
 * 订单状态
 *
 * 来源：
 * 订单列表：全部 / 待支付 / 待使用 / 已完成
 * 订单详情：待支付、待使用、已完成、退款成功、已取消
 */
export enum OrderStatus {
  /** 待支付：订单已创建，用户尚未支付 */
  WAIT_PAY = 'WAIT_PAY',

  /** 待使用：支付成功，订单已提交，可能电子票生成中，也可能已出票 */
  WAIT_USE = 'WAIT_USE',

  /** 已完成：演出结束后订单完成 */
  FINISHED = 'FINISHED',

  /** 退款成功：出票失败或用户/系统退款成功 */
  REFUND_SUCCESS = 'REFUND_SUCCESS',

  /** 退款申请中 / 退款处理中  */
  REFUNDING = 'REFUNDING',

  /** 已取消：待支付订单超时未支付自动取消 */
  CANCELED = 'CANCELED'
}