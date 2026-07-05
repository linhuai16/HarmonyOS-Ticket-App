/**
 * 证件类型
 *
 * 来源：
 * 观演人创建页支持身份证、护照、港澳通行证。
 */
export enum CertificateType {
  /** 身份证 */
  ID_CARD = 'ID_CARD',

  /** 护照 */
  PASSPORT = 'PASSPORT',

  /** 港澳通行证 */
  HK_MACAO_PASS = 'HK_MACAO_PASS'
}