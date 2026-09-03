import {
  TicketFolderPageVO,
  TicketFolderItemVO
} from '../model/vo/ticket/TicketFolderPageVO'

import { TicketRepository } from '../repository/TicketRepository'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

export interface TicketDetailJumpParams {
  userId: string
  orderId: string
  ticketId?: string
}


/**

 
 */
export class TicketFolderViewModel {
  tickets: TicketFolderItemVO[] = []

  userId: string = ''

  isLoading: boolean = false
  errorMessage: string = ''

  private ticketRepository: TicketRepository = new TicketRepository()
  private hasLoaded: boolean = false

  async loadPage(userId: string): Promise<void> {
    if (this.isLoading) {
      return
    }
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    try {
      const previousState: string = this.serviceCardStateSignature(this.tickets)
      const pageVO: TicketFolderPageVO = await this.ticketRepository.getTicketFolderPage(userId)
      this.tickets = pageVO.tickets
      if (this.hasLoaded && previousState !== this.serviceCardStateSignature(pageVO.tickets)) {
        AppStorageVersionUtil.bumpOrderTicketRelatedVersions()
      }
      this.hasLoaded = true
    } catch (error) {
      this.errorMessage = '票夹加载失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }

  async refresh(): Promise<void> {
    if (this.userId.length === 0) {
      return
    }

    await this.loadPage(this.userId)
  }

  hasTickets(): boolean {
    return this.tickets.length > 0
  }

  buildTicketDetailJumpParams(item: TicketFolderItemVO): TicketDetailJumpParams {
    const params: TicketDetailJumpParams = {
      userId: this.userId,
      orderId: item.orderId,
      ticketId: item.ticketId
    }

    return params
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private serviceCardStateSignature(tickets: TicketFolderItemVO[]): string {
    return tickets.map((item: TicketFolderItemVO): string => {
      return item.orderId + ':' + String(item.orderStatus ?? '') + ':' + String(item.ticketStatus) + ':' +
        String(item.ticketCount) + ':' + (item.ticketId ?? '')
    }).join('|')
  }
}
