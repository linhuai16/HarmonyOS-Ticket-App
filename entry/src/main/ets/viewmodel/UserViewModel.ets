import {
  MinePageVO,
  MineUserVO
} from '../model/vo/user/MinePageVO'

import {
  UserRepository,
  SendSmsCodeResponse,
  LoginResponse,
  UpdateUserProfileResponse
} from '../repository/UserRepository'

import { UserDataUtil } from '../utils/UserDataUtil'

/** 登录页 / 我的页 / 用户资料页 VM。 */
export class UserViewModel {
  minePageVO: MinePageVO | undefined = undefined
  user: MineUserVO | undefined = undefined

  phone: string = ''
  smsCode: string = ''
  token: string = ''

  isLoginStatus: boolean = false
  isSendingCode: boolean = false
  isLoggingIn: boolean = false
  isLoadingMine: boolean = false
  isSavingProfile: boolean = false
  errorMessage: string = ''

  private userRepository: UserRepository = new UserRepository()

  async sendSmsCode(phone: string): Promise<boolean> {
    if (!this.isValidPhone(phone.trim())) {
      this.errorMessage = '手机号格式不正确'
      return false
    }

    this.isSendingCode = true
    this.errorMessage = ''
    this.phone = phone.trim()

    try {
      const response: SendSmsCodeResponse = await this.userRepository.sendSmsCode(this.phone)
      this.isSendingCode = false
      if (!response.success) {
        this.errorMessage = '验证码发送失败'
        return false
      }
      return true
    } catch (error) {
      this.isSendingCode = false
      this.errorMessage = error instanceof Error ? error.message : '验证码发送失败'
      return false
    }
  }

  async login(phone: string, smsCode: string): Promise<boolean> {
    const normalizedPhone: string = phone.trim()

    if (!this.isValidPhone(normalizedPhone)) {
      this.errorMessage = '手机号格式不正确'
      return false
    }

    if (smsCode.length === 0) {
      this.errorMessage = '请输入验证码'
      return false
    }

    this.isLoggingIn = true
    this.errorMessage = ''

    try {
      const response: LoginResponse | undefined = await this.userRepository.login(normalizedPhone, smsCode)
      this.isLoggingIn = false

      if (response === undefined) {
        this.errorMessage = '登录失败，请检查手机号或验证码'
        return false
      }

      this.token = response.token
      this.user = response.user
      this.phone = response.user.phone ?? normalizedPhone
      this.isLoginStatus = true
      return true
    } catch (error) {
      this.isLoggingIn = false
      this.errorMessage = error instanceof Error ? error.message : '登录失败，请检查手机号或验证码'
      return false
    }
  }

  async loadMinePage(userId: string): Promise<void> {
    this.isLoadingMine = true
    this.errorMessage = ''

    try {
      const pageVO: MinePageVO | undefined = await this.userRepository.getMinePage(userId)
      if (pageVO === undefined) {
        this.errorMessage = '用户信息不存在'
        this.isLoadingMine = false
        return
      }

      this.minePageVO = pageVO
      this.user = pageVO.user
      this.phone = pageVO.user.phone ?? ''
      this.isLoginStatus = true
      this.isLoadingMine = false
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '用户信息加载失败'
      this.isLoadingMine = false
    }
  }

  async loadCurrentUser(): Promise<void> {
    this.isLoginStatus = this.userRepository.isLogin()
    this.token = this.userRepository.getToken()

    const currentUser = this.userRepository.getCurrentUser()
    if (currentUser === undefined) {
      this.user = undefined
      this.minePageVO = undefined
      this.phone = ''
      return
    }

    await this.loadMinePage(currentUser.userId)
  }

  async updateUserProfile(userId: string, nickname: string, phone: string, avatarUrl: string): Promise<boolean> {
    this.isSavingProfile = true
    this.errorMessage = ''

    try {
      const response: UpdateUserProfileResponse = await this.userRepository.updateUserProfile(userId, nickname, phone, avatarUrl)
      this.isSavingProfile = false

      if (!response.success || response.user === undefined) {
        this.errorMessage = response.message
        return false
      }

      this.user = response.user
      this.phone = response.user.phone ?? ''
      this.minePageVO = { user: response.user }
      this.isLoginStatus = true
      return true
    } catch (error) {
      this.isSavingProfile = false
      this.errorMessage = error instanceof Error ? error.message : '保存失败'
      return false
    }
  }

  logout(): void {
    this.userRepository.logout()
    this.minePageVO = undefined
    this.user = undefined
    this.phone = ''
    this.smsCode = ''
    this.token = ''
    this.isLoginStatus = false
    this.errorMessage = ''
  }

  isLogin(): boolean {
    return this.userRepository.isLogin()
  }

  getCurrentUserId(): string {
    if (this.user === undefined) {
      return this.userRepository.getCurrentUserId()
    }
    return this.user.userId
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private isValidPhone(phone: string): boolean {
    return UserDataUtil.isValidPhone(phone)
  }
}
