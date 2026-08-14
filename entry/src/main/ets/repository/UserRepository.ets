import { User } from '../model/entity/User'
import { AccountStatus } from '../model/enums/AccountStatus'

import {
  MinePageVO,
  MineUserVO
} from '../model/vo/user/MinePageVO'

import { UserDataUtil } from '../utils/UserDataUtil'
import { UserSessionUtil } from '../utils/UserSessionUtil'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'

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

interface BackendMineUserVO {
  userId: number | string
  phone?: string
  nickname?: string
  avatarUrl?: string
  accountStatus?: string
}

interface BackendMinePageVO {
  user?: BackendMineUserVO
  userId?: number | string
  phone?: string
  nickname?: string
  avatarUrl?: string
  accountStatus?: string
}

interface BackendLoginResponse {
  token: string
  user: BackendMineUserVO
}

interface BackendUpdateUserProfileResponse {
  success: boolean
  message?: string
  user?: BackendMineUserVO
}

interface SmsCodeRequestBody {
  phone: string
}

interface LoginRequestBody {
  phone: string
  smsCode: string
}

interface UpdateUserProfileRequestBody {
  nickname: string
  phone: string
  avatarUrl: string
}

/**
 * 用户 Repository。
 *
 * 该版本已从 Mock 切换到 SpringBoot：
 * POST /api/auth/sms-code
 * POST /api/auth/login
 * GET  /api/users/me
 * PUT  /api/users/{userId}/profile
 */
export class UserRepository {
  async sendSmsCode(phone: string): Promise<SendSmsCodeResponse> {
    const normalizedPhone: string = UserDataUtil.normalizePhone(phone)
    if (!UserDataUtil.isValidPhone(normalizedPhone)) {
      return { success: false }
    }

    const body: SmsCodeRequestBody = {
      phone: normalizedPhone
    }
    return await ApiClient.post<SendSmsCodeResponse>('/api/auth/sms-code', body)
  }

  async login(phone: string, smsCode: string): Promise<LoginResponse | undefined> {
    const normalizedPhone: string = UserDataUtil.normalizePhone(phone)
    if (!UserDataUtil.isValidPhone(normalizedPhone) || smsCode.length === 0) {
      return undefined
    }

    const body: LoginRequestBody = {
      phone: normalizedPhone,
      smsCode: smsCode
    }
    const response: BackendLoginResponse = await ApiClient.post<BackendLoginResponse>('/api/auth/login', body)

    const userVO: MineUserVO = this.mapMineUser(response.user)
    const user: User = this.mapUserEntity(response.user)
    UserSessionUtil.saveLoginState(user, response.token)

    return {
      token: response.token,
      user: userVO
    }
  }

  logout(): void {
    UserSessionUtil.clearLoginState()
  }

  async getMinePage(userId: string = ''): Promise<MinePageVO | undefined> {
    const targetUserId: string = this.getEffectiveUserId(userId)
    if (targetUserId.length === 0) {
      return undefined
    }

    const response: BackendMinePageVO = await ApiClient.get<BackendMinePageVO>('/api/users/me', [
      new ApiQueryParam('userId', targetUserId)
    ])

    const rawUser: BackendMineUserVO | undefined = response.user ?? this.mapMinePageAsUser(response)
    if (rawUser === undefined) {
      return undefined
    }

    return {
      user: this.mapMineUser(rawUser)
    }
  }

  getCurrentUser(): User | undefined {
    const currentUserId: string = UserSessionUtil.getCurrentUserId()
    if (currentUserId.length === 0) {
      return undefined
    }

    const nickname: string | undefined = AppStorage.get<string>('login_nickname')
    const phone: string | undefined = AppStorage.get<string>('login_phone')
    const avatarUrl: string | undefined = AppStorage.get<string>('login_avatar_url')

    return {
      userId: currentUserId,
      phone: phone ?? '',
      nickname: nickname ?? '',
      avatarUrl: avatarUrl ?? '',
      accountStatus: AccountStatus.NORMAL
    }
  }

  async updateUserProfile(userId: string, nickname: string, phone: string, avatarUrl: string): Promise<UpdateUserProfileResponse> {
    const targetUserId: string = this.getEffectiveUserId(userId)
    const normalizedNickname: string = UserDataUtil.normalizeNickname(nickname)
    const normalizedPhone: string = UserDataUtil.normalizePhone(phone)
    const normalizedAvatarUrl: string = UserDataUtil.normalizeAvatarUrl(avatarUrl)

    if (targetUserId.length === 0 || !this.isLogin()) {
      return { success: false, message: '用户未登录' }
    }

    const body: UpdateUserProfileRequestBody = {
      nickname: normalizedNickname,
      phone: normalizedPhone,
      avatarUrl: normalizedAvatarUrl
    }
    const response: BackendUpdateUserProfileResponse =
      await ApiClient.put<BackendUpdateUserProfileResponse>('/api/users/' + encodeURIComponent(targetUserId) + '/profile', body)

    const userVO: MineUserVO | undefined = response.user === undefined ? undefined : this.mapMineUser(response.user)
    if (response.success && response.user !== undefined) {
      UserSessionUtil.saveLoginState(this.mapUserEntity(response.user), UserSessionUtil.getToken())
    }

    return {
      success: response.success,
      message: response.message ?? (response.success ? '保存成功' : '保存失败'),
      user: userVO
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

  private mapMinePageAsUser(raw: BackendMinePageVO): BackendMineUserVO | undefined {
    if (raw.userId === undefined) {
      return undefined
    }

    return {
      userId: raw.userId,
      phone: raw.phone,
      nickname: raw.nickname,
      avatarUrl: raw.avatarUrl,
      accountStatus: raw.accountStatus
    }
  }

  private mapMineUser(raw: BackendMineUserVO): MineUserVO {
    return {
      userId: String(raw.userId),
      phone: raw.phone ?? '',
      nickname: raw.nickname ?? '',
      avatarUrl: raw.avatarUrl ?? ''
    }
  }

  private mapUserEntity(raw: BackendMineUserVO): User {
    return {
      userId: String(raw.userId),
      phone: raw.phone ?? '',
      nickname: raw.nickname ?? '',
      avatarUrl: raw.avatarUrl ?? '',
      accountStatus: raw.accountStatus === AccountStatus.DISABLED ? AccountStatus.DISABLED : AccountStatus.NORMAL
    }
  }
}
