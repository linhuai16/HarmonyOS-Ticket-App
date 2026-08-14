import { UserAddress } from '../model/entity/UserAddress'
import { CertificateType } from '../model/enums/CertificateType'
import { AddressRegionUtil } from '../utils/AddressRegionUtil'

export class UserDataUtil {
  static normalizeUserId(userId: string): string {
    return userId.trim()
  }

  static normalizeText(value: string): string {
    return value.trim()
  }

  static normalizeComparableText(value: string): string {
    return value.replace(/\s/g, '')
  }

  static normalizePhone(phone: string): string {
    return phone.trim()
  }

  static normalizeNickname(nickname: string): string {
    return nickname.trim()
  }

  static normalizeAvatarUrl(avatarUrl: string): string {
    const normalizedAvatarUrl: string = avatarUrl.trim()
    return normalizedAvatarUrl.length > 0 ? normalizedAvatarUrl : 'default_avatar'
  }

  static isValidNickname(nickname: string): boolean {
    const normalizedNickname: string = UserDataUtil.normalizeNickname(nickname)
    return normalizedNickname.length > 0 && normalizedNickname.length <= 12
  }

  static buildDefaultNickname(phone: string): string {
    const normalizedPhone: string = UserDataUtil.normalizePhone(phone)
    return normalizedPhone.length >= 4 ? `用户${normalizedPhone.substring(7)}` : '用户'
  }

  static buildFullAddress(address: UserAddress): string {
    return `${address.province}${address.city}${address.district}${address.detailAddress}`
  }

  static buildAddressComparableText(province: string, city: string, district: string, detailAddress: string): string {
    return UserDataUtil.normalizeComparableText(`${province}${city}${district}${detailAddress}`)
  }

  static isSameAddress(
    address: UserAddress,
    receiverName: string,
    receiverPhone: string,
    province: string,
    city: string,
    district: string,
    detailAddress: string
  ): boolean {
    const targetName: string = UserDataUtil.normalizeComparableText(receiverName)
    const targetPhone: string = UserDataUtil.normalizeComparableText(receiverPhone)
    const targetAddress: string = UserDataUtil.buildAddressComparableText(province, city, district, detailAddress)

    const itemName: string = UserDataUtil.normalizeComparableText(address.receiverName)
    const itemPhone: string = UserDataUtil.normalizeComparableText(address.receiverPhone)
    const itemAddress: string = UserDataUtil.buildAddressComparableText(
      address.province,
      address.city,
      address.district,
      address.detailAddress
    )

    return itemName === targetName && itemPhone === targetPhone && itemAddress === targetAddress
  }

  static isValidAudience(
    realName: string,
    certificateType: CertificateType,
    certificateNo: string,
    phone: string
  ): boolean {
    if (!UserDataUtil.isValidPersonName(realName)) {
      return false
    }

    if (!UserDataUtil.isValidPhone(phone)) {
      return false
    }

    return UserDataUtil.isValidCertificateNo(certificateType, certificateNo)
  }

  static isValidCertificateNo(certificateType: CertificateType, certificateNo: string): boolean {
    if (certificateType === CertificateType.ID_CARD) {
      return UserDataUtil.isValidIdCard(certificateNo)
    }

    if (certificateType === CertificateType.PASSPORT) {
      return UserDataUtil.isValidPassport(certificateNo)
    }

    if (certificateType === CertificateType.HK_MACAO_PASS) {
      return UserDataUtil.isValidHkMacaoPass(certificateNo)
    }

    return false
  }

  static getAddressValidateError(
    receiverName: string,
    receiverPhone: string,
    province: string,
    city: string,
    district: string,
    detailAddress: string
  ): string {
    if (!UserDataUtil.isValidPersonName(receiverName)) {
      return '收货人姓名格式不正确'
    }

    if (!UserDataUtil.isValidPhone(receiverPhone)) {
      return '手机号格式不正确'
    }

    if (province.trim().length === 0) {
      return '请选择省份'
    }

    if (city.trim().length === 0) {
      return '请选择城市'
    }

    if (district.trim().length === 0) {
      return '请选择区县'
    }

    if (detailAddress.trim().length === 0) {
      return '请输入详细地址'
    }

    if (!AddressRegionUtil.isValidProvinceName(province)) {
      return '请选择正确的省份'
    }

    if (!AddressRegionUtil.isValidCityName(province, city)) {
      return '请选择正确的城市'
    }

    if (!AddressRegionUtil.isValidDistrictName(province, city, district)) {
      return '请选择正确的区县'
    }

    return ''
  }

  static isValidPersonName(name: string): boolean {
    const regExp: RegExp = /^[\u4e00-\u9fa5a-zA-Z]{1,10}$/
    return regExp.test(name.trim())
  }

  static isValidPhone(phone: string): boolean {
    const regExp: RegExp = /^1[3-9]\d{9}$/
    return regExp.test(phone.trim())
  }

  static isValidIdCard(certificateNo: string): boolean {
    const regExp: RegExp = /^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dX]$/
    return regExp.test(certificateNo.trim())
  }

  static isValidPassport(certificateNo: string): boolean {
    const newPassport: RegExp = /^E[A-HJ-NP-Z]\d{7}$/
    const oldPassport: RegExp = /^G\d{8}$/
    const normalizedCertificateNo: string = certificateNo.trim()
    return newPassport.test(normalizedCertificateNo) || oldPassport.test(normalizedCertificateNo)
  }

  static isValidHkMacaoPass(certificateNo: string): boolean {
    const hkMacao: RegExp = /^[HM]\d{8}$/
    const mainland: RegExp = /^C\d{8}$|^\d{9}$/
    const normalizedCertificateNo: string = certificateNo.trim()
    return hkMacao.test(normalizedCertificateNo) || mainland.test(normalizedCertificateNo)
  }
}
