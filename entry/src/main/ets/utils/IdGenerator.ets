export class IdGenerator {
  static createOrderId(): string {
    return `order_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createOrderNo(): string {
    return `MM${IdGenerator.now()}${IdGenerator.randomSuffix()}`
  }

  static createOrderItemId(): string {
    return `order_item_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createOrderAudienceId(index: number): string {
    return `order_aud_${IdGenerator.now()}_${index}_${IdGenerator.randomSuffix()}`
  }

  static createOrderAddressId(): string {
    return `order_addr_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createTicketId(index: number): string {
    return `ticket_${IdGenerator.now()}_${index}_${IdGenerator.randomSuffix()}`
  }

  static createQrCodeValue(ticketId: string): string {
    return `MM_TICKET_QR_CODE_${ticketId}_${IdGenerator.now()}`
  }

  static createSearchHistoryId(): string {
    return `history_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createRefundId(): string {
    return `refund_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createAudienceId(): string {
    return `aud_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createAddressId(): string {
    return `addr_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createUserId(): string {
    return `user_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createToken(userId: string): string {
    return `token_${userId}_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  static createWantId(): string {
    return `want_${IdGenerator.now()}_${IdGenerator.randomSuffix()}`
  }

  private static now(): number {
    return new Date().getTime()
  }

  private static randomSuffix(): number {
    return Math.floor(Math.random() * 1000)
  }
}
