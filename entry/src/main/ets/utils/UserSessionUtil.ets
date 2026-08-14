import { User } from '../model/entity/User'
import { AppStorageVersionUtil } from './AppStorageVersionUtil'

const KEY_LOGIN_STATUS: string = 'login_status'
const KEY_LOGIN_USER_ID: string = 'login_user_id'
const KEY_LOGIN_NICKNAME: string = 'login_nickname'
const KEY_LOGIN_PHONE: string = 'login_phone'
const KEY_LOGIN_AVATAR_URL: string = 'login_avatar_url'
const KEY_LOGIN_TOKEN: string = 'login_token'

/**
 * 用户登录态工具。
 *
 * 说明：
 * 登录态同时写入内存静态变量和 AppStorage，页面通过 StorageLink 监听 login_version 刷新。
 * 这类逻辑不是 UserRepository 独有的业务查询，提取后可以避免 Repository 内维护一堆 KEY 和读写方法。
 */
export class UserSessionUtil {
  private static currentToken: string = ''
  private static currentUserId: string = ''

  static saveLoginState(user: User, token: string): void {
    UserSessionUtil.currentUserId = user.userId
    UserSessionUtil.currentToken = token

    AppStorage.setOrCreate(KEY_LOGIN_STATUS, true)
    AppStorage.setOrCreate(KEY_LOGIN_USER_ID, user.userId)
    AppStorage.setOrCreate(KEY_LOGIN_NICKNAME, user.nickname)
    AppStorage.setOrCreate(KEY_LOGIN_PHONE, user.phone)
    AppStorage.setOrCreate(KEY_LOGIN_AVATAR_URL, user.avatarUrl)
    AppStorage.setOrCreate(KEY_LOGIN_TOKEN, token)
    AppStorageVersionUtil.bumpLoginVersion()
    AppStorageVersionUtil.bumpUserCenterChangedVersion()
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()
    AppStorageVersionUtil.bumpWantChangedVersion()
    AppStorageVersionUtil.bumpAddressListVersion()
    AppStorageVersionUtil.bumpAudienceChangedVersion()
  }

  static clearLoginState(): void {
    UserSessionUtil.currentUserId = ''
    UserSessionUtil.currentToken = ''

    AppStorage.setOrCreate(KEY_LOGIN_STATUS, false)
    AppStorage.setOrCreate(KEY_LOGIN_USER_ID, '')
    AppStorage.setOrCreate(KEY_LOGIN_NICKNAME, '')
    AppStorage.setOrCreate(KEY_LOGIN_PHONE, '')
    AppStorage.setOrCreate(KEY_LOGIN_AVATAR_URL, '')
    AppStorage.setOrCreate(KEY_LOGIN_TOKEN, '')
    AppStorageVersionUtil.bumpLoginVersion()
    AppStorageVersionUtil.bumpUserCenterChangedVersion()
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()
    AppStorageVersionUtil.bumpWantChangedVersion()
    AppStorageVersionUtil.bumpAddressListVersion()
    AppStorageVersionUtil.bumpAudienceChangedVersion()
  }

  static isLogin(): boolean {
    const storageLoginStatus: boolean | undefined = AppStorage.get<boolean>(KEY_LOGIN_STATUS)
    const storageUserId: string | undefined = AppStorage.get<string>(KEY_LOGIN_USER_ID)
    const storageToken: string | undefined = AppStorage.get<string>(KEY_LOGIN_TOKEN)

    if (storageLoginStatus === true && storageUserId !== undefined && storageUserId.length > 0 &&
      storageToken !== undefined && storageToken.length > 0) {
      UserSessionUtil.currentUserId = storageUserId
      UserSessionUtil.currentToken = storageToken
      return true
    }

    return UserSessionUtil.currentToken.length > 0 && UserSessionUtil.currentUserId.length > 0
  }

  static getCurrentUserId(): string {
    if (UserSessionUtil.currentUserId.length > 0) {
      return UserSessionUtil.currentUserId
    }

    const userId: string | undefined = AppStorage.get<string>(KEY_LOGIN_USER_ID)
    UserSessionUtil.currentUserId = userId ?? ''
    return UserSessionUtil.currentUserId
  }

  static getToken(): string {
    if (UserSessionUtil.currentToken.length > 0) {
      return UserSessionUtil.currentToken
    }

    const token: string | undefined = AppStorage.get<string>(KEY_LOGIN_TOKEN)
    UserSessionUtil.currentToken = token ?? ''
    return UserSessionUtil.currentToken
  }
}
