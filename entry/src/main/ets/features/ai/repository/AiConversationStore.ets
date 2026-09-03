import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import {
  AiChatMessageVO,
  AiChatStatus,
  AiConversation,
  AiEntityContext,
  AiLastSearchResult,
  AiPerformanceCardVO,
  AiSearchContext,
  AiSearchResultState
} from '../model/AiChatVO'

const STORE_NAME: string = 'ai_conversation_store'
const KEY_CONVERSATIONS: string = 'ai_conversations'
const KEY_ACTIVE_CONVERSATION_ID: string = 'ai_active_conversation_id'

export class AiConversationStore {
  static load(context: common.Context): AiConversation[] {
    try {
      const store: preferences.Preferences = AiConversationStore.getStore(context)
      const raw: string = String(store.getSync(KEY_CONVERSATIONS, ''))
      if (raw.length === 0) return []
      const values: AiConversation[] = JSON.parse(raw) as AiConversation[]
      return values.map((value: AiConversation): AiConversation => AiConversationStore.normalizeConversation(value))
        .filter((value: AiConversation): boolean => value.messages.some(
          (message: AiChatMessageVO): boolean => message.role === 'user'))
        .sort((left: AiConversation, right: AiConversation): number => right.updateTime - left.updateTime)
    } catch (error) {
      return []
    }
  }

  static save(context: common.Context, conversations: AiConversation[], activeConversationId: string): void {
    try {
      const store: preferences.Preferences = AiConversationStore.getStore(context)
      store.putSync(KEY_CONVERSATIONS, JSON.stringify(conversations))
      store.putSync(KEY_ACTIVE_CONVERSATION_ID, activeConversationId)
      store.flushSync()
    } catch (error) {
    }
  }

  static getActiveConversationId(context: common.Context): string {
    try {
      return String(AiConversationStore.getStore(context).getSync(KEY_ACTIVE_CONVERSATION_ID, ''))
    } catch (error) {
      return ''
    }
  }

  private static normalizeConversation(value: AiConversation): AiConversation {
    const messages: AiChatMessageVO[] = Array.isArray(value.messages) ? value.messages.map(
      (message: AiChatMessageVO): AiChatMessageVO => AiConversationStore.normalizeMessage(message)) : []
    const createTime: number = Number(value.createTime ?? Date.now())
    const updateTime: number = Number(value.updateTime ?? createTime)
    const rawResults: AiLastSearchResult[] = Array.isArray(value.lastSearchResults) ? value.lastSearchResults : []
    const lastSearchResults: AiLastSearchResult[] = rawResults.map(
      (item: AiLastSearchResult): AiLastSearchResult => AiConversationStore.normalizeLastSearchResult(item))
    return new AiConversation(
      String(value.id ?? ''),
      String(value.title ?? ''),
      createTime,
      updateTime,
      messages,
      String(value.contextProjectId ?? ''),
      String(value.contextSessionId ?? ''),
      AiConversationStore.normalizeSearchContext(value.searchContext),
      lastSearchResults,
      String(value.selectedProjectId ?? ''),
      String(value.selectedSessionId ?? ''),
      AiConversationStore.normalizeSearchResultState(value.searchResultState),
      AiConversationStore.normalizeEntityContext(value.entityContext),
      String(value.activeSlot ?? 'NONE'),
      Array.isArray(value.capabilities) ? value.capabilities.map(String) : []
    )
  }

  private static normalizeMessage(value: AiChatMessageVO): AiChatMessageVO {
    const cards: AiPerformanceCardVO[] = Array.isArray(value.cards) ? value.cards.map(
      (card: AiPerformanceCardVO): AiPerformanceCardVO => AiConversationStore.normalizeCard(card)) : []
    const rawStatus: string = String(value.status ?? AiChatStatus.DONE)
    const status: AiChatStatus = rawStatus === AiChatStatus.STREAMING ? AiChatStatus.STOPPED :
      AiConversationStore.toStatus(rawStatus)
    return new AiChatMessageVO(
      String(value.id ?? ''),
      String(value.role ?? ''),
      String(value.content ?? ''),
      cards,
      status,
      String(value.requestContextProjectId ?? ''),
      String(value.requestContextSessionId ?? '')
    )
  }

  private static normalizeCard(value: AiPerformanceCardVO): AiPerformanceCardVO {
    const card: AiPerformanceCardVO = new AiPerformanceCardVO()
    card.projectId = String(value.projectId ?? '')
    card.sessionId = String(value.sessionId ?? '')
    card.title = String(value.title ?? '')
    card.posterUrl = String(value.posterUrl ?? '')
    card.categoryName = String(value.categoryName ?? '')
    card.cityName = String(value.cityName ?? '')
    card.venueName = String(value.venueName ?? '')
    card.startTime = String(value.startTime ?? '')
    card.minPrice = value.minPrice
    card.maxPrice = value.maxPrice
    return card
  }

  private static normalizeSearchContext(value: AiSearchContext | undefined): AiSearchContext {
    const context: AiSearchContext = new AiSearchContext()
    if (value === undefined || value === null) return context
    context.city = String(value.city ?? '')
    context.category = String(value.category ?? '')
    context.keyword = String(value.keyword ?? '')
    context.venue = String(value.venue ?? '')
    context.minPrice = value.minPrice
    context.maxPrice = value.maxPrice
    context.startTime = String(value.startTime ?? '')
    context.endTime = String(value.endTime ?? '')
    context.timeIntent = String(value.timeIntent ?? '')
    context.sort = String(value.sort ?? '')
    return context
  }

  private static normalizeSearchResultState(value: AiSearchResultState | undefined): AiSearchResultState {
    const state: AiSearchResultState = new AiSearchResultState()
    if (value === undefined || value === null) return state
    state.currentResultIds = Array.isArray(value.currentResultIds) ? value.currentResultIds.map(String) : []
    state.shownProjectIds = Array.isArray(value.shownProjectIds) ? value.shownProjectIds.map(String) : []
    state.offset = Number(value.offset ?? 0)
    state.resultCount = Number(value.resultCount ?? 0)
    state.hasMore = Boolean(value.hasMore ?? false)
    return state
  }

  private static normalizeEntityContext(value: AiEntityContext | undefined): AiEntityContext {
    const context: AiEntityContext = new AiEntityContext()
    if (value === undefined || value === null) return context
    context.mentionedProjectId = String(value.mentionedProjectId ?? '')
    context.comparedProjectIds = Array.isArray(value.comparedProjectIds) ? value.comparedProjectIds.map(String) : []
    context.city = String(value.city ?? '')
    context.venue = String(value.venue ?? '')
    context.venueId = String(value.venueId ?? '')
    return context
  }

  private static normalizeLastSearchResult(value: AiLastSearchResult): AiLastSearchResult {
    const result: AiLastSearchResult = new AiLastSearchResult()
    result.projectId = String(value.projectId ?? '')
    result.sessionId = String(value.sessionId ?? '')
    result.title = String(value.title ?? '')
    return result
  }

  private static toStatus(value: string): AiChatStatus {
    if (value === AiChatStatus.ERROR) return AiChatStatus.ERROR
    if (value === AiChatStatus.STOPPED) return AiChatStatus.STOPPED
    if (value === AiChatStatus.IDLE) return AiChatStatus.IDLE
    if (value === AiChatStatus.STREAMING) return AiChatStatus.STREAMING
    return AiChatStatus.DONE
  }

  private static getStore(context: common.Context): preferences.Preferences {
    return preferences.getPreferencesSync(context, { name: STORE_NAME })
  }
}
