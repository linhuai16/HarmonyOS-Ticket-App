import {
  AudienceListPageVO,
  AudienceItemVO
} from '../model/vo/user/AudiencePageVO'
import { Audience } from '../model/entity/Audience'
import { audienceMockList } from '../mock/user/AudienceMock'
import { CertificateType } from '../model/enums/CertificateType'
import { MaskUtil } from '../utils/MaskUtil'
import { IdGenerator } from '../utils/IdGenerator'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'
import { UserDataUtil } from '../utils/UserDataUtil'

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

/**
 获取观演人列表
 获取观演人详情
 新增观演人
 修改观演人
 删除观演人
 设为默认观演人
 */
export class AudienceRepository {

  /**
   * 1. 获取观演人列表
   */
  getAudienceList(userId: string): AudienceListPageVO {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    if (normalizedUserId.length === 0) {
      const emptyResult: AudienceListPageVO = {
        audiences: new Array<AudienceItemVO>()
      }
      return emptyResult
    }

    this.ensureSingleDefault(normalizedUserId)

    const userAudiences: Audience[] = this.getUserAudiences(normalizedUserId)
    userAudiences.sort((a: Audience, b: Audience): number => {
      return this.compareDefaultFirst(a.isDefault, b.isDefault)
    })

    const audiences: AudienceItemVO[] = []
    userAudiences.forEach((item: Audience) => {
      audiences.push(this.buildAudienceItemVO(item))
    })

    const result: AudienceListPageVO = {
      audiences: audiences
    }

    return result
  }

  /**
   * 2. 获取观演人详情
   */
  getAudienceDetail(userId: string, audienceId: string): Audience | undefined {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAudienceId: string = audienceId.trim()

    if (normalizedUserId.length === 0 || normalizedAudienceId.length === 0) {
      return undefined
    }

    return this.findAudience(normalizedUserId, normalizedAudienceId)
  }

  /**
   * 3. 新增观演人
   */
  createAudience(userId: string, request: CreateAudienceRequest): Audience | undefined {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    if (normalizedUserId.length === 0) {
      return undefined
    }

    const realName: string = request.realName.trim()
    const certificateNo: string = request.certificateNo.trim()
    const phone: string = request.phone.trim()

    if (!UserDataUtil.isValidAudience(realName, request.certificateType, certificateNo, phone)) {
      return undefined
    }

    if (this.hasSameCertificate(normalizedUserId, certificateNo)) {
      return undefined
    }

    const shouldSetDefault: boolean = request.isDefault || this.getUserAudienceCount(normalizedUserId) === 0
    if (shouldSetDefault) {
      this.clearDefault(normalizedUserId)
    }

    const audience: Audience = {
      audienceId: IdGenerator.createAudienceId(),
      userId: normalizedUserId,
      realName: realName,
      certificateType: request.certificateType,
      certificateNo: certificateNo,
      phone: phone,
      isDefault: shouldSetDefault
    }

    audienceMockList.push(audience)
    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAudienceChangedVersion()

    return audience
  }

  /**
   * 4. 修改观演人
   */
  updateAudience(userId: string, audienceId: string, request: UpdateAudienceRequest): Audience | undefined {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAudienceId: string = audienceId.trim()

    if (normalizedUserId.length === 0 || normalizedAudienceId.length === 0) {
      return undefined
    }

    const audience: Audience | undefined = this.findAudience(normalizedUserId, normalizedAudienceId)
    if (audience === undefined) {
      return undefined
    }

    const realName: string = request.realName.trim()
    const certificateNo: string = request.certificateNo.trim()
    const phone: string = request.phone.trim()

    if (!UserDataUtil.isValidAudience(realName, request.certificateType, certificateNo, phone)) {
      return undefined
    }

    if (this.hasSameCertificate(normalizedUserId, certificateNo, normalizedAudienceId)) {
      return undefined
    }

    if (request.isDefault) {
      this.clearDefault(normalizedUserId)
    }

    audience.realName = realName
    audience.certificateType = request.certificateType
    audience.certificateNo = certificateNo
    audience.phone = phone
    audience.isDefault = request.isDefault

    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAudienceChangedVersion()

    return audience
  }

