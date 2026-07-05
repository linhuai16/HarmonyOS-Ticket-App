import { CertificateType } from "../enums/CertificateType"

/**
 * 观演人
 *
 * 注解：
 * 用于实名制购票和入场核验。
 */
export interface Audience {
  /** 观演人ID */
  audienceId: string

  /** 所属用户ID */
  userId: string

  /** 姓名 */
  realName: string

  /** 证件类型 */
  certificateType: CertificateType

  /** 证件号，实体层保存完整值，页面展示时由 VO 做脱敏 */
  certificateNo: string

  /** 手机号，实体层保存完整值，页面展示时由 VO 做脱敏 */
  phone: string

  /** 是否默认观演人 */
  isDefault: boolean
}
