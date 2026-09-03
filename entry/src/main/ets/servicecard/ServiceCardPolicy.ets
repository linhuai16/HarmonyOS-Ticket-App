import { TicketFolderItemVO } from '../model/vo/ticket/TicketFolderPageVO'

export class ServiceCardPolicy {
  static selectUpcomingTicket(items: TicketFolderItemVO[], now: number = Date.now()): TicketFolderItemVO | undefined {
    const candidates: TicketFolderItemVO[] = items.filter((item: TicketFolderItemVO): boolean => {
      const start: number = ServiceCardPolicy.parseDateTime(item.startTime)
      return item.displayStatus === 'UNUSED' && (start <= 0 || start >= now)
    })
    candidates.sort((left: TicketFolderItemVO, right: TicketFolderItemVO): number => {
      const leftTime: number = ServiceCardPolicy.parseDateTime(left.startTime)
      const rightTime: number = ServiceCardPolicy.parseDateTime(right.startTime)
      if (leftTime <= 0) return 1
      if (rightTime <= 0) return -1
      return leftTime - rightTime
    })
    return candidates[0]
  }

  private static parseDateTime(value: string): number {
    const normalized: string = value.trim().replace(' ', 'T')
    if (normalized.length === 0) {
      return 0
    }
    const result: number = new Date(normalized).getTime()
    return result === result ? result : 0
  }
}
