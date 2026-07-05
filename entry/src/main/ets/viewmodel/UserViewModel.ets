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

/**
登录页：发送验证码、手机号验证码登录
我的页：加载用户信息、判断登录状态、退出登录
用户信息管理页：修改头像、昵称、手机号
 */
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

  sendSmsCode(phone: string): boolean {
    if (!this.isValidPhone(phone.trim())) {
      this.errorMessage = '手机号格式不正确'
      return false
    }

    this.isSendingCode = true
    this.errorMessage = ''
    this.phone = phone.trim()

    const response: SendSmsCodeResponse =
      this.userRepository.sendSmsCode(this.phone)

    this.isSendingCode = false

    if (!response.success) {
      this.errorMessage = '验证码发送失败'
      return false
    }

    return true
  }

  login(phone: string, smsCode: string): boolean {
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

    const response: LoginResponse | undefined =
      this.userRepository.login(normalizedPhone, smsCode)

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
  }

  loadMinePage(userId: string): void {
    this.isLoadingMine = true
    this.errorMessage = ''

    const pageVO: MinePageVO | undefined =
      this.userRepository.getMinePage(userId)

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
  }

  loadCurrentUser(): void {
    this.isLoginStatus = this.userRepository.isLogin()
    this.token = this.userRepository.getToken()

    const currentUser = this.userRepository.getCurrentUser()

    if (currentUser === undefined) {
      this.user = undefined
      this.minePageVO = undefined
      this.phone = ''
      return
    }

    this.loadMinePage(currentUser.userId)
  }

  updateUserProfile(userId: string, nickname: string, phone: string, avatarUrl: string): boolean {
    this.isSavingProfile = true
    this.errorMessage = ''

    const response: UpdateUserProfileResponse =
      this.userRepository.updateUserProfile(userId, nickname, phone, avatarUrl)

    this.isSavingProfile = false

    if (!response.success || response.user === undefined) {
      this.errorMessage = response.message
      return false
    }

    this.user = response.user
    this.phone = response.user.phone ?? ''
    this.minePageVO = {
      user: response.user
    }
    this.isLoginStatus = true
    return true
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
