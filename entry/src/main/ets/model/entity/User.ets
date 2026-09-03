import { AccountStatus } from "../enums/AccountStatus"

/**
 * 用户实体
 *
 * 注解：
 * 表示 APP 登录账号本身。
 * 一期使用手机号验证码登录；用户资料页维护昵称、头像和手机号。
 * 不存 token、登录态、验证码等运行时数据，这些交给 UserSessionUtil 或登录流程处理。
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

  /** 账号状态：用于登录时判断账号是否可用 */
  accountStatus: AccountStatus
}
