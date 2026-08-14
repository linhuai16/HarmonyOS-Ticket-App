import { DynamicCredentialVO } from '../model/vo/ticketsource/DynamicCredentialVO'
import { CredentialType } from '../model/vo/ticketsource/TicketSourceTypes'
import { ApiClient } from '../network/ApiClient'

interface BackendDynamicCredential {
  ticketId: number | string
  credentialType: string
  credentialPayload: string
  credentialVersion?: string | null
  issuedAt?: string | null
  expiresAt?: string | null
  refreshAfterSeconds?: number | null
  serverTime?: string | null
}

/**
 * V1.3 第十一批动态凭证数据层。
 * 第三方 providerTicketId、provider ticketProductId 不向页面透传。
 */
export class TicketSourceFulfillmentRepository {
  /**
   * 动态码明文仅返回给调用方。Repository 不缓存，也不写入任何持久化/全局状态。
   */
  async refreshDynamicCredential(orderId: string, ticketId: string, userId: string): Promise<DynamicCredentialVO> {
    const raw: BackendDynamicCredential = await ApiClient.post<BackendDynamicCredential>(
      '/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/tickets/' + encodeURIComponent(ticketId) +
      '/dynamic-credential:refresh?userId=' + encodeURIComponent(userId)
    )
    return {
      ticketId: String(raw.ticketId),
      credentialType: raw.credentialType as CredentialType,
      credentialPayload: raw.credentialPayload,
      credentialVersion: raw.credentialVersion ?? '',
      issuedAt: raw.issuedAt ?? '',
      expiresAt: raw.expiresAt ?? '',
      refreshAfterSeconds: Number(raw.refreshAfterSeconds ?? 0),
      serverTime: raw.serverTime ?? ''
    }
  }

}
