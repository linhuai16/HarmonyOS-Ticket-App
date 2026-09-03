/**
 * 电子票状态
 *
 * 来源：
 * 票夹详情页：生成中、未使用、已检票、已失效、异常
 */
export enum TicketStatus {
  /** 生成中：订单已支付，但二维码暂未生成 */
  GENERATING = 'GENERATING',

  /** 未使用：二维码已生成，尚未核验 */
  UNUSED = 'UNUSED',

  /** 已检票：二维码已核验入场 */
  CHECKED = 'CHECKED',

  /** 已失效：超过演出时间 / 票不可用 / 已退款 */
  EXPIRED = 'EXPIRED',

  /** 异常：临时异常 / 二维码生成失败 / 第三方出票接口超时，系统自动重试 */
  ERROR = 'ERROR'
}