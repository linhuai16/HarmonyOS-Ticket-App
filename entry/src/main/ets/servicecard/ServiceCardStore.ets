import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { ServiceCardData } from './ServiceCardData'

const STORE_NAME: string = 'ticket_service_card'
const KEY_USER_ID: string = 'user_id'
const KEY_TOKEN: string = 'token'
const KEY_CITY: string = 'city'
const KEY_LAST_DATA: string = 'last_data'
const KEY_LAST_DATA_OWNER: string = 'last_data_owner'
const KEY_FORM_IDS: string = 'form_ids'
const KEY_FORM_BINDINGS: string = 'form_bindings'

export class ServiceCardBinding {
  formId: string
  moduleName: string
  abilityName: string
  formName: string
  cityName: string

  constructor(formId: string, moduleName: string, abilityName: string, formName: string, cityName: string) {
    this.formId = formId
    this.moduleName = moduleName
    this.abilityName = abilityName
    this.formName = formName
    this.cityName = cityName
  }
}

export class ServiceCardStore {
  static saveLogin(context: common.Context, userId: string, token: string): void {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      store.putSync(KEY_USER_ID, userId)
      store.putSync(KEY_TOKEN, token)
      store.flushSync()
    } catch (error) {
    }
  }

  static clearLogin(context: common.Context): void {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      store.putSync(KEY_USER_ID, '')
      store.putSync(KEY_TOKEN, '')
      store.deleteSync(KEY_LAST_DATA)
      store.deleteSync(KEY_LAST_DATA_OWNER)
      store.flushSync()
    } catch (error) {
    }
  }

  static getUserId(context: common.Context): string {
    try {
      return String(ServiceCardStore.getStore(context).getSync(KEY_USER_ID, ''))
    } catch (error) {
      return ''
    }
  }

  static getToken(context: common.Context): string {
    try {
      return String(ServiceCardStore.getStore(context).getSync(KEY_TOKEN, ''))
    } catch (error) {
      return ''
    }
  }

  static saveCity(context: common.Context, cityName: string): void {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      store.putSync(KEY_CITY, cityName)
      store.flushSync()
    } catch (error) {
    }
  }

  static getCity(context: common.Context): string {
    try {
      const value: string = String(ServiceCardStore.getStore(context).getSync(KEY_CITY, '北京')).trim()
      return value.length > 0 ? value : '北京'
    } catch (error) {
      return '北京'
    }
  }

  static saveLastData(context: common.Context, owner: string, data: ServiceCardData): void {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      store.putSync(KEY_LAST_DATA_OWNER, owner)
      store.putSync(KEY_LAST_DATA, JSON.stringify(data))
      store.flushSync()
    } catch (error) {
    }
  }

  static getLastData(context: common.Context, owner: string): ServiceCardData | undefined {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      if (String(store.getSync(KEY_LAST_DATA_OWNER, '')) !== owner) {
        return undefined
      }
      const raw: string = String(store.getSync(KEY_LAST_DATA, ''))
      if (raw.length === 0) {
        return undefined
      }
      return JSON.parse(raw) as ServiceCardData
    } catch (error) {
      return undefined
    }
  }

  static addFormId(context: common.Context, formId: string): void {
    if (formId.length === 0) {
      return
    }
    const formIds: string[] = ServiceCardStore.getFormIds(context)
    if (!formIds.includes(formId)) {
      formIds.push(formId)
      ServiceCardStore.saveFormIds(context, formIds)
    }
  }

  static addForm(context: common.Context, binding: ServiceCardBinding): void {
    if (binding.formId.length === 0 || binding.moduleName.length === 0 ||
      binding.abilityName.length === 0 || binding.formName.length === 0) {
      return
    }
    ServiceCardStore.addFormId(context, binding.formId)
    const bindings: ServiceCardBinding[] = ServiceCardStore.getFormBindings(context)
      .filter((item: ServiceCardBinding): boolean => item.formId !== binding.formId)
    bindings.push(binding)
    ServiceCardStore.saveFormBindings(context, bindings)
  }

  static removeFormId(context: common.Context, formId: string): void {
    if (formId.length === 0) {
      return
    }
    const formIds: string[] = ServiceCardStore.getFormIds(context)
    ServiceCardStore.saveFormIds(context, formIds.filter((item: string): boolean => item !== formId))
    const bindings: ServiceCardBinding[] = ServiceCardStore.getFormBindings(context)
      .filter((item: ServiceCardBinding): boolean => item.formId !== formId)
    ServiceCardStore.saveFormBindings(context, bindings)
  }

  static getFormBindings(context: common.Context): ServiceCardBinding[] {
    try {
      const raw: string = String(ServiceCardStore.getStore(context).getSync(KEY_FORM_BINDINGS, ''))
      if (raw.length === 0) {
        return []
      }
      const values: ServiceCardBinding[] = JSON.parse(raw) as ServiceCardBinding[]
      return values.filter((item: ServiceCardBinding): boolean => item.formId.length > 0 &&
        item.moduleName.length > 0 && item.abilityName.length > 0 && item.formName.length > 0)
    } catch (error) {
      return []
    }
  }

  static getFormIds(context: common.Context): string[] {
    try {
      const raw: string = String(ServiceCardStore.getStore(context).getSync(KEY_FORM_IDS, ''))
      if (raw.length === 0) {
        return []
      }
      const values: string[] = JSON.parse(raw) as string[]
      return values.filter((item: string): boolean => item.length > 0)
    } catch (error) {
      return []
    }
  }

  static saveFormIds(context: common.Context, formIds: string[]): void {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      store.putSync(KEY_FORM_IDS, JSON.stringify(formIds))
      store.flushSync()
    } catch (error) {
    }
  }

  private static saveFormBindings(context: common.Context, bindings: ServiceCardBinding[]): void {
    try {
      const store: preferences.Preferences = ServiceCardStore.getStore(context)
      store.putSync(KEY_FORM_BINDINGS, JSON.stringify(bindings))
      store.flushSync()
    } catch (error) {
    }
  }

  private static getStore(context: common.Context): preferences.Preferences {
    try {
      return preferences.getPreferencesSync(context, { name: STORE_NAME })
    } catch (error) {
      throw new Error('Service card preferences unavailable')
    }
  }
}
