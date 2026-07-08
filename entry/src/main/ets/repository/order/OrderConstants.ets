export type OrderActionType = 'CONTINUE_PAY' | 'VIEW_TICKET' | 'TICKETING' | 'NONE'
export type OrderDetailTicketActionType = 'VIEW_TICKET' | 'TICKETING' | 'NONE'

export const PAY_EXPIRE_MINUTES: number = 15
export const TICKET_ISSUE_BEFORE_HOURS: number = 24 * 7
