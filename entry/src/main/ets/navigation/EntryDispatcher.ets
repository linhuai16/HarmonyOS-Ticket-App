import { Want } from '@kit.AbilityKit'

const REQUEST_KEY: string = 'entry_request'
const VERSION_KEY: string = 'entry_request_version'

export class EntryDispatchRequest {
  target: string = 'HOME'
  userId: string = ''
  orderId: string = ''
  ticketId: string = ''
  projectId: string = ''
  sessionId: string = ''
}

export class EntryDispatcher {
  static receive(want: Want): void {
    const target: string = EntryDispatcher.read(want, 'entryTarget')
    if (target.length === 0) {
      return
    }
    const request: EntryDispatchRequest = new EntryDispatchRequest()
    request.target = target
    request.userId = EntryDispatcher.read(want, 'entryUserId')
    request.orderId = EntryDispatcher.read(want, 'entryOrderId')
    request.ticketId = EntryDispatcher.read(want, 'entryTicketId')
    request.projectId = EntryDispatcher.read(want, 'entryProjectId')
    request.sessionId = EntryDispatcher.read(want, 'entrySessionId')
    AppStorage.setOrCreate(REQUEST_KEY, JSON.stringify(request))
    const currentVersion: number = AppStorage.get<number>(VERSION_KEY) ?? 0
    AppStorage.setOrCreate(VERSION_KEY, currentVersion + 1)
  }

  static consume(): EntryDispatchRequest | undefined {
    const raw: string = AppStorage.get<string>(REQUEST_KEY) ?? ''
    if (raw.length === 0) {
      return undefined
    }
    AppStorage.setOrCreate(REQUEST_KEY, '')
    try {
      return JSON.parse(raw) as EntryDispatchRequest
    } catch (error) {
      return undefined
    }
  }

  private static read(want: Want, key: string): string {
    const value: Object | undefined = want.parameters?.[key]
    return value === undefined || value === null ? '' : String(value)
  }
}
