import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ApiConfig } from './ApiConfig'

export class ApiQueryParam {
  key: string
  value: string

  constructor(key: string, value: string | number | boolean | undefined | null) {
    this.key = key
    this.value = value === undefined || value === null ? '' : String(value)
  }
}

export interface ApiResult<T> {
  code: number
  message?: string
  data?: T
}

/**
 * 统一接口请求工具。
 *
 * 注意：鸿蒙模拟器/真机访问电脑 SpringBoot 时，localhost 很容易访问不到。
 * 所以这里按 ApiConfig.BASE_URLS 顺序尝试多个 baseUrl，并打印请求日志，方便排查。
 */
export class ApiClient {
  private static activeBaseUrl: string = ApiConfig.BASE_URLS[0]

  static getStreamingBaseUrlCandidates(): string[] {
    return ApiClient.getBaseUrlCandidates()
  }

  static activateBaseUrl(baseUrl: string): void {
    if (ApiConfig.BASE_URLS.includes(baseUrl)) {
      ApiClient.activeBaseUrl = baseUrl
    }
  }

  static resolveMediaUrl(path: string | undefined | null): string {
    const value: string = path?.trim() ?? ''
    if (value.length === 0) {
      return ''
    }
    if (value.startsWith('http://') || value.startsWith('https://') || value.startsWith('data:image/')) {
      return value
    }
    if (value.startsWith('/')) {
      return ApiClient.activeBaseUrl + value
    }
    return value
  }

  static async get<T>(path: string, params: ApiQueryParam[] = []): Promise<T> {
    return ApiClient.requestWithFallback<T>(http.RequestMethod.GET, path, params)
  }

  static async post<T>(path: string, body?: object): Promise<T> {
    return ApiClient.requestWithFallback<T>(http.RequestMethod.POST, path, [], body)
  }

  static async put<T>(path: string, body?: object): Promise<T> {
    return ApiClient.requestWithFallback<T>(http.RequestMethod.PUT, path, [], body)
  }

  static async delete<T>(path: string, params: ApiQueryParam[] = []): Promise<T> {
    return ApiClient.requestWithFallback<T>(http.RequestMethod.DELETE, path, params)
  }

  private static async requestWithFallback<T>(
    method: http.RequestMethod,
    path: string,
    params: ApiQueryParam[] = [],
    body?: object
  ): Promise<T> {
    let lastError: Error = new Error('接口请求失败')
    const baseUrls: string[] = ApiClient.getBaseUrlCandidates()

    for (let index = 0; index < baseUrls.length; index++) {
      const baseUrl: string = baseUrls[index]
      const url: string = ApiClient.buildUrl(baseUrl, path, params)

      try {
        const data: T = await ApiClient.request<T>(method, url, body)
        ApiClient.activeBaseUrl = baseUrl
        return data
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error))
        console.error('[ApiClient] request failed url=' + url + ', error=' + lastError.message)

        // 后端已经返回业务错误时，不再切换 baseUrl，避免把真实业务错误吞掉。
        if (lastError.message.startsWith('接口返回失败：')) {
          throw lastError
        }
      }
    }

    throw lastError
  }

  private static getBaseUrlCandidates(): string[] {
    const result: string[] = [ApiClient.activeBaseUrl]
    ApiConfig.BASE_URLS.forEach((baseUrl: string) => {
      if (baseUrl !== ApiClient.activeBaseUrl) {
        result.push(baseUrl)
      }
    })
    return result
  }

  private static buildUrl(baseUrl: string, path: string, params: ApiQueryParam[] = []): string {
    let url: string = baseUrl + path
    const queryItems: string[] = []

    params.forEach((param: ApiQueryParam) => {
      if (param.value.length === 0) {
        return
      }
      queryItems.push(encodeURIComponent(param.key) + '=' + encodeURIComponent(param.value))
    })

    if (queryItems.length > 0) {
      url += '?' + queryItems.join('&')
    }

    return url
  }

  private static async request<T>(method: http.RequestMethod, url: string, body?: object): Promise<T> {
    const httpRequest: http.HttpRequest = http.createHttp()

    return new Promise<T>((resolve: (value: T) => void, reject: (reason: Error) => void) => {
      const options: http.HttpRequestOptions = {
        method: method,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT,
        expectDataType: http.HttpDataType.STRING,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache'
        }
      }

      const loginToken: string = AppStorage.get<string>('login_token') ?? ''
      if (loginToken.length > 0) {
        options.header = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
          'Authorization': 'Bearer ' + loginToken
        }
      }

      if (body !== undefined) {
        options.extraData = JSON.stringify(body)
      }

      httpRequest.request(url, options, (error: BusinessError, response: http.HttpResponse) => {
        httpRequest.destroy()

        if (error) {
          reject(new Error(error.message))
          return
        }

        if (response.responseCode < 200 || response.responseCode >= 300) {
          reject(new Error('网络请求失败：' + response.responseCode))
          return
        }

        try {
          const resultText: string = String(response.result)

          const apiResult: ApiResult<T> = JSON.parse(resultText) as ApiResult<T>

          if (apiResult.code !== 200) {
            reject(new Error('接口返回失败：' + (apiResult.message ?? '未知错误')))
            return
          }

          resolve(apiResult.data as T)
        } catch (parseError) {
          reject(new Error('接口数据解析失败'))
        }
      })
    })
  }
}
