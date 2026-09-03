import { CertificateType } from "../enums/CertificateType"

/**
 * 订单观演人快照
 *
 * 注解：
 * 表示某个订单在下单时绑定的观演人信息。
 * 订单详情页展示观演人信息时，应读取该快照，而不是直接读取用户当前的 Audience 表。
 *
 * 字段优化说明：
 * - 不保存原观演人 audienceId，历史订单只依赖下单时快照。
 * - 用户后续编辑/删除 Audience，不影响历史订单展示。
 */
export interface OrderAudience {
  /** 订单观演人记录ID */
  orderAudienceId: string

  /** 所属订单ID */
  orderId: string

  /** 观演人姓名快照 */
  realName: string

  /** 证件类型快照 */
  certificateType: CertificateType

  /** 证件号快照，实体层保存完整值，页面展示时由 VO 做脱敏 */
  certificateNo: string

  /** 证件号哈希，用于同场次实名查重，不一定返回给页面 VO */
  certificateNoHash: string

  /** 手机号快照 */
  phone: string
}
