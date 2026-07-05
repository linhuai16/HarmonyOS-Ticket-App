import {
  AudienceListPageVO,
  AudienceItemVO
} from '../model/vo/user/AudiencePageVO'

import { Audience } from '../model/entity/Audience'
import { CertificateType } from '../model/enums/CertificateType'
import { UserDataUtil } from '../utils/UserDataUtil'

import {
  AudienceRepository,
  CreateAudienceRequest,
  UpdateAudienceRequest
} from '../repository/AudienceRepository'

/**
  观演人列表页
  观演人新增页
  观演人编辑页
  删除观演人
  设为默认观演人
  表单校验
 */
export class AudienceViewModel {
  audienceList: AudienceItemVO[] = []
  audienceDetail: Audience | undefined = undefined

  userId: string = ''
  audienceId: string = ''

  realName: string = ''
  certificateType: CertificateType = CertificateType.ID_CARD
  certificateNo: string = ''
  phone: string = ''
  isDefault: boolean = false

  isLoading: boolean = false
  errorMessage: string = ''

  private audienceRepository: AudienceRepository = new AudienceRepository()

  loadList(userId: string): void {
    this.isLoading = true
    this.errorMessage = ''
    this.userId = userId

    const pageVO: AudienceListPageVO = this.audienceRepository.getAudienceList(userId)
    this.audienceList = pageVO.audiences

    this.isLoading = false
  }

  loadDetail(userId: string, audienceId: string): void {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId
    this.audienceId = audienceId

    const detail: Audience | undefined =
      this.audienceRepository.getAudienceDetail(userId, audienceId)

    if (detail === undefined) {
      this.errorMessage = '观演人信息不存在'
      this.isLoading = false
      return
    }

    this.audienceDetail = detail
    this.applyDetail(detail)

    this.isLoading = false
  }

  createAudience(): boolean {
    if (this.userId.length === 0) {
      this.errorMessage = '用户未登录，请先登录'
      return false
    }

    if (!this.validateForm()) {
      return false
    }

    const request: CreateAudienceRequest = {
      realName: this.realName,
      certificateType: this.certificateType,
      certificateNo: this.certificateNo,
      phone: this.phone.trim(),
      isDefault: this.isDefault
    }

    const audience: Audience | undefined =
      this.audienceRepository.createAudience(this.userId, request)

    if (audience === undefined) {
      this.errorMessage = '新增观演人失败，证件信息可能已存在或格式不正确'
      return false
    }

    this.loadList(this.userId)
    return true
  }

  updateAudience(): boolean {
    if (this.userId.length === 0) {
      this.errorMessage = '用户未登录，请先登录'
      return false
    }

    if (this.audienceId.length === 0) {
      this.errorMessage = '观演人ID不能为空'
      return false
    }

    if (!this.validateForm()) {
      return false
    }

    const request: UpdateAudienceRequest = {
      realName: this.realName,
      certificateType: this.certificateType,
      certificateNo: this.certificateNo,
      phone: this.phone.trim(),
      isDefault: this.isDefault
    }

    const audience: Audience | undefined =
      this.audienceRepository.updateAudience(this.userId, this.audienceId, request)

    if (audience === undefined) {
      this.errorMessage = '修改观演人失败，证件信息可能已存在或格式不正确'
      return false
    }

    this.audienceDetail = audience
    this.loadList(this.userId)
    return true
  }

  deleteAudience(audienceId: string): boolean {
    const success: boolean = this.audienceRepository.deleteAudience(this.userId, audienceId)

    if (!success) {
      this.errorMessage = '删除观演人失败'
      return false
    }

    this.loadList(this.userId)
    return true
  }

  setDefaultAudience(audienceId: string): boolean {
    const success: boolean = this.audienceRepository.setDefaultAudience(this.userId, audienceId)

    if (!success) {
      this.errorMessage = '设置默认观演人失败'
      return false
    }

    this.loadList(this.userId)
    return true
  }

  resetForm(userId: string): void {
    this.userId = userId
    this.audienceId = ''
    this.audienceDetail = undefined

    this.realName = ''
    this.certificateType = CertificateType.ID_CARD
    this.certificateNo = ''
    this.phone = ''
    this.isDefault = false
    this.errorMessage = ''
  }

  setCertificateType(certificateType: CertificateType): void {
    this.certificateType = certificateType
    this.certificateNo = ''
    this.errorMessage = ''
  }

  canSave(): boolean {
    return UserDataUtil.isValidPersonName(this.realName) &&
      UserDataUtil.isValidCertificateNo(this.certificateType, this.certificateNo) &&
      UserDataUtil.isValidPhone(this.phone)
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private applyDetail(detail: Audience): void {
    this.realName = detail.realName
    this.certificateType = detail.certificateType
    this.certificateNo = detail.certificateNo
    this.phone = detail.phone
    this.isDefault = detail.isDefault
  }

  private validateForm(): boolean {
    if (!UserDataUtil.isValidPersonName(this.realName)) {
      this.errorMessage = '姓名格式不正确'
      return false
    }

    if (!UserDataUtil.isValidCertificateNo(this.certificateType, this.certificateNo)) {
      this.errorMessage = '证件号格式不正确'
      return false
    }

    if (this.phone.trim().length === 0) {
      this.errorMessage = '手机号不能为空'
      return false
    }

    if (!UserDataUtil.isValidPhone(this.phone)) {
      this.errorMessage = '手机号格式不正确'
      return false
    }

    this.errorMessage = ''
    return true
  }
}