import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ServiceCardStore } from './ServiceCardStore'

const LOG_DOMAIN: number = 0x0000
const LOG_TAG: string = 'ServiceCard'

export class ServiceCardRuntime {
  private static context: common.Context | undefined = undefined
  private static refreshHandler: (() => Promise<void>) | undefined = undefined
  private static refreshing: boolean = false
  private static pending: boolean = false

  static register(context: common.Context, refreshHandler: () => Promise<void>): void {
    ServiceCardRuntime.context = context
    ServiceCardRuntime.refreshHandler = refreshHandler
    const userId: string = AppStorage.get<string>('login_user_id') ?? ''
    const token: string = AppStorage.get<string>('login_token') ?? ''
    const city: string = AppStorage.get<string>('current_city') ?? '北京'
    if (userId.length > 0 && token.length > 0) {
      ServiceCardStore.saveLogin(context, userId, token)
    }
    ServiceCardStore.saveCity(context, city)
    if (ServiceCardRuntime.pending) {
      ServiceCardRuntime.requestRefresh()
    }
  }

  static unregister(): void {
    ServiceCardRuntime.context = undefined
    ServiceCardRuntime.refreshHandler = undefined
    ServiceCardRuntime.refreshing = false
    ServiceCardRuntime.pending = false
  }

  static saveLogin(userId: string, token: string): void {
    if (ServiceCardRuntime.context !== undefined) {
      ServiceCardStore.saveLogin(ServiceCardRuntime.context, userId, token)
    }
    ServiceCardRuntime.requestRefresh()
  }

  static clearLogin(): void {
    if (ServiceCardRuntime.context !== undefined) {
      ServiceCardStore.clearLogin(ServiceCardRuntime.context)
    }
    ServiceCardRuntime.requestRefresh()
  }

  static saveCity(cityName: string): void {
    if (ServiceCardRuntime.context !== undefined) {
      ServiceCardStore.saveCity(ServiceCardRuntime.context, cityName)
    }
    ServiceCardRuntime.requestRefresh()
  }

  static requestRefresh(): void {
    if (ServiceCardRuntime.refreshHandler === undefined) {
      ServiceCardRuntime.pending = true
      return
    }
    if (ServiceCardRuntime.refreshing) {
      ServiceCardRuntime.pending = true
      return
    }
    ServiceCardRuntime.runRefresh()
  }

  private static async runRefresh(): Promise<void> {
    const handler: (() => Promise<void>) | undefined = ServiceCardRuntime.refreshHandler
    if (handler === undefined || ServiceCardRuntime.refreshing) {
      ServiceCardRuntime.pending = true
      return
    }
    ServiceCardRuntime.refreshing = true
    ServiceCardRuntime.pending = false
    try {
      await handler()
    } catch (error) {
      const message: string = error instanceof Error ? error.message : 'unknown'
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Refresh failed: %{public}s', message)
    } finally {
      ServiceCardRuntime.refreshing = false
      if (ServiceCardRuntime.pending && ServiceCardRuntime.refreshHandler !== undefined) {
        ServiceCardRuntime.pending = false
        ServiceCardRuntime.runRefresh()
      }
    }
  }
}