  /**
   * 5. 删除观演人
   */
  deleteAudience(userId: string, audienceId: string): boolean {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAudienceId: string = audienceId.trim()

    if (normalizedUserId.length === 0 || normalizedAudienceId.length === 0) {
      return false
    }

    const index: number = audienceMockList.findIndex((item: Audience): boolean => {
      return item.userId === normalizedUserId && item.audienceId === normalizedAudienceId
    })

    if (index < 0) {
      return false
    }

    const isDefault: boolean = audienceMockList[index].isDefault
    audienceMockList.splice(index, 1)

    if (isDefault) {
      this.resetFirstAsDefault(normalizedUserId)
    }

    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAudienceChangedVersion()
    return true
  }

  /**
   * 6. 设为默认观演人
   */
  setDefaultAudience(userId: string, audienceId: string): boolean {
    const normalizedUserId: string = UserDataUtil.normalizeUserId(userId)
    const normalizedAudienceId: string = audienceId.trim()

    if (normalizedUserId.length === 0 || normalizedAudienceId.length === 0) {
      return false
    }

    const audience: Audience | undefined = this.findAudience(normalizedUserId, normalizedAudienceId)
    if (audience === undefined) {
      return false
    }

    this.clearDefault(normalizedUserId)
    audience.isDefault = true
    this.ensureSingleDefault(normalizedUserId)
    AppStorageVersionUtil.bumpAudienceChangedVersion()

    return true
  }

  private buildAudienceItemVO(item: Audience): AudienceItemVO {
    const vo: AudienceItemVO = {
      audienceId: item.audienceId,
      realName: item.realName,
      certificateType: item.certificateType,
      maskedCertificateNo: MaskUtil.maskCertificateNo(item.certificateNo),
      maskedPhone: MaskUtil.maskPhone(item.phone),
      isDefault: item.isDefault
    }

    return vo
  }

  private getUserAudiences(userId: string): Audience[] {
    const audiences: Audience[] = []
    audienceMockList.forEach((item: Audience) => {
      if (item.userId === userId) {
        audiences.push(item)
      }
    })
    return audiences
  }

  private getUserAudienceCount(userId: string): number {
    let count: number = 0
    audienceMockList.forEach((item: Audience) => {
      if (item.userId === userId) {
        count++
      }
    })
    return count
  }

  private findAudience(userId: string, audienceId: string): Audience | undefined {
    return audienceMockList.find((item: Audience): boolean => {
      return item.userId === userId && item.audienceId === audienceId
    })
  }

  private hasSameCertificate(userId: string, certificateNo: string, ignoreAudienceId: string = ''): boolean {
    return audienceMockList.some((item: Audience): boolean => {
      if (item.userId !== userId) {
        return false
      }

      if (ignoreAudienceId.length > 0 && item.audienceId === ignoreAudienceId) {
        return false
      }

      return item.certificateNo === certificateNo
    })
  }

  private compareDefaultFirst(leftIsDefault: boolean, rightIsDefault: boolean): number {
    if (leftIsDefault && !rightIsDefault) {
      return -1
    }

    if (!leftIsDefault && rightIsDefault) {
      return 1
    }

    return 0
  }

  private ensureSingleDefault(userId: string): void {
    const userAudiences: Audience[] = this.getUserAudiences(userId)
    if (userAudiences.length === 0) {
      return
    }

    let activeDefaultAudienceId: string = ''
    userAudiences.forEach((item: Audience) => {
      if (item.isDefault) {
        activeDefaultAudienceId = item.audienceId
      }
    })

    if (activeDefaultAudienceId.length === 0) {
      activeDefaultAudienceId = userAudiences[0].audienceId
    }

    userAudiences.forEach((item: Audience) => {
      item.isDefault = item.audienceId === activeDefaultAudienceId
    })
  }

  private clearDefault(userId: string): void {
    audienceMockList.forEach((item: Audience) => {
      if (item.userId === userId) {
        item.isDefault = false
      }
    })
  }

  private resetFirstAsDefault(userId: string): void {
    const first: Audience | undefined = audienceMockList.find((item: Audience): boolean => {
      return item.userId === userId
    })

    if (first !== undefined) {
      first.isDefault = true
    }
  }
}
