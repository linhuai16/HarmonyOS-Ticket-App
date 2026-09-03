import { AiChatStatus, AiConversation } from '../model/AiChatVO'

@Component
export struct AiEmptyState {
  tablet: boolean = false
  cityPrompt: string = ''
  onSend: (text: string) => void = (_text: string): void => {}

  build() {
    Column() {
      Text('✨').fontSize(40)
      Text('想看什么，问问麦麦AI')
        .fontSize(this.tablet ? 22 : 19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ top: 12 })
      Text('演出信息、场次、票档与退款规则均来自麦麦实时业务数据')
        .fontSize(this.tablet ? 15 : 13)
        .fontColor('#777777')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 22 })
      this.Prompt(this.cityPrompt)
      this.Prompt('500元以内有什么演出？')
      this.Prompt('这个周末有什么演出？')
    }
    .layoutWeight(1)
    .width('100%')
    .padding({ left: 20, right: 20, top: this.tablet ? 80 : 48 })
  }

  @Builder
  private Prompt(text: string) {
    Row() {
      Text(text)
        .fontSize(this.tablet ? 16 : 14)
        .fontColor('#333333')
        .maxLines(2)
      Blank()
      Text('›').fontSize(22).fontColor('#1677FF')
    }
    .width('100%')
    .constraintSize({ maxWidth: 560 })
    .height(this.tablet ? 54 : 50)
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.onSend(text)
    })
  }
}

@Component
export struct AiInputToolbar {
  inputText: string = ''
  status: AiChatStatus = AiChatStatus.IDLE
  tablet: boolean = false
  onInput: (text: string) => void = (_text: string): void => {}
  onSend: (text: string) => void = (_text: string): void => {}
  onStop: () => void = (): void => {}

  build() {
    Row() {
      TextArea({
        placeholder: this.status === AiChatStatus.STREAMING ? '可以继续输入，停止或生成完成后发送' : '问问想看的演出',
        text: this.inputText
      })
        .layoutWeight(1)
        .minLines(1)
        .maxLines(5, { overflowMode: MaxLinesMode.SCROLL })
        .textOverflow(TextOverflow.None)
        .constraintSize({
          minHeight: this.tablet ? 52 : 48,
          maxHeight: this.tablet ? 132 : 124
        })
        .align(Alignment.TopStart)
        .padding({ left: 12, right: 12, top: 11, bottom: 11 })
        .fontSize(this.tablet ? 16 : 15)
        .backgroundColor('#F3F4F6')
        .borderRadius(12)
        .onChange((value: string) => {
          this.onInput(value.substring(0, Math.min(500, value.length)))
        })
      Button(this.status === AiChatStatus.STREAMING ? '停止生成' : '发送')
        .width(this.tablet ? 104 : 88)
        .height(this.tablet ? 52 : 48)
        .fontSize(this.tablet ? 16 : 14)
        .fontColor('#FFFFFF')
        .backgroundColor(this.status === AiChatStatus.STREAMING ? '#E33B3B' :
          (this.canSend() ? '#1677FF' : '#B7C8DD'))
        .borderRadius(12)
        .enabled(this.status === AiChatStatus.STREAMING || this.canSend())
        .margin({ left: 10 })
        .onClick(() => {
          if (this.status === AiChatStatus.STREAMING) {
            this.onStop()
            return
          }
          this.onSend(this.inputText.trim())
        })
    }
    .width('100%')
    .padding({ left: this.tablet ? 24 : 12, right: this.tablet ? 24 : 12, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .border({ width: { top: 1 }, color: '#EAEAEA' })
  }

  private canSend(): boolean {
    return this.status !== AiChatStatus.STREAMING && this.inputText.trim().length > 0
  }
}

@Component
export struct AiHistoryPanel {
  persistent: boolean = false
  conversations: AiConversation[] = []
  currentConversationId: string = ''
  panelWidth: number = 300
  onClose: () => void = (): void => {}
  onOpen: (id: string) => void = (_id: string): void => {}
  onDelete: (id: string) => void = (_id: string): void => {}

  build() {
    Column() {
      Row() {
        Text('历史对话').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#222222')
        Blank()
        if (!this.persistent) {
          Button('关闭')
            .height(36)
            .fontSize(13)
            .fontColor('#555555')
            .backgroundColor('#F2F3F5')
            .onClick(() => {
              this.onClose()
            })
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 18, right: 14 })
      .border({ width: { bottom: 1 }, color: '#EAEAEA' })
      if (this.conversations.length === 0) {
        Column() {
          Text('暂无历史对话').fontSize(15).fontColor('#888888')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 4 }) {
          ForEach(this.conversations, (conversation: AiConversation, index: number) => {
            ListItem() {
              Column() {
                if (this.historyGroupLabel(index).length > 0) {
                  Text(this.historyGroupLabel(index))
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#888888')
                    .width('100%')
                    .margin({ top: 12, bottom: 6 })
                }
                Row() {
                  Column() {
                    Text(conversation.title)
                      .fontSize(15)
                      .fontColor('#222222')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    Text(this.formatHistoryTime(conversation.updateTime))
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .onClick(() => {
                    this.onOpen(conversation.id)
                  })
                  Button() {
                    Image($r('app.media.delete'))
                      .width(18)
                      .height(18)
                      .opacity(0.72)
                  }
                  .width(40)
                  .height(34)
                  .backgroundColor('#00000000')
                  .borderRadius(17)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.onDelete(conversation.id)
                  })
                }
                .width('100%')
                .padding({ left: 12, right: 8, top: 12, bottom: 12 })
                .backgroundColor(conversation.id === this.currentConversationId ? '#EEF5FF' : '#F7F7F7')
                .borderRadius(10)
              }
              .width('100%')
            }
          }, (conversation: AiConversation) => conversation.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 16 })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width(this.panelWidth)
    .height('100%')
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 18, color: '#33000000', offsetX: 4, offsetY: 0 })
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 16 })
        .onActionEnd((event: GestureEvent) => {
          const horizontal: number = Number(event.offsetX ?? 0)
          const vertical: number = Number(event.offsetY ?? 0)
          if (!this.persistent && horizontal < -72 && Math.abs(horizontal) > Math.abs(vertical) * 1.4) {
            this.onClose()
          }
        })
    )
    .onClick(() => {
    })
  }

  private historyGroupLabel(index: number): string {
    if (index < 0 || index >= this.conversations.length) return ''
    const group: string = this.dayLabel(this.conversations[index].updateTime)
    if (index === 0) return group
    return this.dayLabel(this.conversations[index - 1].updateTime) === group ? '' : group
  }

  private dayLabel(timestamp: number): string {
    const now: Date = new Date()
    const target: Date = new Date(timestamp)
    const todayStart: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const targetStart: Date = new Date(target.getFullYear(), target.getMonth(), target.getDate())
    const days: number = Math.round((todayStart.getTime() - targetStart.getTime()) / 86400000)
    if (days === 0) return '今天'
    if (days === 1) return '昨天'
    if (now.getFullYear() === target.getFullYear()) {
      return String(target.getMonth() + 1) + '月' + String(target.getDate()) + '日'
    }
    return String(target.getFullYear()) + '年' + String(target.getMonth() + 1) + '月' + String(target.getDate()) + '日'
  }

  private formatHistoryTime(timestamp: number): string {
    const date: Date = new Date(timestamp)
    return this.padTwo(date.getHours()) + ':' + this.padTwo(date.getMinutes())
  }

  private padTwo(value: number): string {
    return value < 10 ? '0' + String(value) : String(value)
  }
}
