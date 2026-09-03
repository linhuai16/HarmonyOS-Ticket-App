import { ServiceCardRuntime } from '../servicecard/ServiceCardRuntime'
import { PushRuntime } from '../notification/PushRuntime'

const KEY_ORDER_CHANGED_VERSION: string = 'order_changed_version'
const KEY_TICKET_CHANGED_VERSION: string = 'ticket_changed_version'
const KEY_AUDIENCE_CHANGED_VERSION: string = 'audience_changed_version'
const KEY_ADDRESS_LIST_VERSION: string = 'address_list_version'
const KEY_LOGIN_VERSION: string = 'login_version'
const KEY_TICKET_SELECT_REFRESH_VERSION: string = 'ticket_select_refresh_version'
const KEY_PERFORMANCE_CHANGED_VERSION: string = 'performance_changed_version'
const KEY_WANT_CHANGED_VERSION: string = 'want_changed_version'
const KEY_USER_CENTER_CHANGED_VERSION: string = 'user_center_changed_version'
const KEY_REFUND_CHANGED_VERSION: string = 'refund_changed_version'
const KEY_SHIPMENT_CHANGED_VERSION: string = 'shipment_changed_version'

/**
 * 跨页面数据失效版本。
 * 写操作只负责 bump 对应领域；页面通过 @StorageLink + @Watch 重新拉取服务端数据。
 * 版本只表达“旧数据已失效”，不把业务对象塞进 AppStorage，避免页面之间共享陈旧对象。
 */
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

  static bumpTicketSelectRefreshVersion(): void {
    AppStorageVersionUtil.bump(KEY_TICKET_SELECT_REFRESH_VERSION)
  }

  static bumpPerformanceChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_PERFORMANCE_CHANGED_VERSION)
  }

  static bumpWantChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_WANT_CHANGED_VERSION)
  }

  static bumpUserCenterChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_USER_CENTER_CHANGED_VERSION)
  }

  static bumpRefundChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_REFUND_CHANGED_VERSION)
  }

  static bumpShipmentChangedVersion(): void {
    AppStorageVersionUtil.bump(KEY_SHIPMENT_CHANGED_VERSION)
  }

  /** 下单/取消会占用或释放票档库存，订单与演出/票档页面都应失效。 */
  static bumpOrderInventoryRelatedVersions(): void {
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketSelectRefreshVersion()
    AppStorageVersionUtil.bumpPerformanceChangedVersion()
    AppStorageVersionUtil.bumpUserCenterChangedVersion()
    PushRuntime.businessStateChanged()
  }

  /** 支付/出票变化会同时影响订单、票夹和“我的”。 */
  static bumpOrderTicketRelatedVersions(): void {
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()
    AppStorageVersionUtil.bumpUserCenterChangedVersion()
    PushRuntime.businessStateChanged()
  }

  /** 退款会影响订单、票夹、退款进度、物流及“我的”。 */
  static bumpRefundRelatedVersions(): void {
    AppStorageVersionUtil.bumpOrderChangedVersion()
    AppStorageVersionUtil.bumpTicketChangedVersion()
    AppStorageVersionUtil.bumpRefundChangedVersion()
    AppStorageVersionUtil.bumpShipmentChangedVersion()
    AppStorageVersionUtil.bumpTicketSelectRefreshVersion()
    AppStorageVersionUtil.bumpPerformanceChangedVersion()
    AppStorageVersionUtil.bumpUserCenterChangedVersion()
    PushRuntime.businessStateChanged()
  }

  static bump(key: string): void {
    const currentVersion: number | undefined = AppStorage.get<number>(key)
    AppStorage.setOrCreate(key, (currentVersion ?? 0) + 1)
    if (key === KEY_ORDER_CHANGED_VERSION || key === KEY_TICKET_CHANGED_VERSION || key === KEY_LOGIN_VERSION ||
      key === KEY_PERFORMANCE_CHANGED_VERSION || key === KEY_WANT_CHANGED_VERSION ||
      key === KEY_REFUND_CHANGED_VERSION || key === KEY_SHIPMENT_CHANGED_VERSION) {
      ServiceCardRuntime.requestRefresh()
    }
  }
}
