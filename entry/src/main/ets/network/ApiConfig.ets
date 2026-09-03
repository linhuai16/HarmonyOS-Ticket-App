/**
 * SpringBoot 接口配置。

 */
export class ApiConfig {
  /**
   * 接口地址，也可 使用Hcloudflared，将本地接口生成随机的公网HTTPS 地址
   */
  static readonly BASE_URLS: string[] = [
    'http://127.0.0.1:8080',
    'http://localhost:8080',
    'http://10.0.2.2:8080'
  ]



  static readonly TIMEOUT: number = 15000
}
