export enum AiChatStatus {
  IDLE = 'IDLE',
  STREAMING = 'STREAMING',
  DONE = 'DONE',
  ERROR = 'ERROR',
  STOPPED = 'STOPPED'
}

export class AiPerformanceCardVO {
  projectId: string = ''
  sessionId: string = ''
  title: string = ''
  posterUrl: string = ''
  categoryName: string = ''
  cityName: string = ''
  venueName: string = ''
  startTime: string = ''
  minPrice?: number
  maxPrice?: number
}

export class AiSearchContext {
  city: string = ''
  category: string = ''
  keyword: string = ''
  venue: string = ''
  minPrice?: number
  maxPrice?: number
  startTime: string = ''
  endTime: string = ''
  timeIntent: string = ''
  sort: string = ''
}

export class AiSearchResultState {
  currentResultIds: string[] = []
  shownProjectIds: string[] = []
  offset: number = 0
  resultCount: number = 0
  hasMore: boolean = false
}

export class AiEntityContext {
  mentionedProjectId: string = ''
  comparedProjectIds: string[] = []
  city: string = ''
  venue: string = ''
  venueId: string = ''
}

export class AiLastSearchResult {
  projectId: string = ''
  sessionId: string = ''
  title: string = ''
}

export class AiChatMessageVO {
  id: string = ''
  role: string = ''
  content: string = ''
  cards: AiPerformanceCardVO[] = []
  status: AiChatStatus = AiChatStatus.DONE
  requestContextProjectId: string = ''
  requestContextSessionId: string = ''

  constructor(id: string = '', role: string = '', content: string = '',
              cards: AiPerformanceCardVO[] = [], status: AiChatStatus = AiChatStatus.DONE,
              requestContextProjectId: string = '', requestContextSessionId: string = '') {
    this.id = id
    this.role = role
    this.content = content
    this.cards = cards
    this.status = status
    this.requestContextProjectId = requestContextProjectId
    this.requestContextSessionId = requestContextSessionId
  }
}

export class AiConversation {
  id: string = ''
  title: string = ''
  createTime: number = 0
  updateTime: number = 0
  messages: AiChatMessageVO[] = []
  contextProjectId: string = ''
  contextSessionId: string = ''
  searchContext: AiSearchContext = new AiSearchContext()
  lastSearchResults: AiLastSearchResult[] = []
  selectedProjectId: string = ''
  selectedSessionId: string = ''
  searchResultState: AiSearchResultState = new AiSearchResultState()
  entityContext: AiEntityContext = new AiEntityContext()
  activeSlot: string = 'NONE'
  capabilities: string[] = []

  constructor(id: string = '', title: string = '', createTime: number = 0, updateTime: number = 0,
              messages: AiChatMessageVO[] = [], contextProjectId: string = '', contextSessionId: string = '',
              searchContext: AiSearchContext = new AiSearchContext(), lastSearchResults: AiLastSearchResult[] = [],
              selectedProjectId: string = '', selectedSessionId: string = '',
              searchResultState: AiSearchResultState = new AiSearchResultState(),
              entityContext: AiEntityContext = new AiEntityContext(), activeSlot: string = 'NONE',
              capabilities: string[] = []) {
    this.id = id
    this.title = title
    this.createTime = createTime
    this.updateTime = updateTime
    this.messages = messages
    this.contextProjectId = contextProjectId
    this.contextSessionId = contextSessionId
    this.searchContext = searchContext
    this.lastSearchResults = lastSearchResults
    this.selectedProjectId = selectedProjectId
    this.selectedSessionId = selectedSessionId
    this.searchResultState = searchResultState
    this.entityContext = entityContext
    this.activeSlot = activeSlot
    this.capabilities = capabilities
  }
}

export interface AiChatRequestMessage {
  role: string
  content: string
}

export interface AiChatRequestBody {
  messages: AiChatRequestMessage[]
  contextProjectId?: number
  contextSessionId?: number
  currentCity?: string
  searchContext?: AiSearchContext
  lastSearchResults?: AiLastSearchResult[]
  selectedProjectId?: number
  selectedSessionId?: number
  searchResultState?: AiSearchResultState
  entityContext?: AiEntityContext
  activeSlot?: string
  conversationId?: string
}

export interface AiSseDoneContext {
  contextProjectId: string
  contextSessionId: string
  searchContext: AiSearchContext
  lastSearchResults: AiLastSearchResult[]
  selectedProjectId: string
  selectedSessionId: string
  searchResultState: AiSearchResultState
  entityContext: AiEntityContext
  activeSlot: string
  capabilities: string[]
}

export interface AiSseListener {
  onText: (text: string) => void
  onPerformanceCard: (card: AiPerformanceCardVO) => void
  onDone: (context: AiSseDoneContext) => void
  onError: (message: string) => void
}
