import {
  AudienceListPageVO,
  AudienceItemVO
} from '../model/vo/user/AudiencePageVO'
import { Audience } from '../model/entity/Audience'
import { CertificateType } from '../model/enums/CertificateType'
import { ApiClient } from '../network/ApiClient'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

export interface CreateAudienceRequest {
  realName: string
  certificateType: CertificateType
  certificateNo: string
  phone: string
  isDefault: boolean
}

export interface UpdateAudienceRequest {
  realName: string
  certificateType: CertificateType
  certificateNo: string
  phone: string
  isDefault: boolean
}

interface BackendAudienceItemVO {
  audienceId: number | string
  realName?: string | null
  certificateType?: string | null
  maskedCertificateNo?: string | null
  maskedPhone?: string | null
  isDefault?: boolean | null
}

interface BackendAudienceDetailVO {
  audienceId: number | string
  realName?: string | null
  certificateType?: string | null
  certificateNo?: string | null
  phone?: string | null
  isDefault?: boolean | null
}

interface BackendAudienceListPageVO {
  audiences: BackendAudienceItemVO[]
}

interface OperateResponse {
  success: boolean
}

/** 观演人 Repository：从 SpringBoot 接口读写，不再使用 Mock。 */
export class AudienceRepository {
  async getAudienceList(userId: string): Promise<AudienceListPageVO> {
    if (userId.length === 0) {
      return { audiences: [] }
    }

    const response: BackendAudienceListPageVO =
      await ApiClient.get<BackendAudienceListPageVO>('/api/users/' + encodeURIComponent(userId) + '/audiences')

    return {
      audiences: (response.audiences ?? []).map((item: BackendAudienceItemVO): AudienceItemVO => {
        return {
          audienceId: String(item.audienceId),
          realName: item.realName ?? '',
          certificateType: this.mapCertificateType(item.certificateType),
          maskedCertificateNo: item.maskedCertificateNo ?? '',
          maskedPhone: item.maskedPhone ?? '',
          isDefault: item.isDefault === true
        }
      })
    }
  }

  async getAudienceDetail(userId: string, audienceId: string): Promise<Audience | undefined> {
    if (userId.length === 0 || audienceId.length === 0) {
      return undefined
    }

    const response: BackendAudienceDetailVO =
      await ApiClient.get<BackendAudienceDetailVO>('/api/users/' + encodeURIComponent(userId) + '/audiences/' + encodeURIComponent(audienceId))

    return this.mapAudienceDetail(userId, response)
  }

  async createAudience(userId: string, request: CreateAudienceRequest): Promise<Audience | undefined> {
    if (userId.length === 0) {
      return undefined
    }

    const response: BackendAudienceDetailVO =
      await ApiClient.post<BackendAudienceDetailVO>('/api/users/' + encodeURIComponent(userId) + '/audiences', request)

    const audience: Audience = this.mapAudienceDetail(userId, response)
    AppStorageVersionUtil.bumpAudienceChangedVersion()
    return audience
  }

  async updateAudience(userId: string, audienceId: string, request: UpdateAudienceRequest): Promise<Audience | undefined> {
    if (userId.length === 0 || audienceId.length === 0) {
      return undefined
    }

    const response: BackendAudienceDetailVO =
      await ApiClient.put<BackendAudienceDetailVO>('/api/users/' + encodeURIComponent(userId) + '/audiences/' + encodeURIComponent(audienceId), request)

    const audience: Audience = this.mapAudienceDetail(userId, response)
    AppStorageVersionUtil.bumpAudienceChangedVersion()
    return audience
  }

  async deleteAudience(userId: string, audienceId: string): Promise<boolean> {
    if (userId.length === 0 || audienceId.length === 0) {
      return false
    }

    const response: OperateResponse =
      await ApiClient.delete<OperateResponse>('/api/users/' + encodeURIComponent(userId) + '/audiences/' + encodeURIComponent(audienceId))

    if (response.success) AppStorageVersionUtil.bumpAudienceChangedVersion()
    return response.success
  }

  async setDefaultAudience(userId: string, audienceId: string): Promise<boolean> {
    if (userId.length === 0 || audienceId.length === 0) {
      return false
    }

    const response: OperateResponse =
      await ApiClient.put<OperateResponse>('/api/users/' + encodeURIComponent(userId) + '/audiences/' + encodeURIComponent(audienceId) + '/default')

    if (response.success) AppStorageVersionUtil.bumpAudienceChangedVersion()
    return response.success
  }

  private mapCertificateType(certificateType: string | undefined | null): CertificateType {
    if (certificateType === CertificateType.PASSPORT) {
      return CertificateType.PASSPORT
    }
    if (certificateType === CertificateType.HK_MACAO_PASS) {
      return CertificateType.HK_MACAO_PASS
    }
    return CertificateType.ID_CARD
  }

  private mapAudienceDetail(userId: string, raw: BackendAudienceDetailVO): Audience {
    return {
      audienceId: String(raw.audienceId),
      userId: userId,
      realName: raw.realName ?? '',
      certificateType: this.mapCertificateType(raw.certificateType),
      certificateNo: raw.certificateNo ?? '',
      phone: raw.phone ?? '',
      isDefault: raw.isDefault === true
    }
  }
}
