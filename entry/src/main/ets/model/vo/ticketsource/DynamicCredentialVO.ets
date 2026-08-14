import { CredentialType } from './TicketSourceTypes'

/**
 * 动态二维码一次性响应模型。
 * credentialPayload 只能存在于当前页面内存；禁止写入 Preferences、数据库、AppStorage 或 ElectronicTicket 实体。
 */
export interface DynamicCredentialVO {
  ticketId: string
  credentialType: CredentialType
  credentialPayload: string
  credentialVersion: string
  issuedAt: string
  expiresAt: string
  refreshAfterSeconds: number
  serverTime: string
}
