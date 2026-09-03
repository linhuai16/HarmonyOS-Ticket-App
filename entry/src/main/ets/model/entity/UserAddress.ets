/**
 * 用户收货地址
 *
 * 注解：
 * 用户地址管理页维护的真实地址信息。
 * 用于提交快递票 / 实体票订单时选择收货地址。
 *
 * 注意：
 * 下单后订单详情展示的是 OrderAddress 快照，
 * 不应直接读取当前 UserAddress，避免用户后续修改地址影响历史订单。
 */
export interface UserAddress {
  /** 地址ID */
  addressId: string

  /** 所属用户ID */
  userId: string

  /** 收货人姓名 */
  receiverName: string

  /** 收货人手机号：实体层保存完整手机号，VO 层负责脱敏展示 */
  receiverPhone: string

  /** 国家编码，当前中国大陆为 CN */
  countryCode: string

  /** 省级 6 位行政区编码 */
  provinceCode: string

  /** 市级 6 位行政区编码 */
  cityCode: string

  /** 区县级 6 位行政区编码 */
  areaCode: string

  /** 省 */
  province: string

  /** 市 */
  city: string

  /** 区 / 县 */
  district: string

  /** 详细地址 */
  detailAddress: string

  /** 是否默认地址 */
  isDefault: boolean
}
