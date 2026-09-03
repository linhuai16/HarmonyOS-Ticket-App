import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit'
import { ServiceCardStore } from '../servicecard/ServiceCardStore'
import { PerformanceReminderRuntime } from './PerformanceReminderRuntime'

export default class ReminderWorkAbility extends WorkSchedulerExtensionAbility {
  onWorkStart(work: workScheduler.WorkInfo): void {
    const userId: string = ServiceCardStore.getUserId(this.context)
    PerformanceReminderRuntime.register(this.context)
    PerformanceReminderRuntime.reconcileNow(userId).finally((): void => {
      try {
        workScheduler.stopWork(work, false)
      } catch (error) {
      }
    })
  }

  onWorkStop(work: workScheduler.WorkInfo): void {
  }
}
