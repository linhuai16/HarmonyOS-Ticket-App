import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { formBindingData, formInfo, formProvider } from '@kit.FormKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ServiceCardData } from './ServiceCardData'
import { ServiceCardDataService } from './ServiceCardDataService'
import { ServiceCardStore } from './ServiceCardStore'

const LOG_DOMAIN: number = 0x0000
const LOG_TAG: string = 'ServiceCard'
const FORM_ABILITY_NAME: string = 'ServiceCardFormAbility'
const FORM_NAME_2X2: string = 'TicketServiceCard2x2'
const FORM_NAME_2X4: string = 'TicketServiceCard2x4'

export class ServiceCardUpdater {
  static async refreshForm(context: common.Context, formId: string): Promise<void> {
    if (formId.length === 0) {
      return
    }
    const data: ServiceCardData = await new ServiceCardDataService().load(context)
    await ServiceCardUpdater.updateSingle(context, formId, data)
  }

  static async refreshAll(context: common.Context): Promise<void> {
    const formIds: string[] = await ServiceCardUpdater.resolveFormIds(context)
    if (formIds.length === 0) {
      return
    }
    const data: ServiceCardData = await new ServiceCardDataService().load(context)
    for (let index: number = 0; index < formIds.length; index++) {
      await ServiceCardUpdater.updateSingle(context, formIds[index], data)
    }
  }

  private static async resolveFormIds(context: common.Context): Promise<string[]> {
    const storedIds: string[] = ServiceCardStore.getFormIds(context)
    try {
      const runningForms: formInfo.RunningFormInfo[] = await formProvider.getPublishedRunningFormInfos()
      const publishedIds: string[] = []
      for (let index: number = 0; index < runningForms.length; index++) {
        const item: formInfo.RunningFormInfo = runningForms[index]
        if (!ServiceCardUpdater.isServiceCard(item)) {
          continue
        }
        if (!publishedIds.includes(item.formId)) {
          publishedIds.push(item.formId)
        }
      }
      ServiceCardStore.saveFormIds(context, publishedIds)
      return publishedIds
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Resolve running forms failed code=%{public}s message=%{public}s',
        ServiceCardUpdater.errorCode(businessError), ServiceCardUpdater.errorMessage(businessError))
      return storedIds
    }
  }

  private static isServiceCard(item: formInfo.RunningFormInfo): boolean {
    return item.abilityName === FORM_ABILITY_NAME || item.abilityName.endsWith('.' + FORM_ABILITY_NAME) ||
      item.formName === FORM_NAME_2X2 || item.formName === FORM_NAME_2X4
  }

  private static async updateSingle(context: common.Context, formId: string, data: ServiceCardData): Promise<void> {
    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(data))
    } catch (error) {
      const businessError: BusinessError = error as BusinessError
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Update form failed code=%{public}s message=%{public}s',
        ServiceCardUpdater.errorCode(businessError), ServiceCardUpdater.errorMessage(businessError))
      if (businessError.code === 16501001) {
        ServiceCardStore.removeFormId(context, formId)
      }
    }
  }

  private static errorCode(error: BusinessError): string {
    return error.code === undefined ? 'unknown' : String(error.code)
  }

  private static errorMessage(error: BusinessError): string {
    return error.message === undefined || error.message.length === 0 ? 'unknown' : error.message
  }
}
