/**
 * 订单收货地址快照
 *
 * 注解：
 * 快递票 / 实体票下单时，从 UserAddress 复制生成。
 * 订单详情展示该快照，而不是读取用户当前地址，
 * 避免用户后续修改 / 删除地址影响历史订单。
 */
export interface OrderAddress {
  /** 订单地址快照ID */
  orderAddressId: string

  /** 所属订单ID */
  orderId: string

  /** 收货人姓名快照 */
  receiverName: string

  /** 收货人手机号快照：实体层保存完整值，VO 层负责脱敏展示 */
  receiverPhone: string

  /** 省快照 */
  province: string

  /** 市快照 */
  city: string

  /** 区 / 县快照 */
  district: string

  /** 详细地址快照 */
  detailAddress: string
}
