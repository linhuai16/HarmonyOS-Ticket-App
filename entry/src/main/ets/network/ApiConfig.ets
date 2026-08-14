/**
 * SpringBoot 接口配置。
 *
 * 当前首页/分类页没有数据，最常见原因是鸿蒙模拟器/真机不能通过 localhost 访问电脑上的 SpringBoot。
 * 这里先提供多个候选地址，ApiClient 会按顺序尝试。
 *
 * 如果你使用真机调试，请把第一项改成电脑的局域网 IP，例如：
 *   http://192.168.1.10:8080
 */
export class ApiConfig {
  /**
   * 优先使用的接口地址。
   * 真机调试时，建议把电脑局域网 IP 放到数组第一项。
   */
  static readonly BASE_URLS: string[] = [
    'http://127.0.0.1:8080',
    'http://localhost:8080',
    'http://10.0.2.2:8080'
  ]

  static readonly TIMEOUT: number = 15000
}
