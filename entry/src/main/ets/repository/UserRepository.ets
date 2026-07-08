import { User } from '../model/entity/User'
import { userMockList } from '../mock/user/UserMock'
import { AccountStatus } from '../model/enums/AccountStatus'

import {
  MinePageVO,
  MineUserVO
} from '../model/vo/user/MinePageVO'

import { UserDataUtil } from '../utils/UserDataUtil'
import { UserSessionUtil } from '../utils/UserSessionUtil'
import { IdGenerator } from '../utils/IdGenerator'

export interface SendSmsCodeResponse {
  success: boolean
}

export interface LoginResponse {
  token: string
  user: MineUserVO
}

export interface UpdateUserProfileResponse {
  success: boolean
  message: string
  user?: MineUserVO
}

const MOCK_SMS_CODE: string = '123456'

/**
 * 用户 Repository。
 *
 * 职责：登录注册、当前用户查询、我的页 VO、用户资料更新。
 * 登录态读写交给 UserSessionUtil；手机号/昵称校验和用户查找交给 UserDataUtil。
 */
export class UserRepository {
  sendSmsCode(phone: string): SendSmsCodeResponse {
    const result: SendSmsCodeResponse = {
      success: UserDataUtil.isValidPhone(phone)
    }
    return result
  }

  login(phone: string, smsCode: string): LoginResponse | undefined {
    const normalizedPhone: string = UserDataUtil.normalizePhone(phone)

    if (!UserDataUtil.isValidPhone(normalizedPhone)) {
      return undefined
    }

    if (smsCode !== MOCK_SMS_CODE) {
      return undefined
    }

    let user: User | undefined = UserDataUtil.findUserByPhone(normalizedPhone)

    if (user === undefined) {
      user = this.createUser(normalizedPhone)
      userMockList.push(user)
    }

    if (user.accountStatus === AccountStatus.DISABLED) {
      return undefined
    }

    const token: string = IdGenerator.createToken(user.userId)
    UserSessionUtil.saveLoginState(user, token)

    const result: LoginResponse = {
      token: token,
      user: this.buildMineUserVO(user)
    }
    return result
  }

  logout(): void {
    UserSessionUtil.clearLoginState()
  }

  getMinePage(userId: string = ''): MinePageVO | undefined {
    const targetUserId: string = this.getEffectiveUserId(userId)
    const user: User | undefined = UserDataUtil.findUserById(targetUserId)

    if (user === undefined) {
      return undefined
    }

    const result: MinePageVO = {
      user: this.buildMineUserVO(user)
    }
    return result
  }

  getCurrentUser(): User | undefined {
    const currentUserId: string = UserSessionUtil.getCurrentUserId()
    return UserDataUtil.findUserById(currentUserId)
  }

  updateUserProfile(userId: string, nickname: string, phone: string, avatarUrl: string): UpdateUserProfileResponse {
    const targetUserId: string = this.getEffectiveUserId(userId)
    const normalizedNickname: string = UserDataUtil.normalizeNickname(nickname)
    const normalizedPhone: string = UserDataUtil.normalizePhone(phone)
    const normalizedAvatarUrl: string = UserDataUtil.normalizeAvatarUrl(avatarUrl)

    if (targetUserId.length === 0 || !this.isLogin()) {
      return {
        success: false,
        message: '用户未登录'
      }
    }

    if (normalizedNickname.length === 0) {
      return {
        success: false,
        message: '请输入用户昵称'
      }
    }

    if (!UserDataUtil.isValidNickname(normalizedNickname)) {
      return {
        success: false,
        message: '用户昵称不能超过12个字符'
      }
    }

    if (!UserDataUtil.isValidPhone(normalizedPhone)) {
      return {
        success: false,
        message: '手机号格式不正确'
      }
    }

    const user: User | undefined = UserDataUtil.findUserById(targetUserId)
    if (user === undefined) {
      return {
        success: false,
        message: '用户信息不存在'
      }
    }

    if (UserDataUtil.hasDuplicateUserPhone(normalizedPhone, targetUserId)) {
      return {
        success: false,
        message: '该手机号已被其他账号使用'
      }
    }

    user.nickname = normalizedNickname
    user.phone = normalizedPhone
    user.avatarUrl = normalizedAvatarUrl

    if (targetUserId === UserSessionUtil.getCurrentUserId()) {
      const token: string = UserSessionUtil.getToken().length > 0 ?
        UserSessionUtil.getToken() :
        IdGenerator.createToken(user.userId)
      UserSessionUtil.saveLoginState(user, token)
    }

    return {
      success: true,
      message: '保存成功',
      user: this.buildMineUserVO(user)
    }
  }

  isLogin(): boolean {
    return UserSessionUtil.isLogin()
  }

  getCurrentUserId(): string {
    return UserSessionUtil.getCurrentUserId()
  }

  getToken(): string {
    return UserSessionUtil.getToken()
  }

  private getEffectiveUserId(userId: string): string {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    return normalizedUserId.length > 0 ? normalizedUserId : UserSessionUtil.getCurrentUserId()
  }

  private createUser(phone: string): User {
    const user: User = {
      userId: IdGenerator.createUserId(),
      phone: phone,
      nickname: UserDataUtil.buildDefaultNickname(phone),
      avatarUrl: 'default_avatar',
      accountStatus: AccountStatus.NORMAL
    }
    return user
  }

  private buildMineUserVO(user: User): MineUserVO {
    const vo: MineUserVO = {
      userId: user.userId,
      phone: user.phone,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl
    }
    return vo
  }
}
