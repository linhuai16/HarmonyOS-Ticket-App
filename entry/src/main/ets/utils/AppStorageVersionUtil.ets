const KEY_ORDER_CHANGED_VERSION: string = 'order_changed_version'
const KEY_TICKET_CHANGED_VERSION: string = 'ticket_changed_version'
const KEY_AUDIENCE_CHANGED_VERSION: string = 'audience_changed_version'
const KEY_ADDRESS_LIST_VERSION: string = 'address_list_version'
const KEY_LOGIN_VERSION: string = 'login_version'

export class AppStorageVersionUtil {
  static bumpOrderChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_ORDER_CHANGED_VERSION)
  }

  static bumpTicketChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_TICKET_CHANGED_VERSION)
  }

  static bumpAudienceChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_AUDIENCE_CHANGED_VERSION)
  }

  static bumpAddressListVersion(): void {
    AppStorageVersionUtil.bump(KEY_ADDRESS_LIST_VERSION)
  }

  static bumpLoginVersion(): void {
    AppStorageVersionUtil.bump(KEY_LOGIN_VERSION)
  }

  static bump(key: string): void {
    const currentVersion: number | undefined = AppStorage.get<number>(key)
    AppStorage.setOrCreate(key, (currentVersion ?? 0) + 1)
  }
}
