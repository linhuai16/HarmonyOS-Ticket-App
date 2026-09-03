import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { notificationManager } from '@kit.NotificationKit'
import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { TicketRepository } from '../repository/TicketRepository'
import { TicketFolderItemVO } from '../model/vo/ticket/TicketFolderPageVO'

const STORE_NAME: string = 'performance_reminder'
const RECORDS_KEY: string = 'records'
const APP_BUNDLE: string = 'com.example.gomaimai'

class ReminderRecord {
  key: string = ''
  reminderId: number = 0
  userId: string = ''
}

class DesiredReminder {
  key: string = ''
  userId: string = ''
  orderId: string = ''
  ticketId: string = ''
  projectId: string = ''
  sessionId: string = ''
  title: string = ''
  venueName: string = ''
  reminderTime: Date = new Date()
  offsetHours: number = 0
}

export class PerformanceReminderRuntime {
  private static context: common.Context | undefined
  private static running: boolean = false
  private static pending: boolean = false

  static register(context: common.Context): void {
    PerformanceReminderRuntime.context = context
  }

  static requestReconcile(userId: string): void {
    if (userId.length === 0 || PerformanceReminderRuntime.context === undefined) {
      return
    }
    if (PerformanceReminderRuntime.running) {
      PerformanceReminderRuntime.pending = true
      return
    }
    PerformanceReminderRuntime.reconcile(userId).catch((error: Error): void => {
      console.error('[PerformanceReminder] reconcile failed=' + error.message)
    })
  }

  static async reconcileNow(userId: string): Promise<void> {
    if (userId.length === 0 || PerformanceReminderRuntime.context === undefined) {
      return
    }
    if (PerformanceReminderRuntime.running) {
      PerformanceReminderRuntime.pending = true
      return
    }
    await PerformanceReminderRuntime.reconcile(userId)
  }

  static async cancelForUser(userId: string): Promise<void> {
    const context: common.Context | undefined = PerformanceReminderRuntime.context
    if (context === undefined || userId.length === 0) {
      return
    }
    const records: ReminderRecord[] = PerformanceReminderRuntime.loadRecords(context)
    const keep: ReminderRecord[] = []
    for (let index: number = 0; index < records.length; index++) {
      const record: ReminderRecord = records[index]
      if (record.userId === userId) {
        await PerformanceReminderRuntime.cancel(record.reminderId)
      } else {
        keep.push(record)
      }
    }
    PerformanceReminderRuntime.saveRecords(context, keep)
  }

  private static async reconcile(userId: string): Promise<void> {
    const context: common.Context | undefined = PerformanceReminderRuntime.context
    if (context === undefined) {
      return
    }
    PerformanceReminderRuntime.running = true
    PerformanceReminderRuntime.pending = false
    try {
      const tickets: TicketFolderItemVO[] = (await new TicketRepository().getTicketFolderPage(userId)).tickets
      const desired: DesiredReminder[] = PerformanceReminderRuntime.buildDesired(userId, tickets)
      const validIds: number[] | undefined = await PerformanceReminderRuntime.validReminderIds()
      const records: ReminderRecord[] = PerformanceReminderRuntime.loadRecords(context)
      const desiredKeys: string[] = desired.map((item: DesiredReminder): string => item.key)
      const keep: ReminderRecord[] = []
      for (let index: number = 0; index < records.length; index++) {
        const record: ReminderRecord = records[index]
        if (record.userId !== userId) {
          keep.push(record)
        } else if (desiredKeys.includes(record.key) && (validIds === undefined || validIds.includes(record.reminderId))) {
          keep.push(record)
        } else {
          await PerformanceReminderRuntime.cancel(record.reminderId)
        }
      }
      const existingKeys: string[] = keep.map((item: ReminderRecord): string => item.key)
      for (let index: number = 0; index < desired.length; index++) {
        const item: DesiredReminder = desired[index]
        if (existingKeys.includes(item.key)) {
          continue
        }
        const reminderId: number | undefined = await PerformanceReminderRuntime.publish(item)
        if (reminderId !== undefined) {
          const record: ReminderRecord = new ReminderRecord()
          record.key = item.key
          record.reminderId = reminderId
          record.userId = item.userId
          keep.push(record)
        }
      }
      PerformanceReminderRuntime.saveRecords(context, keep)
    } finally {
      PerformanceReminderRuntime.running = false
      if (PerformanceReminderRuntime.pending) {
        PerformanceReminderRuntime.requestReconcile(userId)
      }
    }
  }

