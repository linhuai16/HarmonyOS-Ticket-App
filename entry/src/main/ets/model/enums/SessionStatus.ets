/**
 * 场次状态
 *
 * 来源：
 * 票详情页场次状态和底部按钮规则：
 * 预售中 → 立即预订
 * 售卖中 → 立即购票
 * 已售罄 → 按钮灰置
 * 已结束 → 不可购票
 */
export enum SessionStatus {
  /** 预售中：展示“立即预订” */
  PRESALE = 'PRESALE',

  /** 售卖中：展示“立即购票” */
  ON_SALE = 'ON_SALE',

  /** 已售罄：按钮灰置，不可购买 */
  SOLD_OUT = 'SOLD_OUT',

  /** 已结束：开演前30分钟进入售卖结束，不可购票 */
  ENDED = 'ENDED',

  /** 已下架：后台使用，一期不做后台下架，作为预留 */
  OFFLINE = 'OFFLINE'
}