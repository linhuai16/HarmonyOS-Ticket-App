import { UserStatus } from "../enums/UserStatus"

/**
 * 用户实体
 *
 * 注解：
 * 表示 APP 登录用户。
 * 一期仅支持手机号验证码登录；用户资料页支持维护头像、昵称和手机号。
 */
export interface User {
  /** 用户ID */
  userId: string

  /** 手机号，登录账号和用户资料业务事实 */
  phone: string

  /** 用户昵称，用户资料业务事实 */
  nickname: string

  /** 用户头像，用户资料业务事实 */
  avatarUrl: string

  /** 用户状态，用于登录时判断账号是否可用 */
  userStatus: UserStatus
}
