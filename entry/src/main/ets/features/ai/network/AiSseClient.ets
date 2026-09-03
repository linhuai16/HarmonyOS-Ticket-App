import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { util } from '@kit.ArkTS'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { ApiClient } from '../../../network/ApiClient'
import {
  AiChatRequestBody,
  AiEntityContext,
  AiLastSearchResult,
  AiPerformanceCardVO,
  AiSearchContext,
  AiSearchResultState,
  AiSseDoneContext,
  AiSseListener
} from '../model/AiChatVO'

interface AiSseData {
  text?: string
  message?: string
  contextProjectId?: string | number
  contextSessionId?: string | number
  searchContext?: AiSearchContext
  lastSearchResults?: RawLastSearchResult[]
  selectedProjectId?: string | number
  selectedSessionId?: string | number
  searchResultState?: AiSearchResultState
  entityContext?: AiEntityContext
  activeSlot?: string
  capabilities?: string[]
}

interface RawLastSearchResult {
  projectId?: string | number | null
  sessionId?: string | number | null
  title?: string
}

interface RawPerformanceCard {
  projectId?: string | number
  sessionId?: string | number
  title?: string
  posterUrl?: string
  categoryName?: string
  cityName?: string
  venueName?: string
  startTime?: string
  minPrice?: number
  maxPrice?: number
}

export class AiSseGeneration {
  private cancelled: boolean = false
  private cancelAction: (() => void) | undefined = undefined

  cancel(): void {
    if (this.cancelled) return
    this.cancelled = true
    const action: (() => void) | undefined = this.cancelAction
    this.cancelAction = undefined
    if (action !== undefined) action()
  }

  bind(action: () => void): void {
    if (this.cancelled) {
      action()
      return
    }
    this.cancelAction = action
  }

  clear(): void {
    this.cancelAction = undefined
  }

  isCancelled(): boolean {
    return this.cancelled
  }
}

export class AiSseClient {
  private static readonly LOG_DOMAIN: number = 0x1200
  private static readonly LOG_TAG: string = 'AiSseClient'
  private static readonly CANCELLED_MESSAGE: string = 'AI_SSE_CANCELLED'

