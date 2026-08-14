import {
  TicketFolderPageVO,
  TicketFolderItemVO
} from '../model/vo/ticket/TicketFolderPageVO'

import { TicketRepository } from '../repository/TicketRepository'

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

  async loadPage(userId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId

    const pageVO: TicketFolderPageVO =
      await this.ticketRepository.getTicketFolderPage(userId)

    this.tickets = pageVO.tickets

    this.isLoading = false
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
}