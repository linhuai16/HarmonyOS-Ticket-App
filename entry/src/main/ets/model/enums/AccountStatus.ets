/**
 * 账号状态。
 *
 * 注解：
 * 用于登录、账号可用性校验。不是页面展示状态，也不是每张表都需要的通用 status。
 */
export enum AccountStatus {
  /** 正常可登录 */
  NORMAL = 'NORMAL',

  /** 账号被禁用，不允许登录 */
  DISABLED = 'DISABLED'
}
