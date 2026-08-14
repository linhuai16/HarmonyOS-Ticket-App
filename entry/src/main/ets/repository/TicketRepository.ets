import {
  TicketFolderPageVO,
  TicketFolderItemVO
} from '../model/vo/ticket/TicketFolderPageVO'

import {
  TicketDetailPageVO,
  ElectronicTicketVO
} from '../model/vo/ticket/TicketDetailPageVO'

import { TicketStatus } from '../model/enums/TicketStatus'
import { CertificateType } from '../model/enums/CertificateType'
import { CredentialType, DynamicQrMode } from '../model/vo/ticketsource/TicketSourceTypes'
import { ApiClient, ApiQueryParam } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

const CUSTOMER_SERVICE_PHONE: string = '400-000-0000'

interface BackendTicketFolderPageVO {
  userId?: number | string
  total?: number
  items?: BackendTicketFolderItemVO[]
  tickets?: BackendTicketFolderItemVO[]
}

interface BackendTicketFolderItemVO {
  orderId: number | string
  orderNo?: string
  orderStatus?: string
  projectId?: number | string
  sessionId?: number | string
  title: string
  posterUrl: string
  cityName?: string
  stationName?: string
  startTime: string
  endTime?: string
  venueName: string
  venueAddress?: string
  venueLongitude?: number | string | null
  venueLatitude?: number | string | null
  deliveryType?: string
  deliveryMode?: string
  skuSummary?: string
  skuName?: string
  totalQuantity?: number
  payAmount?: number
  ticketCount: number
  defaultTicketId?: number | string
  ticketId?: number | string
  ticketStatus: string
  displayStatus: 'UNUSED' | 'UNAVAILABLE'
  createTime?: string
}

interface BackendTicketDetailPageVO {
  orderId: number | string
  orderNo?: string
  orderStatus?: string
  projectId?: number | string
  sessionId?: number | string
  title: string
  posterUrl: string
  cityName?: string
  stationName?: string
  startTime: string
  endTime?: string
  venueName: string
  venueAddress?: string
  venueLongitude?: number | string | null
  venueLatitude?: number | string | null
  deliveryType?: string
  deliveryMode?: string
  totalQuantity?: number
  payAmount?: number
  defaultTicketId?: number | string
  tickets?: BackendElectronicTicketVO[]
  customerServicePhone?: string
}

interface BackendElectronicTicketVO {
  ticketId: number | string
  ticketNo?: string
  orderId?: number | string
  orderItemId?: number | string
  orderAudienceId?: number | string
  ticketStatus: string
  credentialType?: string | null
  dynamicQrMode?: string | null
  credentialVersion?: string | null
  credentialExpireTime?: string | null
  refreshAfterSeconds?: number | string | null
  credentialDisplayValue?: string | null
  qrCodeValue?: string | null
  seatInfo?: string
  entranceInfo?: string | null
  generateTime?: string
  checkTime?: string
  expireTime?: string
  abnormalReason?: string
  skuId?: number | string
  skuName: string
  unitPrice?: number
  realName?: string
  audienceName?: string
  certificateType?: string
  maskedCertificateNo?: string
}

interface MockTicketIssueSuccessResponse {
  success: boolean
  orderId: number | string
  orderStatus: string
  issuedCount?: number
  ticketIssuedTime?: string
}

interface MockTicketIssueFailedResponse {
  success: boolean
  orderId: number | string
  orderStatus: string
  refundId?: number | string
  refundNo?: string
  expiredCount?: number
}

interface MockTicketCheckResponse {
  success: boolean
  ticketId: number | string
  orderId: number | string
  ticketStatus: string
  checkTime?: string
}

/** 票夹 / 电子票 Repository：从 SpringBoot 接口读写，不再使用 Mock。 */
export class TicketRepository {
  async getTicketFolderPage(userId: string): Promise<TicketFolderPageVO> {
    if (userId.length === 0) {
      return { tickets: [] }
    }

    const response: BackendTicketFolderPageVO =
      await ApiClient.get<BackendTicketFolderPageVO>('/api/ticket-source/user/v13/users/' + encodeURIComponent(userId) + '/ticket-folder')

    const rawItems: BackendTicketFolderItemVO[] = response.items ?? response.tickets ?? []
    const tickets: TicketFolderItemVO[] = rawItems.map((item: BackendTicketFolderItemVO): TicketFolderItemVO => {
      return {
        orderId: String(item.orderId),
        orderStatus: item.orderStatus,
        ticketId: this.toOptionalString(item.defaultTicketId ?? item.ticketId),
        posterUrl: item.posterUrl,
        projectTitle: item.title,
        startTime: item.startTime,
        venueName: item.venueName,
        venueAddress: item.venueAddress ?? '',
        deliveryType: item.deliveryType ?? 'ETICKET',
        deliveryMode: item.deliveryMode,
        ticketCount: Number(item.ticketCount),
        skuName: item.skuSummary ?? item.skuName ?? '',
        displayStatus: item.displayStatus,
        ticketStatus: item.ticketStatus as TicketStatus
      }
    })

    return {
      tickets: tickets
    }
  }

