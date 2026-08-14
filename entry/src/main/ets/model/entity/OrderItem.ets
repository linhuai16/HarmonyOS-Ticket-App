/**
 * 订单项
 * 注解：
 * 表示订单中购买的具体票品。
 * V1.2 新订单业务上只允许一条订单项，即一个订单只选择一个票档；数据库一对多结构仅用于通用兼容。
 * 票档名称、单价和小计金额是下单时快照，不直接读取当前 TicketSku。
 */
export interface OrderItem {
  /** 订单项ID */
  orderItemId: string

  /** 所属订单ID */
  orderId: string

  /** 票档ID */
  skuId: string

  /** 下单时票档名称快照 */
  skuName: string

  /** 下单时单价快照 */
  unitPrice: number

  /** 数量 */
  quantity: number

  /** 下单时票款小计金额快照 */
  subtotalAmount: number
}
