import { common, UIAbility } from '@kit.AbilityKit'
import { pushService } from '@kit.PushKit'
import { notificationManager } from '@kit.NotificationKit'
import { workScheduler } from '@kit.BackgroundTasksKit'
import { preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { formInfo, formProvider } from '@kit.FormKit'
import { PushRepository } from './PushRepository'
import { PerformanceReminderRuntime } from './PerformanceReminderRuntime'
import { ServiceCardBinding, ServiceCardStore } from '../servicecard/ServiceCardStore'
import { ServiceCardRuntime } from '../servicecard/ServiceCardRuntime'

const STORE_NAME: string = 'push_runtime'
const KEY_DEVICE_ID: string = 'device_id'
const KEY_PUSH_TOKEN: string = 'push_token'
const REMINDER_WORK_ID: number = 6001

export class PushRuntime {
  private static ability: UIAbility | undefined
  private static context: common.UIAbilityContext | undefined
  private static tokenCallback: ((token: string) => void) | undefined
  private static fallbackDeviceId: string = ''
  private static preferenceStore: preferences.Preferences | undefined
  private static lightweightRegistered: boolean = false
  private static deferredSyncStarted: boolean = false
  private static refreshPromise: Promise<void> | undefined

  static restoreLoginSession(context: common.Context): string {
    return PushRuntime.restoreSession(context)
  }

  static registerLightweight(ability: UIAbility): void {
    PushRuntime.ability = ability
    PushRuntime.context = ability.context
    PerformanceReminderRuntime.register(ability.context)
    if (PushRuntime.lightweightRegistered) {
      return
    }
    PushRuntime.tokenCallback = (token: string): void => {
      PushRuntime.onToken(token)
    }
    try {
      pushService.on('tokenUpdate', ability, PushRuntime.tokenCallback)
    } catch (error) {
      console.error('[Push] tokenUpdate registration failed=' + String(error))
    }
    PushRuntime.lightweightRegistered = true
  }

  static syncDeferred(restoredUserId?: string): void {
    if (PushRuntime.deferredSyncStarted) {
      return
    }
    PushRuntime.deferredSyncStarted = true
    const context: common.UIAbilityContext | undefined = PushRuntime.context
    const activeUserId: string = restoredUserId === undefined && context !== undefined ?
      PushRuntime.restoreSession(context) : (restoredUserId ?? '')
    PushRuntime.refresh(activeUserId)
    if (activeUserId.length > 0) {
      PerformanceReminderRuntime.requestReconcile(activeUserId)
      PushRuntime.scheduleReminderWork()
    }
  }

  static unregister(): void {
    try {
      if (PushRuntime.tokenCallback !== undefined) {
        pushService.off('tokenUpdate', PushRuntime.tokenCallback)
      }
    } catch (error) {
    }
    PushRuntime.ability = undefined
    PushRuntime.context = undefined
    PushRuntime.tokenCallback = undefined
    PushRuntime.preferenceStore = undefined
    PushRuntime.lightweightRegistered = false
    PushRuntime.deferredSyncStarted = false
    PushRuntime.refreshPromise = undefined
  }

  static login(userId: string): void {
    PushRuntime.requestPermission()
    PushRuntime.refresh(userId)
    PerformanceReminderRuntime.requestReconcile(userId)
    PushRuntime.scheduleReminderWork()
  }

  static logout(userId: string): void {
    PushRuntime.logoutAsync(userId)
    PerformanceReminderRuntime.cancelForUser(userId).catch((): void => {
    })
    PushRuntime.cancelReminderWork()
  }

  static foreground(userId: string): void {
    PushRuntime.refresh(userId)
    PerformanceReminderRuntime.requestReconcile(userId)
  }

  static businessStateChanged(): void {
    ServiceCardRuntime.requestRefresh()
    const userId: string = AppStorage.get<string>('login_user_id') ?? ''
    if ((AppStorage.get<boolean>('login_status') ?? false) && userId.length > 0) {
      PerformanceReminderRuntime.requestReconcile(userId)
    }
  }

  private static refresh(userId: string = ''): Promise<void> {
    if (PushRuntime.refreshPromise !== undefined) {
      return PushRuntime.refreshPromise
    }
    const request: Promise<void> = PushRuntime.refreshToken(userId)
    PushRuntime.refreshPromise = request
    request.finally((): void => {
      if (PushRuntime.refreshPromise === request) {
        PushRuntime.refreshPromise = undefined
      }
    })
    return request
  }

  private static async refreshToken(userId: string): Promise<void> {
    try {
      const token: string = await pushService.getToken()
      PushRuntime.onToken(token, userId)
    } catch (error) {
      console.error('[Push] getToken failed=' + String(error))
    }
  }

  private static onToken(token: string, userId: string = ''): void {
    const context: common.UIAbilityContext | undefined = PushRuntime.context
    const value: string = token.trim()
    if (context === undefined || value.length === 0) {
      return
    }
    PushRuntime.saveToken(context, value)
    const targetUserId: string = userId.length > 0 ? userId : (AppStorage.get<string>('login_user_id') ?? '')
    if (targetUserId.length > 0 && (AppStorage.get<boolean>('login_status') ?? false)) {
      PushRuntime.bindDevice(context, targetUserId, value).catch((error: Error): void => {
        console.error('[Push] bind failed=' + error.message)
      })
    }
  }

  private static async bindDevice(context: common.Context, userId: string, pushToken: string): Promise<void> {
    try {
      const runningForms: formInfo.RunningFormInfo[] = await formProvider.getPublishedRunningFormInfos()
      const city: string = ServiceCardStore.getCity(context)
      runningForms.forEach((item: formInfo.RunningFormInfo): void => {
        if (item.abilityName === 'ServiceCardFormAbility' || item.abilityName.endsWith('.ServiceCardFormAbility') ||
          item.formName === 'TicketServiceCard2x2' || item.formName === 'TicketServiceCard2x4') {
          ServiceCardStore.addForm(context, new ServiceCardBinding(item.formId, item.moduleName,
            item.abilityName.endsWith('.ServiceCardFormAbility') ? 'ServiceCardFormAbility' : item.abilityName,
            item.formName, city))
        }
      })
    } catch (error) {
    }
    await PushRepository.bind(userId, PushRuntime.deviceId(context), pushToken,
      ServiceCardStore.getFormBindings(context))
  }

  private static async logoutAsync(userId: string): Promise<void> {
    const context: common.UIAbilityContext | undefined = PushRuntime.context
    if (context === undefined || userId.length === 0) {
      return
    }
    const token: string = PushRuntime.readToken(context)
    if (token.length > 0) {
      try {
        await PushRepository.unbind(userId, PushRuntime.deviceId(context), token)
      } catch (error) {
      }
    }
    try {
      await pushService.deleteToken()
    } catch (error) {
    }
    PushRuntime.saveToken(context, '')
  }

  private static requestPermission(): void {
    const context: common.UIAbilityContext | undefined = PushRuntime.context
    if (context === undefined) {
      return
    }
    notificationManager.requestEnableNotification(context).catch((error: Error): void => {
      console.info('[Push] notification permission unavailable=' + error.message)
    })
  }

  private static restoreSession(context: common.Context): string {
    const activeUserId: string = AppStorage.get<string>('login_user_id') ?? ''
    const activeToken: string = AppStorage.get<string>('login_token') ?? ''
    if ((AppStorage.get<boolean>('login_status') ?? false) && activeUserId.length > 0 && activeToken.length > 0) {
      return activeUserId
    }
    const userId: string = ServiceCardStore.getUserId(context)
    const token: string = ServiceCardStore.getToken(context)
    if (userId.length === 0 || token.length === 0) {
      return ''
    }
    AppStorage.setOrCreate('login_status', true)
    AppStorage.setOrCreate('login_user_id', userId)
    AppStorage.setOrCreate('login_token', token)
    return userId
  }

  private static scheduleReminderWork(): void {
    try {
      workScheduler.startWork({
        workId: REMINDER_WORK_ID,
        bundleName: 'com.example.gomaimai',
        abilityName: 'ReminderWorkAbility',
        isPersisted: true,
        networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY,
        isRepeat: true,
        repeatCycleTime: 60 * 60 * 1000
      })
    } catch (error) {
      console.error('[PerformanceReminder] work scheduling failed=' + String(error))
    }
  }

  private static cancelReminderWork(): void {
    try {
      workScheduler.stopWork({
        workId: REMINDER_WORK_ID,
        bundleName: 'com.example.gomaimai',
        abilityName: 'ReminderWorkAbility'
      }, true)
    } catch (error) {
    }
  }

  private static deviceId(context: common.Context): string {
    if (PushRuntime.fallbackDeviceId.length === 0) {
      PushRuntime.fallbackDeviceId = util.generateRandomUUID(true)
    }
    const store: preferences.Preferences | undefined = PushRuntime.store(context)
    if (store === undefined) {
      return PushRuntime.fallbackDeviceId
    }
    try {
      let deviceId: string = String(store.getSync(KEY_DEVICE_ID, ''))
      if (deviceId.length === 0) {
        deviceId = PushRuntime.fallbackDeviceId
        store.putSync(KEY_DEVICE_ID, deviceId)
        store.flushSync()
      }
      PushRuntime.fallbackDeviceId = deviceId
      return deviceId
    } catch (error) {
      return PushRuntime.fallbackDeviceId
    }
  }

  private static readToken(context: common.Context): string {
    const store: preferences.Preferences | undefined = PushRuntime.store(context)
    if (store === undefined) {
      return ''
    }
    try {
      return String(store.getSync(KEY_PUSH_TOKEN, ''))
    } catch (error) {
      return ''
    }
  }

  private static saveToken(context: common.Context, value: string): void {
    const store: preferences.Preferences | undefined = PushRuntime.store(context)
    if (store === undefined) {
      return
    }
    try {
      store.putSync(KEY_PUSH_TOKEN, value)
      store.flushSync()
    } catch (error) {
    }
  }

  private static store(context: common.Context): preferences.Preferences | undefined {
    if (PushRuntime.preferenceStore !== undefined) {
      return PushRuntime.preferenceStore
    }
    try {
      PushRuntime.preferenceStore = preferences.getPreferencesSync(context, { name: STORE_NAME })
      return PushRuntime.preferenceStore
    } catch (error) {
      return undefined
    }
  }
}
