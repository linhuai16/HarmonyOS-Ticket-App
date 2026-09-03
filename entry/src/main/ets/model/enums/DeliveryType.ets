/**
 * 配送方式
 *
 * 来源：
 * 提交订单页和订单详情页：电子票 / 实体票
 */
export enum DeliveryType {
  /** 电子票 */
  ETICKET = 'ETICKET',

  /** 实体票 / 快递票 */
  PAPER_TICKET = 'PAPER_TICKET'
}