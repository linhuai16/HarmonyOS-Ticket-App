import { AiSseClient, AiSseGeneration } from '../network/AiSseClient'
import {
  AiChatMessageVO,
  AiChatRequestBody,
  AiChatRequestMessage,
  AiChatStatus,
  AiConversation,
  AiEntityContext,
  AiLastSearchResult,
  AiPerformanceCardVO,
  AiSearchContext,
  AiSearchResultState,
  AiSseDoneContext,
  AiSseListener
} from '../model/AiChatVO'
import { AiConversationStore } from '../repository/AiConversationStore'
import { AiPerformanceCard } from '../components/AiPerformanceCard'
import { AiMarkdownText } from '../components/AiMarkdownText'
import { AiEmptyState, AiHistoryPanel, AiInputToolbar } from '../components/AiChatSections'
import { WindowImmersiveUtil } from '../../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../../common/ResponsiveLayout'
import { CityRepository } from '../../../repository/CityRepository'
import { common } from '@kit.AbilityKit'
import { KeyboardAvoidMode, window } from '@kit.ArkUI'

interface AiRetryPopupState {
  isVisible: boolean
}

@Component
export struct AiChatPage {
  private messageScroller: Scroller = new Scroller()
  private pendingCards: AiPerformanceCardVO[] = []
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET
  private keyboardAvoidModeCaptured: boolean = false
  private historyLoaded: boolean = false
  private activeGeneration: AiSseGeneration | undefined = undefined
  private generationSequence: number = 0
  private currentCreateTime: number = 0
  private currentUpdateTime: number = 0
  private keyboardWindow: window.Window | undefined = undefined
  private keyboardListenerRegistered: boolean = false
  private keyboardListenerPending: boolean = false
  private retryLongPressHandled: boolean = false
  private retryTooltipTimer: number = -1
  private followLatest: boolean = true
  private followScrollPending: boolean = false
  private readonly cityRepository: CityRepository = new CityRepository()
  private searchContext: AiSearchContext = new AiSearchContext()
  private lastSearchResults: AiLastSearchResult[] = []
  private selectedProjectId: string = ''
  private selectedSessionId: string = ''
  private searchResultState: AiSearchResultState = new AiSearchResultState()
  private entityContext: AiEntityContext = new AiEntityContext()
  private activeSlot: string = 'NONE'
  private supportedCapabilities: string[] = []
  private keyboardHeightChangeCallback: (height: number) => void = (height: number): void => {
    this.aiKeyboardVisible = height > 0
  }
  @State messages: AiChatMessageVO[] = []
  @State conversations: AiConversation[] = []
  @State currentConversationId: string = ''
  @State inputText: string = ''
  @State status: AiChatStatus = AiChatStatus.IDLE
  @State contextProjectId: string = ''
  @State contextSessionId: string = ''
  @State lastFailedText: string = ''
  @State suggestedPrompts: string[] = []
  @State retryTooltipVisible: boolean = false
  @State contentWidth: number = 0
  @State workspaceWidth: number = 0
  @StorageLink('current_city') @Watch('onCurrentCityChanged') currentCity: string = ''
  @StorageLink('ai_keyboard_visible') aiKeyboardVisible: boolean = false
  @StorageLink('ai_history_visible') historyVisible: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
    if (!this.keyboardAvoidModeCaptured) {
      this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode()
      this.keyboardAvoidModeCaptured = true
    }
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
    this.loadHistory()
    this.registerKeyboardListener()
  }

  onPageShow(): void {
    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
    this.registerKeyboardListener()
  }

  onPageHide(): void {
    this.hideRetryTooltip()
    this.flushCurrentConversation()
    this.unregisterKeyboardListener()
    this.restoreKeyboardAvoidMode()
  }

  aboutToDisappear(): void {
    this.hideRetryTooltip()
    this.flushCurrentConversation()
    this.unregisterKeyboardListener()
    this.restoreKeyboardAvoidMode()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        if (this.isWideLayout()) {
          this.HistoryPanel(true)
        }
        this.ChatWorkspace()
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Top)

      if (!this.isWideLayout() && this.historyVisible) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .onClick(() => {
            this.historyVisible = false
          })
        this.HistoryPanel(false)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width: number = Number(newValue.width ?? 0)
      if (Math.abs(width - this.contentWidth) > 0.5) {
        if (ResponsiveLayout.isWideWidth(width) !== ResponsiveLayout.isWideWidth(this.contentWidth)) {
          this.historyVisible = false
        }
        this.contentWidth = width
      }
    })
  }

  @Builder
  private ChatWorkspace() {
    Column() {
      this.Header()
      Column() {
        if (this.messages.length === 0) {
          this.EmptyState()
        } else {
          this.MessageList()
        }
        this.InputBar()
      }
      .layoutWeight(1)
      .width('100%')
      .constraintSize({ maxWidth: ResponsiveLayout.READABLE_MAX_WIDTH })
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const width: number = Number(newValue.width ?? 0)
        if (Math.abs(width - this.workspaceWidth) > 0.5) {
          this.workspaceWidth = width
        }
      })
    }
    .layoutWeight(1)
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private Header() {
    Row() {
      if (!this.isWideLayout()) {
        Button('历史')
          .width(this.isTabletLayout() ? 84 : 68)
          .height(38)
          .fontSize(this.isTabletLayout() ? 15 : 14)
          .fontColor(this.status === AiChatStatus.STREAMING ? '#AAAAAA' : '#333333')
          .backgroundColor('#F2F3F5')
          .enabled(this.status !== AiChatStatus.STREAMING)
          .onClick(() => {
            this.historyVisible = true
          })
      } else {
        Blank().width(104)
      }
      Column() {
        Text('麦麦AI')
          .fontSize(this.isTabletLayout() ? 22 : 20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
        Text('真实麦麦票务数据')
          .fontSize(11)
          .fontColor('#888888')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      Button('新对话 +')
        .width(this.isTabletLayout() ? 104 : 88)
        .height(38)
        .fontSize(this.isTabletLayout() ? 15 : 13)
        .fontColor(this.status === AiChatStatus.STREAMING ? '#AAAAAA' : '#1677FF')
        .backgroundColor('#EEF5FF')
        .enabled(this.status !== AiChatStatus.STREAMING)
        .onClick(() => {
          this.startNewConversation()
        })
    }
    .width('100%')
    .height(this.isTabletLayout() ? 70 : 62)
    .padding({ left: this.isTabletLayout() ? 28 : 12, right: this.isTabletLayout() ? 28 : 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#EAEAEA' })
  }

  @Builder
  private EmptyState() {
    AiEmptyState({
      tablet: this.isTabletLayout(),
      cityPrompt: this.defaultCityPrompt(),
      onSend: (text: string): void => {
        this.sendText(text)
      }
    })
  }

  @Builder
  private MessageList() {
    List({ scroller: this.messageScroller, space: 14 }) {
      ForEach(this.messages, (item: AiChatMessageVO) => {
        ListItem() {
          this.MessageItem(item)
        }
      }, (item: AiChatMessageVO) => item.id + '_' + String(item.content.length) + '_' +
        String(item.cards.length) + '_' + item.status)
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ left: this.isTabletLayout() ? 24 : 12, right: this.isTabletLayout() ? 24 : 12,
      top: 18, bottom: 18 })
    .edgeEffect(EdgeEffect.Spring)
    .onDidScroll(() => {
      this.hideRetryTooltip()
      this.followLatest = this.messageScroller.isAtEnd()
    })
    .onReachEnd(() => {
      this.followLatest = true
    })
  }

  @Builder
  private RetryTooltip() {
    Row() {
      Text('重试')
        .fontSize(12)
        .fontColor('#4A4F55')
    }
    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    .backgroundColor('#F4F5F6')
    .border({ width: 1, color: '#E6E8EB' })
    .borderRadius(7)
  }

  @Builder
  private MessageItem(item: AiChatMessageVO) {
    if (item.role === 'user') {
      Row() {
        Blank()
        Text(item.content)
          .fontSize(this.isTabletLayout() ? 16 : 15)
          .fontColor('#FFFFFF')
          .lineHeight(this.isTabletLayout() ? 24 : 22)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .constraintSize({ maxWidth: this.isTabletLayout() ? 620 : '82%' })
          .backgroundColor('#1677FF')
          .borderRadius(14)
      }
      .width('100%')
    } else {
      Column() {
        Row() {
          Text('麦').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        }
        .width(32)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#E33B3B')
        .borderRadius(16)
        if (item.content.length > 0) {
          AiMarkdownText({ content: item.content, tablet: this.isTabletLayout() })
            .width('100%')
            .margin({ top: 8 })
        } else if (item.status === AiChatStatus.STREAMING) {
          Text('正在查询麦麦票务数据…').fontSize(14).fontColor('#888888').margin({ top: 8 })
        }
        if (item.cards.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(item.cards, (card: AiPerformanceCardVO) => {
              AiPerformanceCard({
                item: card,
                wide: this.useRoomyResultCard(),
                onOpen: (selected: AiPerformanceCardVO): void => {
                  this.contextProjectId = selected.projectId
                  this.contextSessionId = selected.sessionId
                  this.selectedProjectId = selected.projectId
                  this.selectedSessionId = selected.sessionId
                  this.currentUpdateTime = Date.now()
                  this.flushCurrentConversation()
                }
              })
                .width(this.useTwoColumnResultCards() && item.cards.length > 1 ? 'calc(50% - 8vp)' : '100%')
                .margin({ top: 12 })
            }, (card: AiPerformanceCardVO) => card.projectId + '_' + card.sessionId)
          }
          .width('100%')
        }
        if (item.status === AiChatStatus.ERROR) {
          Text('请求失败').fontSize(13).fontColor('#E33B3B').margin({ top: 10 })
        } else if (item.status === AiChatStatus.STOPPED) {
          Text('已停止生成').fontSize(13).fontColor('#888888').margin({ top: 10 })
        }
        if (this.canRegenerate(item)) {
          Button() {
            Image($r('app.media.refrech'))
              .width(18)
              .height(18)
              .fillColor('#666666')
          }
            .width(36)
            .height(32)
            .backgroundColor('#00000000')
            .borderRadius(16)
            .margin({ top: 10 })
            .onClick(() => {
              if (this.retryLongPressHandled) {
                this.retryLongPressHandled = false
                return
              }
              this.regenerateLatest()
            })
            .gesture(
              LongPressGesture({ repeat: false, duration: 500 })
                .onAction(() => {
                  this.retryLongPressHandled = true
                  this.showRetryTooltip()
                })
                .onActionEnd(() => {
                  setTimeout((): void => {
                    this.retryLongPressHandled = false
                  }, 200)
                })
            )
            .bindPopup(this.retryTooltipVisible, {
              builder: this.RetryTooltip,
              placement: Placement.Bottom,
              popupColor: '#00000000',
              enableArrow: false,
              autoCancel: true,
              mask: false,
              showInSubWindow: false,
              offset: { x: 0, y: 4 },
              onStateChange: (event: AiRetryPopupState): void => {
                this.retryTooltipVisible = event.isVisible
              }
            })
        }
        if (this.shouldShowSuggestions(item)) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.suggestedPrompts, (prompt: string) => {
              Button() {
                Text(prompt)
                  .fontSize(13)
                  .fontColor('#1677FF')
                  .maxLines(2)
                  .textAlign(TextAlign.Center)
                }
                .constraintSize({ minHeight: 38, maxWidth: this.isTabletLayout() ? 260 : 230 })
                .padding({ left: 13, right: 13, top: 8, bottom: 8 })
                .backgroundColor('#F4F8FF')
                .border({ width: 1, color: '#D8E8FF' })
                .margin({ right: 8, top: 8 })
                .onClick(() => {
                  this.sendSuggestedPrompt(prompt)
                })
            }, (prompt: string) => prompt)
          }
          .width('100%')
          .margin({ top: 4 })
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: this.isTabletLayout() ? 760 : '92%' })
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
    }
  }

  @Builder
  private InputBar() {
    AiInputToolbar({
      inputText: this.inputText,
      status: this.status,
      tablet: this.isTabletLayout(),
      onInput: (text: string): void => {
        this.inputText = text
      },
      onSend: (text: string): void => {
        this.inputText = ''
        this.sendText(text)
      },
      onStop: (): void => {
        this.stopGeneration()
      }
    })
  }

  @Builder
  private HistoryPanel(persistent: boolean) {
    AiHistoryPanel({
      persistent: persistent,
      conversations: this.conversations,
      currentConversationId: this.currentConversationId,
      panelWidth: this.historyPanelWidth(),
      onClose: (): void => {
        this.historyVisible = false
      },
      onOpen: (id: string): void => {
        this.openConversation(id)
      },
      onDelete: (id: string): void => {
        this.showDeleteConversationDialog(id)
      }
    })
  }

  private async sendText(text: string): Promise<void> {
    const value: string = text.trim()
    if (value.length === 0 || this.status === AiChatStatus.STREAMING) return
    if (this.inputText.trim() === value) this.inputText = ''
    this.ensureCurrentConversation(value)
    const sequence: string = String(Date.now()) + '_' + String(this.messages.length)
    const userMessage: AiChatMessageVO = new AiChatMessageVO('user_' + sequence, 'user', value)
    const assistantId: string = 'assistant_' + sequence
    const assistantMessage: AiChatMessageVO = new AiChatMessageVO(
      assistantId, 'assistant', '', [], AiChatStatus.STREAMING, this.contextProjectId, this.contextSessionId)
    this.pendingCards = []
    this.suggestedPrompts = []
    this.messages = this.messages.concat([userMessage, assistantMessage])
    this.status = AiChatStatus.STREAMING
    this.followLatest = true
    this.lastFailedText = value
    this.currentUpdateTime = Date.now()
    this.scrollToLatest()
    await this.streamAssistant(assistantId, this.contextProjectId, this.contextSessionId)
  }

  private async regenerateLatest(): Promise<void> {
    if (this.status === AiChatStatus.STREAMING) return
    const assistantIndex: number = this.findLatestAssistantIndex()
    if (assistantIndex <= 0) return
    const assistant: AiChatMessageVO = this.messages[assistantIndex]
    const userMessage: AiChatMessageVO = this.messages[assistantIndex - 1]
    if (userMessage.role !== 'user') return
    const requestProjectId: string = assistant.requestContextProjectId
    const requestSessionId: string = assistant.requestContextSessionId
    const replacement: AiChatMessageVO = new AiChatMessageVO(
      assistant.id, 'assistant', '', [], AiChatStatus.STREAMING, requestProjectId, requestSessionId)
    this.messages = this.messages.map((item: AiChatMessageVO, index: number): AiChatMessageVO =>
      index === assistantIndex ? replacement : item)
    this.contextProjectId = requestProjectId
    this.contextSessionId = requestSessionId
    this.pendingCards = []
    this.suggestedPrompts = []
    this.status = AiChatStatus.STREAMING
    this.followLatest = true
    this.lastFailedText = userMessage.content
    this.currentUpdateTime = Date.now()
    this.scrollToLatest()
    await this.streamAssistant(assistant.id, requestProjectId, requestSessionId)
  }

  private async streamAssistant(assistantId: string, requestProjectId: string,
                                requestSessionId: string): Promise<void> {
    const history: AiChatRequestMessage[] = this.messages
      .filter((item: AiChatMessageVO): boolean => item.id !== assistantId && item.content.trim().length > 0)
      .map((item: AiChatMessageVO): AiChatRequestMessage => {
        return { role: item.role, content: item.content }
      })
    const body: AiChatRequestBody = {
      messages: history,
      currentCity: this.effectiveConversationCity(),
      searchContext: this.searchContext,
      lastSearchResults: this.lastSearchResults,
      searchResultState: this.searchResultState,
      entityContext: this.entityContext,
      activeSlot: this.activeSlot,
      conversationId: this.currentConversationId
    }
    if (requestProjectId.length > 0) body.contextProjectId = Number(requestProjectId)
    if (requestSessionId.length > 0) body.contextSessionId = Number(requestSessionId)
    if (this.selectedProjectId.length > 0) body.selectedProjectId = Number(this.selectedProjectId)
    if (this.selectedSessionId.length > 0) body.selectedSessionId = Number(this.selectedSessionId)
    const generation: AiSseGeneration = new AiSseGeneration()
    const sequence: number = ++this.generationSequence
    const conversationId: string = this.currentConversationId
    this.activeGeneration = generation
    const listener: AiSseListener = {
      onText: (chunk: string): void => {
        if (!this.isActiveGeneration(sequence, conversationId, assistantId)) return
        this.getUIContext().runScopedTask((): void => {
          if (!this.isActiveGeneration(sequence, conversationId, assistantId)) return
          this.appendText(assistantId, chunk)
        })
      },
      onPerformanceCard: (card: AiPerformanceCardVO): void => {
        if (!this.isActiveGeneration(sequence, conversationId, assistantId)) return
        this.bufferCard(card)
      },
      onDone: (doneContext: AiSseDoneContext): void => {
        if (!this.isActiveGeneration(sequence, conversationId, assistantId)) return
        this.contextProjectId = doneContext.contextProjectId
        this.contextSessionId = doneContext.contextSessionId
        this.searchContext = doneContext.searchContext
        this.lastSearchResults = doneContext.lastSearchResults
        this.selectedProjectId = doneContext.selectedProjectId
        this.selectedSessionId = doneContext.selectedSessionId
        this.searchResultState = doneContext.searchResultState
        this.entityContext = doneContext.entityContext
        this.activeSlot = doneContext.activeSlot
        this.supportedCapabilities = doneContext.capabilities
        const cards: AiPerformanceCardVO[] = this.completeMessage(assistantId)
        this.status = AiChatStatus.DONE
        this.suggestedPrompts = this.buildSuggestedPrompts(cards)
        this.currentUpdateTime = Date.now()
        this.persistCurrentConversation()
        this.followLatestIfNeeded()
      },
      onError: (message: string): void => {
        if (!this.isActiveGeneration(sequence, conversationId, assistantId)) return
        this.appendError(assistantId, message)
      }
    }
    try {
      await AiSseClient.stream(body, listener, generation)
    } catch (error) {
      const streamError: Error = error instanceof Error ? error : new Error(String(error))
      if (AiSseClient.isCancellation(streamError)) return
      if (!this.isActiveGeneration(sequence, conversationId, assistantId)) return
      this.appendError(assistantId, streamError.message)
    } finally {
      if (this.generationSequence === sequence) this.activeGeneration = undefined
    }
  }

  private stopGeneration(): void {
    if (this.status !== AiChatStatus.STREAMING) return
    const assistantIndex: number = this.findLatestAssistantIndex()
    const generation: AiSseGeneration | undefined = this.activeGeneration
    this.generationSequence++
    this.activeGeneration = undefined
    if (generation !== undefined) generation.cancel()
    this.pendingCards = []
    this.suggestedPrompts = []
    if (assistantIndex >= 0) {
      this.messages = this.messages.map((item: AiChatMessageVO, index: number): AiChatMessageVO => {
        if (index !== assistantIndex) return item
        return new AiChatMessageVO(item.id, item.role, item.content, item.cards, AiChatStatus.STOPPED,
          item.requestContextProjectId, item.requestContextSessionId)
      })
    }
    this.status = AiChatStatus.STOPPED
    this.currentUpdateTime = Date.now()
    this.persistCurrentConversation()
  }

  private appendText(messageId: string, chunk: string): void {
    if (chunk.length === 0) return
    this.updateMessage(messageId, (item: AiChatMessageVO): AiChatMessageVO => {
      return new AiChatMessageVO(item.id, item.role, item.content + chunk, item.cards, AiChatStatus.STREAMING,
        item.requestContextProjectId, item.requestContextSessionId)
    })
    this.followLatestIfNeeded()
  }

  private bufferCard(card: AiPerformanceCardVO): void {
    const exists: boolean = this.pendingCards.some((value: AiPerformanceCardVO): boolean =>
      value.projectId === card.projectId && value.sessionId === card.sessionId)
    if (!exists) this.pendingCards = this.pendingCards.concat([card])
  }

  private completeMessage(messageId: string): AiPerformanceCardVO[] {
    const cards: AiPerformanceCardVO[] = this.pendingCards
    this.pendingCards = []
    this.updateMessage(messageId, (item: AiChatMessageVO): AiChatMessageVO => {
      return new AiChatMessageVO(item.id, item.role, item.content, cards, AiChatStatus.DONE,
        item.requestContextProjectId, item.requestContextSessionId)
    })
    this.followLatestIfNeeded()
    return cards
  }

  private appendError(messageId: string, message: string): void {
    this.pendingCards = []
    this.suggestedPrompts = []
    this.updateMessage(messageId, (item: AiChatMessageVO): AiChatMessageVO => {
      const content: string = item.content.length > 0 ? item.content :
        (message.length > 0 ? message : '麦麦AI请求失败，请重试')
      return new AiChatMessageVO(item.id, item.role, content, item.cards, AiChatStatus.ERROR,
        item.requestContextProjectId, item.requestContextSessionId)
    })
    this.status = AiChatStatus.ERROR
    this.currentUpdateTime = Date.now()
    this.persistCurrentConversation()
    this.scrollToLatest()
  }

  private updateMessage(messageId: string, updater: (item: AiChatMessageVO) => AiChatMessageVO): void {
    this.messages = this.messages.map((item: AiChatMessageVO): AiChatMessageVO =>
      item.id === messageId ? updater(item) : item)
  }

  private buildSuggestedPrompts(cards: AiPerformanceCardVO[]): string[] {
    if (this.supportedCapabilities.length === 0) return []
    if (cards.length === 0 && this.lastSearchResults.length === 0 && this.hasSearchContext()) {
      const city: string = this.effectiveConversationCity()
      const allPerformances: string = city.length > 0 ? '查看' + city + '全部演出' : '查看全部演出'
      const recovery: string[] = this.supportsCapability('VIEW_ALL_RESULTS') ? [allPerformances] : []
      if (this.supportsCapability('BROADEN_TIME') && this.canBroadenTime()) recovery.push('放宽时间范围')
      if (this.supportsCapability('CLEAR_CATEGORY')) recovery.push('不限分类')
      if (this.supportsCapability('CLEAR_PRICE')) recovery.push('不限价格')
      if (this.supportsCapability('CLEAR_VENUE')) recovery.push('不限场馆')
      if (this.supportsCapability('CLEAR_KEYWORD')) recovery.push('不限关键词')
      return this.rankSuggestedPrompts(recovery, 3)
    }
    const resultCount: number = Math.max(cards.length, this.lastSearchResults.length)
    if (resultCount === 0 && this.selectedProjectId.length === 0 && this.selectedSessionId.length === 0) return []
    const selected: boolean = this.selectedProjectId.length > 0 || this.selectedSessionId.length > 0
    const refundContext: boolean = this.hasRecentRefundTopic()
    const discoveryCandidates: string[] = this.supportsCapability('CONTINUE_RESULTS')
      ? ['继续看更多', this.citySuggestedPrompt('最近一周有什么演出'), '看看这个周末', '看看其他类型']
      : [this.citySuggestedPrompt('最近一周有什么演出'), '看看这个周末', '500元以内有什么', '看看其他类型']
    const discovery: string = this.pickSuggestedPrompt(discoveryCandidates)
    const sorting: string = this.supportsCapability('CHANGE_SORT')
      ? this.pickSuggestedPrompt(['按价格从低到高', '按时间最近的看', '不限价格']) : ''
    const detail: string = !this.supportsCapability('QUERY_SESSION') ? '' : selected
      ? this.pickSuggestedPrompt(['查看场次', '查看票档', '还有票吗'])
      : resultCount > 1
        ? this.pickSuggestedPrompt(['查看第一个场次', '第一个和第二个哪个便宜', '第一个还有票吗'])
        : this.pickSuggestedPrompt(['查看场次', '查看票档', '还有票吗'])
    const refund: string = !this.supportsCapability('QUERY_REFUND') ? '' : this.pickSuggestedPrompt(selected
      ? ['查看退款规则', '这个演出能退吗']
      : ['查看其他可退演出', '第一个能退吗', '查看退款规则'])
    const prompts: string[] = []
    this.appendSuggestedPrompt(prompts, discovery)
    if (refundContext || selected) {
      this.appendSuggestedPrompt(prompts, detail)
      this.appendSuggestedPrompt(prompts, refund)
    } else {
      this.appendSuggestedPrompt(prompts, sorting)
      this.appendSuggestedPrompt(prompts, detail)
    }
    return prompts
  }

  private showRetryTooltip(): void {
    if (this.retryTooltipTimer >= 0) clearTimeout(this.retryTooltipTimer)
    this.retryTooltipVisible = true
    this.retryTooltipTimer = setTimeout((): void => {
      this.retryTooltipVisible = false
      this.retryTooltipTimer = -1
    }, 1300)
  }

  private hideRetryTooltip(): void {
    if (!this.retryTooltipVisible && this.retryTooltipTimer < 0) return
    this.retryTooltipVisible = false
    if (this.retryTooltipTimer >= 0) clearTimeout(this.retryTooltipTimer)
    this.retryTooltipTimer = -1
  }

  private appendSuggestedPrompt(values: string[], prompt: string): void {
    if (prompt.length > 0 && values.length < 3 && !values.includes(prompt)) values.push(prompt)
  }

  private pickSuggestedPrompt(candidates: string[]): string {
    const recent: string[] = this.recentUserTexts(2)
    const latestKey: string = recent.length > 0 ? this.suggestionKey(recent[0]) : ''
    const previousKey: string = recent.length > 1 ? this.suggestionKey(recent[1]) : ''
    let previousCandidate: string = ''
    for (const candidate of candidates) {
      const key: string = this.suggestionKey(candidate)
      if (key.length > 0 && key === latestKey) continue
      if (key.length > 0 && key === previousKey) {
        if (previousCandidate.length === 0) previousCandidate = candidate
        continue
      }
      return candidate
    }
    return previousCandidate
  }

  private rankSuggestedPrompts(candidates: string[], limit: number): string[] {
    const recent: string[] = this.recentUserTexts(2)
    const latestKey: string = recent.length > 0 ? this.suggestionKey(recent[0]) : ''
    const previousKey: string = recent.length > 1 ? this.suggestionKey(recent[1]) : ''
    const fresh: string[] = []
    const previous: string[] = []
    for (const candidate of candidates) {
      const key: string = this.suggestionKey(candidate)
      if (key.length > 0 && key === latestKey) continue
      if (key.length > 0 && key === previousKey) previous.push(candidate)
      else fresh.push(candidate)
    }
    return fresh.concat(previous).slice(0, limit)
  }

  private recentUserTexts(limit: number): string[] {
    const values: string[] = []
    for (let index: number = this.messages.length - 1; index >= 0 && values.length < limit; index--) {
      if (this.messages[index].role === 'user') values.push(this.messages[index].content)
    }
    return values
  }

  private hasRecentRefundTopic(): boolean {
    return this.recentUserTexts(2).some((value: string): boolean =>
      value.includes('退款') || value.includes('退票') || value.includes('能退') || value.includes('可退'))
  }

  private suggestionKey(value: string): string {
    if (value.includes('其他') && (value.includes('能退') || value.includes('可退'))) return 'refund_other'
    if (value.includes('退款规则')) return 'refund_rule'
    if (value.includes('能退') || value.includes('可退') || value.includes('退票')) return 'refund_check'
    if (value.includes('第一个') && value.includes('第二个') &&
      (value.includes('便宜') || value.includes('更贵'))) return 'price_compare'
    if (value.includes('场次')) return 'sessions'
    if (value.includes('票档') || value.includes('还有票') || value.includes('库存')) return 'tickets'
    if (value.includes('最近一周')) return 'recent_week'
    if (value.includes('周末')) return 'weekend'
    if (value.includes('500') && value.includes('元')) return 'budget_500'
    if (value.includes('其他类型')) return 'other_category'
    if (value.includes('价格从低到高')) return 'price_asc'
    if (value.includes('时间最近')) return 'nearest'
    if (value.includes('不限价格')) return 'no_price_limit'
    if (value.includes('不限分类')) return 'no_category_limit'
    if (value.includes('不限场馆')) return 'no_venue_limit'
    if (value.includes('不限关键词')) return 'no_keyword_limit'
    if (value.includes('全部演出')) return 'all_performances'
    if (value.includes('放宽时间')) return 'widen_time'
    if (value.includes('换个城市')) return 'change_city'
    if (value.includes('继续看') || value.includes('下一批')) return 'continue_results'
    return value.trim()
  }

  private effectiveConversationCity(): string {
    const conversationCity: string = this.searchContext.city.trim()
    return conversationCity.length > 0 ? conversationCity : this.appCurrentCity()
  }

  private citySuggestedPrompt(prompt: string): string {
    const city: string = this.appCurrentCity()
    return city.length > 0 ? city + prompt : prompt
  }

  private defaultCityPrompt(): string {
    const city: string = this.appCurrentCity()
    return city.length > 0 ? city + '最近有什么演唱会？' : '最近有什么演唱会？'
  }

  private appCurrentCity(): string {
    const storageCity: string = this.currentCity.trim()
    return storageCity.length > 0 ? storageCity : this.cityRepository.getCurrentCity()
  }

  private onCurrentCityChanged(): void {
    if (this.status !== AiChatStatus.DONE) return
    const index: number = this.findLatestAssistantIndex()
    if (index < 0) return
    this.suggestedPrompts = this.buildSuggestedPrompts(this.messages[index].cards)
  }

  private hasSearchContext(): boolean {
    return this.searchContext.city.trim().length > 0 || this.searchContext.category.trim().length > 0 ||
      this.searchContext.keyword.trim().length > 0 || this.searchContext.venue.trim().length > 0 ||
      this.searchContext.minPrice !== undefined ||
      this.searchContext.maxPrice !== undefined || this.searchContext.startTime.trim().length > 0 ||
      this.searchContext.endTime.trim().length > 0 || this.searchContext.timeIntent.trim().length > 0 ||
      this.searchContext.sort.trim().length > 0
  }

  private canBroadenTime(): boolean {
    const intent: string = this.searchContext.timeIntent.trim().toUpperCase()
    return intent.length > 0 && intent !== 'FUTURE' && intent !== 'PAST'
  }

  private supportsCapability(capability: string): boolean {
    return this.supportedCapabilities.includes(capability)
  }

  private sendSuggestedPrompt(prompt: string): void {
    this.sendText(prompt)
  }

  private shouldShowSuggestions(item: AiChatMessageVO): boolean {
    return item.id === this.latestAssistantId() && item.status === AiChatStatus.DONE &&
      this.status === AiChatStatus.DONE && this.suggestedPrompts.length > 0
  }

  private canRegenerate(item: AiChatMessageVO): boolean {
    if (this.status === AiChatStatus.STREAMING || item.id !== this.latestAssistantId()) return false
    return item.status === AiChatStatus.DONE || item.status === AiChatStatus.ERROR ||
      item.status === AiChatStatus.STOPPED
  }

  private isActiveGeneration(sequence: number, conversationId: string, assistantId: string): boolean {
    return this.generationSequence === sequence && this.currentConversationId === conversationId &&
      this.status === AiChatStatus.STREAMING && this.messages.some(
        (item: AiChatMessageVO): boolean => item.id === assistantId && item.status === AiChatStatus.STREAMING)
  }

  private latestAssistantId(): string {
    const index: number = this.findLatestAssistantIndex()
    return index < 0 ? '' : this.messages[index].id
  }

  private findLatestAssistantIndex(): number {
    for (let index: number = this.messages.length - 1; index >= 0; index--) {
      if (this.messages[index].role === 'assistant') return index
    }
    return -1
  }

  private ensureCurrentConversation(firstUserText: string): void {
    if (this.currentConversationId.length > 0) return
    const now: number = Date.now()
    this.currentConversationId = this.createConversationId()
    this.currentCreateTime = now
    this.currentUpdateTime = now
    const title: string = this.createConversationTitle(firstUserText)
    const conversation: AiConversation = new AiConversation(
      this.currentConversationId, title, now, now, [], '', '', new AiSearchContext(), [], '', '')
    this.conversations = [conversation].concat(this.conversations)
  }

  private startNewConversation(): void {
    if (this.status === AiChatStatus.STREAMING) return
    this.flushCurrentConversation()
    this.resetConversationState()
    this.historyVisible = false
    this.saveAllConversations('')
  }

  private openConversation(conversationId: string): void {
    if (this.status === AiChatStatus.STREAMING || conversationId === this.currentConversationId) {
      this.historyVisible = false
      return
    }
    this.flushCurrentConversation()
    const conversation: AiConversation | undefined = this.conversations.find(
      (value: AiConversation): boolean => value.id === conversationId)
    if (conversation === undefined) return
    this.currentConversationId = conversation.id
    this.currentCreateTime = conversation.createTime
    this.currentUpdateTime = conversation.updateTime
    this.messages = conversation.messages
    this.contextProjectId = conversation.contextProjectId
    this.contextSessionId = conversation.contextSessionId
    this.searchContext = conversation.searchContext
    this.lastSearchResults = conversation.lastSearchResults
    this.selectedProjectId = conversation.selectedProjectId
    this.selectedSessionId = conversation.selectedSessionId
    this.searchResultState = conversation.searchResultState
    this.entityContext = conversation.entityContext
    this.activeSlot = conversation.activeSlot
    this.supportedCapabilities = conversation.capabilities
    this.pendingCards = []
    this.inputText = ''
    this.lastFailedText = this.latestUserText()
    this.status = this.resolveConversationStatus()
    this.suggestedPrompts = this.restoreSuggestedPrompts()
    this.historyVisible = false
    this.saveAllConversations(this.currentConversationId)
    this.scrollToLatest()
  }

  private resetConversationState(): void {
    this.currentConversationId = ''
    this.currentCreateTime = 0
    this.currentUpdateTime = 0
    this.messages = []
    this.contextProjectId = ''
    this.contextSessionId = ''
    this.searchContext = new AiSearchContext()
    this.lastSearchResults = []
    this.selectedProjectId = ''
    this.selectedSessionId = ''
    this.searchResultState = new AiSearchResultState()
    this.entityContext = new AiEntityContext()
    this.activeSlot = 'NONE'
    this.supportedCapabilities = []
    this.pendingCards = []
    this.suggestedPrompts = []
    this.inputText = ''
    this.lastFailedText = ''
    this.status = AiChatStatus.IDLE
  }

  private loadHistory(): void {
    if (this.historyLoaded) return
    const context: common.Context | undefined = this.hostContext()
    if (context === undefined) return
    this.historyLoaded = true
    this.conversations = AiConversationStore.load(context)
    const activeId: string = AiConversationStore.getActiveConversationId(context)
    const active: AiConversation | undefined = this.conversations.find(
      (value: AiConversation): boolean => value.id === activeId) ?? this.conversations[0]
    if (active !== undefined) {
      this.currentConversationId = active.id
      this.currentCreateTime = active.createTime
      this.currentUpdateTime = active.updateTime
      this.messages = active.messages
      this.contextProjectId = active.contextProjectId
      this.contextSessionId = active.contextSessionId
      this.searchContext = active.searchContext
      this.lastSearchResults = active.lastSearchResults
      this.selectedProjectId = active.selectedProjectId
      this.selectedSessionId = active.selectedSessionId
      this.searchResultState = active.searchResultState
      this.entityContext = active.entityContext
      this.activeSlot = active.activeSlot
      this.supportedCapabilities = active.capabilities
      this.lastFailedText = this.latestUserText()
      this.status = this.resolveConversationStatus()
      this.suggestedPrompts = this.restoreSuggestedPrompts()
    }
  }

  private persistCurrentConversation(): void {
    if (!this.hasUserMessage() || this.currentConversationId.length === 0) return
    const conversation: AiConversation = new AiConversation(
      this.currentConversationId,
      this.createConversationTitle(this.firstUserText()),
      this.currentCreateTime > 0 ? this.currentCreateTime : Date.now(),
      this.currentUpdateTime > 0 ? this.currentUpdateTime : Date.now(),
      this.messages,
      this.contextProjectId,
      this.contextSessionId,
      this.searchContext,
      this.lastSearchResults,
      this.selectedProjectId,
      this.selectedSessionId,
      this.searchResultState,
      this.entityContext,
      this.activeSlot,
      this.supportedCapabilities
    )
    const remaining: AiConversation[] = this.conversations.filter(
      (value: AiConversation): boolean => value.id !== this.currentConversationId)
    this.conversations = [conversation].concat(remaining)
      .sort((left: AiConversation, right: AiConversation): number => right.updateTime - left.updateTime)
    this.saveAllConversations(this.currentConversationId)
  }

  private flushCurrentConversation(): void {
    if (this.status === AiChatStatus.STREAMING) {
      this.persistStreamingSnapshot()
      return
    }
    this.persistCurrentConversation()
  }

  private persistStreamingSnapshot(): void {
    if (!this.hasUserMessage() || this.currentConversationId.length === 0) return
    const snapshotMessages: AiChatMessageVO[] = this.messages.map((message: AiChatMessageVO): AiChatMessageVO => {
      if (message.status !== AiChatStatus.STREAMING) return message
      return new AiChatMessageVO(message.id, message.role, message.content, message.cards, AiChatStatus.STOPPED,
        message.requestContextProjectId, message.requestContextSessionId)
    })
    const snapshot: AiConversation = new AiConversation(
      this.currentConversationId,
      this.createConversationTitle(this.firstUserText()),
      this.currentCreateTime,
      this.currentUpdateTime,
      snapshotMessages,
      this.contextProjectId,
      this.contextSessionId,
      this.searchContext,
      this.lastSearchResults,
      this.selectedProjectId,
      this.selectedSessionId,
      this.searchResultState,
      this.entityContext,
      this.activeSlot,
      this.supportedCapabilities
    )
    const remaining: AiConversation[] = this.conversations.filter(
      (value: AiConversation): boolean => value.id !== this.currentConversationId)
    const values: AiConversation[] = [snapshot].concat(remaining)
      .sort((left: AiConversation, right: AiConversation): number => right.updateTime - left.updateTime)
    const context: common.Context | undefined = this.hostContext()
    if (context !== undefined) AiConversationStore.save(context, values, this.currentConversationId)
  }

  private saveAllConversations(activeConversationId: string): void {
    const context: common.Context | undefined = this.hostContext()
    if (context !== undefined) AiConversationStore.save(context, this.conversations, activeConversationId)
  }

  private showDeleteConversationDialog(conversationId: string): void {
    this.getUIContext().showAlertDialog({
      title: '删除历史对话',
      message: '删除后无法恢复，确认删除吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.deleteConversation(conversationId)
        }
      }
    })
  }

  private deleteConversation(conversationId: string): void {
    if (this.status === AiChatStatus.STREAMING) return
    this.conversations = this.conversations.filter(
      (value: AiConversation): boolean => value.id !== conversationId)
    if (conversationId === this.currentConversationId) {
      this.resetConversationState()
      const nextConversation: AiConversation | undefined = this.conversations[0]
      if (nextConversation !== undefined) {
        this.openConversation(nextConversation.id)
      } else {
        this.saveAllConversations('')
      }
      return
    }
    this.saveAllConversations(this.currentConversationId)
  }

  private restoreSuggestedPrompts(): string[] {
    const index: number = this.findLatestAssistantIndex()
    if (index < 0 || this.messages[index].status !== AiChatStatus.DONE) return []
    return this.buildSuggestedPrompts(this.messages[index].cards)
  }

  private resolveConversationStatus(): AiChatStatus {
    const index: number = this.findLatestAssistantIndex()
    if (index < 0) return AiChatStatus.IDLE
    const value: AiChatStatus = this.messages[index].status
    return value === AiChatStatus.STREAMING ? AiChatStatus.STOPPED : value
  }

  private hasUserMessage(): boolean {
    return this.messages.some((item: AiChatMessageVO): boolean => item.role === 'user')
  }

  private firstUserText(): string {
    const message: AiChatMessageVO | undefined = this.messages.find(
      (item: AiChatMessageVO): boolean => item.role === 'user')
    return message?.content ?? ''
  }

  private latestUserText(): string {
    for (let index: number = this.messages.length - 1; index >= 0; index--) {
      if (this.messages[index].role === 'user') return this.messages[index].content
    }
    return ''
  }

  private createConversationTitle(value: string): string {
    const normalized: string = value.trim().replace(/[?？!！。,.，]+$/g, '')
    if (normalized.length <= 24) return normalized.length > 0 ? normalized : '新的对话'
    return normalized.substring(0, 24) + '…'
  }

  private createConversationId(): string {
    return 'conversation_' + String(Date.now()) + '_' + String(Math.floor(Math.random() * 1000000))
  }

  private historyPanelWidth(): number {
    const width: number = this.contentWidth > 0 ? this.contentWidth : 360
    if (this.isWideLayout()) return Math.min(340, Math.max(280, width * 0.24))
    if (this.isTabletLayout()) return Math.min(380, Math.max(320, width * 0.4))
    return Math.min(360, Math.max(300, width * 0.88))
  }

  private useRoomyResultCard(): boolean {
    return this.workspaceWidth >= 600
  }

  private useTwoColumnResultCards(): boolean {
    const listPadding: number = this.isTabletLayout() ? 48 : 24
    const messageWidth: number = Math.min(760, Math.max(0, this.workspaceWidth - listPadding))
    const cardContainerWidth: number = Math.max(0, messageWidth - 28)
    const cardWidth: number = (cardContainerWidth - ResponsiveLayout.AI_RESULT_CARD_GAP) / 2
    return cardWidth >= ResponsiveLayout.AI_RESULT_CARD_MIN_WIDTH
  }

  private hostContext(): common.Context | undefined {
    const context: common.Context | undefined = this.getUIContext().getHostContext()
    return context
  }

  private scrollToLatest(): void {
    this.followLatest = true
    setTimeout((): void => {
      if (this.messages.length > 0) {
        this.messageScroller.scrollToIndex(this.messages.length - 1, true, ScrollAlign.END)
      }
    }, 30)
  }

  private followLatestIfNeeded(): void {
    if (!this.followLatest || this.followScrollPending || this.messages.length === 0) return
    this.followScrollPending = true
    setTimeout((): void => {
      this.followScrollPending = false
      if (!this.followLatest || this.messages.length === 0) return
      this.messageScroller.scrollToIndex(this.messages.length - 1, false, ScrollAlign.END)
    }, 80)
  }

  private registerKeyboardListener(): void {
    if (this.keyboardListenerRegistered || this.keyboardListenerPending) return
    const context: common.Context | undefined = this.hostContext()
    if (context === undefined) return
    this.keyboardListenerPending = true
    window.getLastWindow(context).then((appWindow: window.Window): void => {
      this.keyboardListenerPending = false
      if (this.keyboardListenerRegistered) return
      this.keyboardWindow = appWindow
      try {
        appWindow.on('keyboardHeightChange', this.keyboardHeightChangeCallback)
        this.keyboardListenerRegistered = true
      } catch (error) {
        this.keyboardWindow = undefined
      }
    }).catch((): void => {
      this.keyboardListenerPending = false
    })
  }

  private unregisterKeyboardListener(): void {
    this.keyboardListenerPending = false
    this.aiKeyboardVisible = false
    if (!this.keyboardListenerRegistered || this.keyboardWindow === undefined) return
    try {
      this.keyboardWindow.off('keyboardHeightChange', this.keyboardHeightChangeCallback)
    } catch (error) {
    }
    this.keyboardListenerRegistered = false
    this.keyboardWindow = undefined
  }

  private restoreKeyboardAvoidMode(): void {
    if (this.keyboardAvoidModeCaptured) {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode)
    }
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isMediumWidth(this.contentWidth)
  }

  private isWideLayout(): boolean {
    return ResponsiveLayout.isWideWidth(this.contentWidth)
  }
}