  static async stream(body: AiChatRequestBody, listener: AiSseListener,
                      generation: AiSseGeneration = new AiSseGeneration()): Promise<void> {
    const candidates: string[] = ApiClient.getStreamingBaseUrlCandidates()
    let lastError: Error = new Error('麦麦AI连接失败')
    for (let index = 0; index < candidates.length; index++) {
      if (generation.isCancelled()) throw new Error(AiSseClient.CANCELLED_MESSAGE)
      const baseUrl: string = candidates[index]
      try {
        await AiSseClient.request(baseUrl, body, listener, generation)
        ApiClient.activateBaseUrl(baseUrl)
        return
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error))
        if (generation.isCancelled() || lastError.message === AiSseClient.CANCELLED_MESSAGE) {
          throw new Error(AiSseClient.CANCELLED_MESSAGE)
        }
        if (lastError.message.startsWith('SSE_STARTED:')) {
          throw new Error(lastError.message.substring('SSE_STARTED:'.length))
        }
      }
    }
    throw lastError
  }

  static isCancellation(error: Error): boolean {
    return error.message === AiSseClient.CANCELLED_MESSAGE
  }

  private static request(baseUrl: string, body: AiChatRequestBody, listener: AiSseListener,
                         generation: AiSseGeneration): Promise<void> {
    const request: http.HttpRequest = http.createHttp()
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
    let lineBuffer: string = ''
    let currentEventName: string = 'message'
    let currentDataLines: string[] = []
    let eventReceived: boolean = false
    let terminalEvent: boolean = false
    let settled: boolean = false

    return new Promise<void>((resolve: () => void, reject: (reason: Error) => void) => {
      const finishRequest = (): void => {
        generation.clear()
        request.off('dataReceive')
        request.off('dataEnd')
        request.destroy()
      }

      generation.bind((): void => {
        if (settled) return
        settled = true
        finishRequest()
        reject(new Error(AiSseClient.CANCELLED_MESSAGE))
      })
      if (settled) return

      const fail = (message: string): void => {
        if (settled) return
        settled = true
        finishRequest()
        reject(new Error((eventReceived ? 'SSE_STARTED:' : '') + message))
      }

      const dispatchCurrent = (): void => {
        if (currentDataLines.length === 0) {
          currentEventName = 'message'
          return
        }
        const eventName: string = currentEventName
        const dataText: string = currentDataLines.join('\n')
        currentEventName = 'message'
        currentDataLines = []
        AiSseClient.dispatchEvent(eventName, dataText, listener, (): void => {
          terminalEvent = true
        })
      }

      const processLine = (rawLine: string): void => {
        let line: string = rawLine
        if (line.endsWith('\r')) {
          line = line.substring(0, line.length - 1)
        }
        if (line.length === 0) {
          dispatchCurrent()
          return
        }
        if (line.startsWith(':')) return
        if (line.startsWith('event:')) {
          if (currentDataLines.length > 0) {
            dispatchCurrent()
          }
          currentEventName = line.substring(6).trim()
          return
        }
        if (line.startsWith('data:')) {
          let value: string = line.substring(5)
          if (value.startsWith(' ')) value = value.substring(1)
          currentDataLines.push(value)
        }
      }

      const processText = (text: string): void => {
        if (text.length === 0) return
        lineBuffer += text
        let newlineIndex: number = lineBuffer.indexOf('\n')
        while (newlineIndex >= 0) {
          const line: string = lineBuffer.substring(0, newlineIndex)
          lineBuffer = lineBuffer.substring(newlineIndex + 1)
          processLine(line)
          newlineIndex = lineBuffer.indexOf('\n')
        }
      }

      request.on('dataReceive', (data: ArrayBuffer): void => {
        eventReceived = true
        ApiClient.activateBaseUrl(baseUrl)
        try {
          const decoded: string = decoder.decodeToString(new Uint8Array(data), { stream: true })
          processText(decoded)
        } catch (error) {
          hilog.error(AiSseClient.LOG_DOMAIN, AiSseClient.LOG_TAG,
            'decode failed message=%{public}s', error instanceof Error ? error.message : String(error))
          fail('麦麦AI流式数据解析失败，请重试')
        }
      })

      request.on('dataEnd', (): void => {
        if (settled) return
        try {
          const tail: string = decoder.decodeToString(new Uint8Array(0), { stream: false })
          processText(tail)
          if (lineBuffer.length > 0) {
            processLine(lineBuffer)
            lineBuffer = ''
          }
          dispatchCurrent()
        } catch (error) {
          fail('麦麦AI流式数据解析失败，请重试')
          return
        }
        if (!terminalEvent) {
          fail('麦麦AI流式连接提前结束')
          return
        }
        settled = true
        finishRequest()
        resolve()
      })

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Accept-Encoding': 'identity'
      }
      const loginToken: string = AppStorage.get<string>('login_token') ?? ''
      if (loginToken.length > 0) {
        headers['Authorization'] = 'Bearer ' + loginToken
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        extraData: JSON.stringify(body),
        header: headers,
        connectTimeout: 15000,
        readTimeout: 180000,
        usingCache: false,
        usingProtocol: http.HttpProtocol.HTTP1_1
      }

      const url: string = baseUrl + '/api/ai/chat'
      request.requestInStream(url, options).then((responseCode: number): void => {
        if (responseCode < 200 || responseCode >= 300) {
          fail('麦麦AI接口返回 ' + String(responseCode))
        }
      }).catch((error: BusinessError): void => {
        hilog.error(AiSseClient.LOG_DOMAIN, AiSseClient.LOG_TAG,
          'request failed code=%{public}d message=%{public}s', error.code, error.message)
        fail(error.message)
      })
    })
  }

  private static dispatchEvent(eventName: string, dataText: string, listener: AiSseListener, onTerminal: () => void): void {
    try {
      if (eventName === 'PERFORMANCE_CARD') {
        const raw: RawPerformanceCard = JSON.parse(dataText) as RawPerformanceCard
        listener.onPerformanceCard(AiSseClient.toCard(raw))
        return
      }
      const data: AiSseData = JSON.parse(dataText) as AiSseData
      if (eventName === 'TEXT') {
        listener.onText(data.text ?? '')
      } else if (eventName === 'DONE') {
        onTerminal()
        const context: AiSseDoneContext = {
          contextProjectId: AiSseClient.toId(data.contextProjectId),
          contextSessionId: AiSseClient.toId(data.contextSessionId),
          searchContext: AiSseClient.toSearchContext(data.searchContext),
          lastSearchResults: AiSseClient.toLastSearchResults(data.lastSearchResults),
          selectedProjectId: AiSseClient.toId(data.selectedProjectId),
          selectedSessionId: AiSseClient.toId(data.selectedSessionId),
          searchResultState: AiSseClient.toSearchResultState(data.searchResultState),
          entityContext: AiSseClient.toEntityContext(data.entityContext),
          activeSlot: data.activeSlot ?? 'NONE',
          capabilities: Array.isArray(data.capabilities) ? data.capabilities.map(String) : []
        }
        listener.onDone(context)
      } else if (eventName === 'ERROR') {
        onTerminal()
        listener.onError(data.message ?? '麦麦AI请求失败，请重试')
      }
    } catch (error) {
      hilog.error(AiSseClient.LOG_DOMAIN, AiSseClient.LOG_TAG,
        'dispatch parse failed event=%{public}s message=%{public}s',
        eventName, error instanceof Error ? error.message : String(error))
      onTerminal()
      listener.onError('麦麦AI流式数据解析失败，请重试')
    }
  }

  private static toCard(raw: RawPerformanceCard): AiPerformanceCardVO {
    const card: AiPerformanceCardVO = new AiPerformanceCardVO()
    card.projectId = AiSseClient.toId(raw.projectId)
    card.sessionId = AiSseClient.toId(raw.sessionId)
    card.title = raw.title ?? ''
    card.posterUrl = raw.posterUrl ?? ''
    card.categoryName = raw.categoryName ?? ''
    card.cityName = raw.cityName ?? ''
    card.venueName = raw.venueName ?? ''
    card.startTime = (raw.startTime ?? '').replace('T', ' ')
    card.minPrice = raw.minPrice
    card.maxPrice = raw.maxPrice
    return card
  }

  private static toSearchContext(raw: AiSearchContext | undefined): AiSearchContext {
    const context: AiSearchContext = new AiSearchContext()
    if (raw === undefined || raw === null) return context
    context.city = raw.city ?? ''
    context.category = raw.category ?? ''
    context.keyword = raw.keyword ?? ''
    context.venue = raw.venue ?? ''
    context.minPrice = raw.minPrice
    context.maxPrice = raw.maxPrice
    context.startTime = raw.startTime ?? ''
    context.endTime = raw.endTime ?? ''
    context.timeIntent = raw.timeIntent ?? ''
    context.sort = raw.sort ?? ''
    return context
  }

  private static toSearchResultState(raw: AiSearchResultState | undefined): AiSearchResultState {
    const state: AiSearchResultState = new AiSearchResultState()
    if (raw === undefined || raw === null) return state
    state.currentResultIds = Array.isArray(raw.currentResultIds) ? raw.currentResultIds.map(String) : []
    state.shownProjectIds = Array.isArray(raw.shownProjectIds) ? raw.shownProjectIds.map(String) : []
    state.offset = Number(raw.offset ?? 0)
    state.resultCount = Number(raw.resultCount ?? 0)
    state.hasMore = Boolean(raw.hasMore ?? false)
    return state
  }

  private static toEntityContext(raw: AiEntityContext | undefined): AiEntityContext {
    const context: AiEntityContext = new AiEntityContext()
    if (raw === undefined || raw === null) return context
    context.mentionedProjectId = AiSseClient.toId(raw.mentionedProjectId)
    context.comparedProjectIds = Array.isArray(raw.comparedProjectIds) ? raw.comparedProjectIds.map(String) : []
    context.city = raw.city ?? ''
    context.venue = raw.venue ?? ''
    context.venueId = AiSseClient.toId(raw.venueId)
    return context
  }

  private static toLastSearchResults(raw: RawLastSearchResult[] | undefined): AiLastSearchResult[] {
    if (!Array.isArray(raw)) return []
    return raw.map((value: RawLastSearchResult): AiLastSearchResult => {
      const result: AiLastSearchResult = new AiLastSearchResult()
      result.projectId = AiSseClient.toId(value.projectId)
      result.sessionId = AiSseClient.toId(value.sessionId)
      result.title = value.title ?? ''
      return result
    })
  }

  private static toId(value: string | number | null | undefined): string {
    return value === undefined || value === null ? '' : String(value)
  }
}
