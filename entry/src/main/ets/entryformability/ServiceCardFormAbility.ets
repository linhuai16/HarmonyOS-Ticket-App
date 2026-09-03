import { Want } from '@kit.AbilityKit'
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ServiceCardData } from '../servicecard/ServiceCardData'
import { ServiceCardUpdater } from '../servicecard/ServiceCardUpdater'
import { ServiceCardBinding, ServiceCardStore } from '../servicecard/ServiceCardStore'

const LOG_DOMAIN: number = 0x0000
const LOG_TAG: string = 'ServiceCard'

export default class ServiceCardFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = this.getFormId(want)
    ServiceCardStore.addForm(this.context, new ServiceCardBinding(formId, want.moduleName ?? 'entry',
      want.abilityName ?? 'ServiceCardFormAbility', this.getFormName(want), ServiceCardStore.getCity(this.context)))
    ServiceCardUpdater.refreshForm(this.context, formId).catch((error: Error): void => {
      this.logRefreshFailure('onAdd', error)
    })
    return formBindingData.createFormBindingData(new ServiceCardData())
  }

  onUpdateForm(formId: string): void {
    ServiceCardStore.addFormId(this.context, formId)
    ServiceCardUpdater.refreshForm(this.context, formId).catch((error: Error): void => {
      this.logRefreshFailure('onUpdate', error)
    })
  }

  onFormEvent(formId: string, _message: string): void {
    ServiceCardStore.addFormId(this.context, formId)
    ServiceCardUpdater.refreshForm(this.context, formId).catch((error: Error): void => {
      this.logRefreshFailure('onEvent', error)
    })
  }

  onRemoveForm(formId: string): void {
    ServiceCardStore.removeFormId(this.context, formId)
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY
  }

  private getFormId(want: Want): string {
    const value: Object | undefined = want.parameters?.[formInfo.FormParam.IDENTITY_KEY]
    return value === undefined ? '' : String(value)
  }

  private getFormName(want: Want): string {
    const value: Object | undefined = want.parameters?.[formInfo.FormParam.NAME_KEY]
    return value === undefined ? '' : String(value)
  }

  private logRefreshFailure(source: string, error: Error): void {
    hilog.error(LOG_DOMAIN, LOG_TAG, 'Form refresh failed source=%{public}s message=%{public}s', source, error.message)
  }
}