  private static buildDesired(userId: string, tickets: TicketFolderItemVO[]): DesiredReminder[] {
    const upcoming: TicketFolderItemVO[] = tickets.filter((item: TicketFolderItemVO): boolean => {
      const time: number = PerformanceReminderRuntime.parseTime(item.startTime)
      const performanceAvailable: boolean = item.projectStatus !== 'OFFLINE' && item.projectStatus !== 'CANCELLED' &&
        item.sessionStatus !== 'OFFLINE' && item.sessionStatus !== 'ENDED' && item.sessionStatus !== 'CANCELLED'
      return item.displayStatus === 'UNUSED' && item.orderStatus === 'WAIT_USE' && performanceAvailable && time > Date.now()
    }).sort((left: TicketFolderItemVO, right: TicketFolderItemVO): number => {
      return PerformanceReminderRuntime.parseTime(left.startTime) - PerformanceReminderRuntime.parseTime(right.startTime)
    })
    const selected: TicketFolderItemVO[] = []
    const performanceKeys: string[] = []
    for (let index: number = 0; index < upcoming.length && selected.length < 15; index++) {
      const item: TicketFolderItemVO = upcoming[index]
      const performanceKey: string = item.sessionId ?? item.orderId
      if (!performanceKeys.includes(performanceKey)) {
        performanceKeys.push(performanceKey)
        selected.push(item)
      }
    }
    const result: DesiredReminder[] = []
    const offsets: number[] = [24, 2]
    selected.forEach((item: TicketFolderItemVO): void => {
      const startMillis: number = PerformanceReminderRuntime.parseTime(item.startTime)
      offsets.forEach((offset: number): void => {
        const reminderMillis: number = startMillis - offset * 60 * 60 * 1000
        if (reminderMillis <= Date.now()) {
          return
        }
        const desired: DesiredReminder = new DesiredReminder()
        desired.userId = userId
        desired.orderId = item.orderId
        desired.ticketId = item.ticketId ?? ''
        desired.projectId = item.projectId ?? ''
        desired.sessionId = item.sessionId ?? ''
        desired.title = item.projectTitle
        desired.venueName = item.venueName
        desired.reminderTime = new Date(reminderMillis)
        desired.offsetHours = offset
        desired.key = [userId, item.sessionId ?? item.orderId, item.startTime, String(offset)].join('|')
        result.push(desired)
      })
    })
    return result
  }

  private static async publish(item: DesiredReminder): Promise<number | undefined> {
    try {
      const date: Date = item.reminderTime
      const request: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: date.getFullYear(),
          month: date.getMonth() + 1,
          day: date.getDate(),
          hour: date.getHours(),
          minute: date.getMinutes(),
          second: date.getSeconds()
        },
        wantAgent: {
          pkgName: APP_BUNDLE,
          abilityName: 'EntryAbility',
          parameters: {
            'entryTarget': item.ticketId.length > 0 ? 'TICKET_DETAIL' : 'ORDER_DETAIL',
            'entryUserId': item.userId,
            'entryOrderId': item.orderId,
            'entryTicketId': item.ticketId,
            'entryProjectId': item.projectId,
            'entrySessionId': item.sessionId,
            'notificationEventType': 'PERFORMANCE_REMINDER'
          }
        },
        title: item.offsetHours === 24 ? '明天有演出' : '演出即将开始',
        content: '《' + item.title + '》将在' + String(item.offsetHours) + '小时后于' + item.venueName + '开演',
        expiredContent: '本场观演提醒已过期',
        notificationId: PerformanceReminderRuntime.notificationId(item.key),
        groupId: 'PERFORMANCE_REMINDER_' + item.orderId,
        slotType: notificationManager.SlotType.SERVICE_INFORMATION,
        tapDismissed: true
      }
      return await reminderAgentManager.publishReminder(request)
    } catch (error) {
      console.error('[PerformanceReminder] publish failed=' + String(error))
      return undefined
    }
  }

  private static async validReminderIds(): Promise<number[] | undefined> {
    try {
      const reminders: reminderAgentManager.ReminderInfo[] = await reminderAgentManager.getAllValidReminders()
      return reminders.map((item: reminderAgentManager.ReminderInfo): number => item.reminderId)
    } catch (error) {
      return undefined
    }
  }

  private static async cancel(reminderId: number): Promise<void> {
    try {
      await reminderAgentManager.cancelReminder(reminderId)
    } catch (error) {
    }
  }

  private static parseTime(value: string): number {
    const timestamp: number = new Date(value.replace(' ', 'T')).getTime()
    return timestamp === timestamp ? timestamp : 0
  }

  private static notificationId(key: string): number {
    let hash: number = 17
    for (let index: number = 0; index < key.length; index++) {
      hash = (hash * 31 + key.charCodeAt(index)) & 0x7fffffff
    }
    return Math.max(1, hash)
  }

  private static loadRecords(context: common.Context): ReminderRecord[] {
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context, { name: STORE_NAME })
      const raw: string = String(store.getSync(RECORDS_KEY, '[]'))
      return JSON.parse(raw) as ReminderRecord[]
    } catch (error) {
      return []
    }
  }

  private static saveRecords(context: common.Context, records: ReminderRecord[]): void {
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context, { name: STORE_NAME })
      store.putSync(RECORDS_KEY, JSON.stringify(records))
      store.flushSync()
    } catch (error) {
    }
  }
}
