export interface MinePageVO {
  user: MineUserVO
}

export interface MineUserVO {
  userId: string
  /** 登录手机号 */
  phone?: string
  /** 用户昵称 */
  nickname?: string
  /** 用户头像。当前一期使用后端返回的头像 URL 或资源标识，不接真实相册上传。 */
  avatarUrl?: string
}