  async getTicketDetailPage(userId: string, orderId: string, ticketId: string | undefined = undefined): Promise<TicketDetailPageVO | undefined> {
    if (userId.length === 0 || orderId.length === 0) {
      return undefined
    }

    const params: ApiQueryParam[] = [
      new ApiQueryParam('userId', userId)
    ]

    if (ticketId !== undefined && ticketId.length > 0) {
      params.push(new ApiQueryParam('ticketId', ticketId))
    }

    const response: BackendTicketDetailPageVO =
      await ApiClient.get<BackendTicketDetailPageVO>('/api/ticket-source/user/v13/orders/' + encodeURIComponent(orderId) + '/ticket-detail', params)

    const rawTickets: BackendElectronicTicketVO[] = response.tickets ?? []
    const ticketTotal: number = rawTickets.length
    const tickets: ElectronicTicketVO[] = rawTickets.map((ticket: BackendElectronicTicketVO, index: number): ElectronicTicketVO => {
      const maskedCertificateNo: string = ticket.maskedCertificateNo ?? '-'
      const audienceName: string = ticket.realName ?? ticket.audienceName ?? '观演人信息异常'
      return {
        ticketId: String(ticket.ticketId),
        ticketStatus: ticket.ticketStatus as TicketStatus,
        ticketIndex: index + 1,
        ticketTotal: ticketTotal,
        credentialType: this.toCredentialType(ticket.credentialType),
        dynamicQrMode: this.toDynamicQrMode(ticket.dynamicQrMode),
        credentialVersion: this.toOptionalString(ticket.credentialVersion),
        credentialExpireTime: this.toOptionalString(ticket.credentialExpireTime),
        refreshAfterSeconds: ticket.refreshAfterSeconds === undefined || ticket.refreshAfterSeconds === null ? undefined : Number(ticket.refreshAfterSeconds),
        credentialDisplayValue: this.toOptionalString(ticket.credentialDisplayValue),
        qrCodeValue: this.toOptionalString(ticket.qrCodeValue),
        skuName: ticket.skuName ?? '',
        seatInfo: this.toOptionalString(ticket.seatInfo),
        entranceInfo: this.toOptionalString(ticket.entranceInfo),
        audienceName: audienceName,
        certificateType: ticket.certificateType as CertificateType,
        maskedCertificateNo: maskedCertificateNo,
        abnormalReason: this.toOptionalString(ticket.abnormalReason)
      }
    })

    return {
      posterUrl: response.posterUrl,
      projectTitle: response.title,
      startTime: response.startTime,
      venueName: response.venueName,
      venueAddress: response.venueAddress ?? '',
      venueLongitude: this.toOptionalNumber(response.venueLongitude),
      venueLatitude: this.toOptionalNumber(response.venueLatitude),
      orderStatus: response.orderStatus,
      deliveryType: response.deliveryType ?? 'ETICKET',
      deliveryMode: response.deliveryMode,
      totalQuantity: Number(response.totalQuantity ?? rawTickets.length),
      tickets: tickets,
      customerServicePhone: response.customerServicePhone ?? CUSTOMER_SERVICE_PHONE
    }
  }

  async mockIssueSuccess(orderId: string): Promise<boolean> {
    if (orderId.length === 0) {
      return false
    }

    const response: MockTicketIssueSuccessResponse =
      await ApiClient.post<MockTicketIssueSuccessResponse>('/api/mock/orders/' + encodeURIComponent(orderId) + '/tickets/issue-success')

    if (response.success) {
      AppStorageVersionUtil.bumpOrderTicketRelatedVersions()
    }

    return response.success
  }

  async mockIssueFailed(orderId: string, reason: string = '出票接口异常，系统已发起原路退款'): Promise<boolean> {
    if (orderId.length === 0) {
      return false
    }

    const response: MockTicketIssueFailedResponse =
      await ApiClient.post<MockTicketIssueFailedResponse>('/api/mock/orders/' + encodeURIComponent(orderId) + '/tickets/issue-failed?' +
        'abnormalReason=' + encodeURIComponent(reason))

    if (response.success) {
      AppStorageVersionUtil.bumpOrderTicketRelatedVersions()
    }

    return response.success
  }

  async mockCheckTicket(ticketId: string): Promise<boolean> {
    if (ticketId.length === 0) {
      return false
    }

    const response: MockTicketCheckResponse =
      await ApiClient.post<MockTicketCheckResponse>('/api/mock/tickets/' + encodeURIComponent(ticketId) + '/check')

    if (response.success) {
      AppStorageVersionUtil.bumpTicketChangedVersion()
      AppStorageVersionUtil.bumpUserCenterChangedVersion()
    }

    return response.success
  }

  async mockExpireUnusedTickets(_orderId: string): Promise<boolean> {
    // 后端当前没有单独的“手动过期未使用票”接口；保留方法避免调试入口报错。
    return false
  }

  private toOptionalString(value: number | string | undefined | null): string | undefined {
    if (value === undefined || value === null) {
      return undefined
    }
    const text: string = String(value)
    return text.length === 0 ? undefined : text
  }

  private toOptionalNumber(value: number | string | undefined | null): number | undefined {
    if (value === undefined || value === null || String(value).length === 0) {
      return undefined
    }
    const numberValue: number = Number(value)
    return numberValue === numberValue ? numberValue : undefined
  }

  private toCredentialType(value: string | undefined | null): CredentialType | undefined {
    return value === undefined || value === null || value.length === 0 ? undefined : value as CredentialType
  }

  private toDynamicQrMode(value: string | undefined | null): DynamicQrMode | undefined {
    return value === undefined || value === null || value.length === 0 ? undefined : value as DynamicQrMode
  }


}
