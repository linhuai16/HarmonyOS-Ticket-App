const ticketServiceCard2x2Storage: LocalStorage = new LocalStorage()

@Entry(ticketServiceCard2x2Storage)
@Component
struct TicketServiceCard2x2 {
  @LocalStorageProp('statusCode') statusCode: string = 'LOADING'
  @LocalStorageProp('statusText') statusText: string = '正在更新'
  @LocalStorageProp('title') title: string = '麦麦票务'
  @LocalStorageProp('primaryText') primaryText: string = '正在获取真实票务数据'
  @LocalStorageProp('secondaryText') secondaryText: string = ''
  @LocalStorageProp('payRemainingMillis') payRemainingMillis: number = 0
  @LocalStorageProp('payExpireTimestamp') @Watch('onPayExpireTimestampChanged') payExpireTimestamp: number = 0
  @LocalStorageProp('actionText') actionText: string = '打开应用'
  @LocalStorageProp('target') target: string = 'HOME'
  @LocalStorageProp('userId') userId: string = ''
  @LocalStorageProp('orderId') orderId: string = ''
  @LocalStorageProp('ticketId') ticketId: string = ''
  @LocalStorageProp('projectId') projectId: string = ''
  @LocalStorageProp('sessionId') sessionId: string = ''
  @State payExpired: boolean = false
  private payTimerController: TextTimerController = new TextTimerController()

  aboutToAppear(): void {
    this.payExpired = this.isPayExpired()
  }

  build() {
    Column() {
      Row() {
        Text(this.statusText)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getStatusColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Text('麦麦')
          .fontSize(12)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')

      Text(this.title)
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 10 })

      Text(this.primaryText)
        .width('100%')
        .fontSize(13)
        .fontColor($r('sys.color.font_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })

      if (this.hasActivePayCountdown()) {
        Row() {
          Text('支付剩余 ')
            .fontSize(12)
            .fontColor($r('sys.color.font_tertiary'))

          TextTimer({
            isCountDown: true,
            count: this.getPayRemainingMillis(),
            controller: this.payTimerController
          })
            .format('mm:ss')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getStatusColor())
            .onTimer((_utc: number, elapsedTime: number): void => {
              if (this.isPayExpired() ||
                (this.payExpireTimestamp <= 0 && elapsedTime >= this.payRemainingMillis)) {
                this.payExpired = true
              }
            })
            .onAppear((): void => {
              this.payTimerController.start()
            })
        }
        .width('100%')
        .margin({ top: 4 })
      } else if (this.statusCode === 'WAIT_PAY') {
        Text(this.getPayStatusText())
          .width('100%')
          .fontSize(12)
          .fontColor($r('sys.color.font_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }

      Blank()

      Row() {
        Text(this.getActionText())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(40)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.getStatusColor())
      .borderRadius(20)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .onClick(() => {
      this.openTarget()
    })
  }

  private openTarget(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        entryTarget: this.target,
        entryUserId: this.userId,
        entryOrderId: this.orderId,
        entryTicketId: this.ticketId,
        entryProjectId: this.projectId,
        entrySessionId: this.sessionId
      }
    })
  }

  private onPayExpireTimestampChanged(): void {
    this.payExpired = this.isPayExpired()
    if (this.statusCode === 'WAIT_PAY' && !this.payExpired) {
      this.payTimerController.reset()
      this.payTimerController.start()
    }
  }

  private hasActivePayCountdown(): boolean {
    return this.statusCode === 'WAIT_PAY' && !this.payExpired && this.getPayRemainingMillis() > 0
  }

  private getPayRemainingMillis(): number {
    const remaining: number = this.payExpireTimestamp > 0 ?
      this.payExpireTimestamp - Date.now() : this.payRemainingMillis
    return Math.max(0, Math.min(86399999, remaining))
  }

  private isPayExpired(): boolean {
    return this.statusCode === 'WAIT_PAY' && this.payExpireTimestamp > 0 &&
      this.payExpireTimestamp <= Date.now()
  }

  private getPayStatusText(): string {
    if (this.payExpired || this.isPayExpired()) {
      return '支付已超时 · 请查看订单'
    }
    return this.secondaryText.length > 0 ? this.secondaryText : '请查看订单确认支付状态'
  }

  private getActionText(): string {
    return this.statusCode === 'WAIT_PAY' && (this.payExpired || this.isPayExpired()) ? '查看订单' : this.actionText
  }

  private getStatusColor(): string {
    if (this.statusCode === 'WAIT_PAY') return '#E33B3B'
    if (this.statusCode === 'TICKETING') return '#D97706'
    if (this.statusCode === 'UPCOMING') return '#1677FF'
    if (this.statusCode === 'HOT') return '#C93664'
    return '#596579'
  }
}
