export class MaskUtil {
  static maskCertificateNo(certificateNo: string): string {
    if (certificateNo.length <= 7) {
      return certificateNo
    }
    return `${certificateNo.substring(0, 3)}***********${certificateNo.substring(certificateNo.length - 4)}`
  }

  static maskPhone(phone: string): string {
    if (phone.length !== 11) {
      return phone
    }
    return `${phone.substring(0, 3)}****${phone.substring(7)}`
  }
}
