import router from '@ohos.router'

import {
  TicketFolderItemVO
} from '../../model/vo/ticket/TicketFolderPageVO'

import {
  TicketFolderViewModel,
  TicketDetailJumpParams
} from '../../viewmodel/TicketFolderViewModel'

import { TicketStatus } from '../../model/enums/TicketStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface TicketFolderRouteParams {
  userId?: string
}


@Entry
@Component
struct TicketFolderPage {
  private vm: TicketFolderViewModel = new TicketFolderViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVersion: number = 0
  @State userId: string = ''
  @State tickets: TicketFolderItemVO[] = []
  @State isLoading: boolean = false
  @State isRefreshing: boolean = false
  @State errorMessage: string = ''
  @StorageLink('ticket_changed_version') @Watch('onTicketChanged') ticketChangedVersion: number = 0
  @StorageLink('refund_changed_version') @Watch('onTicketChanged') refundChangedVersion: number = 0
  @StorageLink('shipment_changed_version') @Watch('onTicketChanged') shipmentChangedVersion: number = 0
  @StorageLink('login_version') @Watch('onLoginChanged') loginVersion: number = 0
  private stateRefreshTimerId: number = -1

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentUserTickets()
  }

  aboutToDisappear(): void {
    this.stopStateRefreshTimer()
  }

  private onTicketChanged(): void {
    this.reloadCurrentUserTickets()
  }

  private async onLoginChanged(): Promise<void> {
    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    if (currentUserId.length === 0 || !this.userRepository.isLogin()) {
      this.userId = ''
      this.tickets = []
      this.errorMessage = ''
      this.pageVersion++
      this.stopStateRefreshTimer()
      return
    }
    await this.vm.loadPage(currentUserId)
    this.syncFromVm()
  }

  private async loadPageData(): Promise<void> {
    const params = router.getParams() as TicketFolderRouteParams
    const routeUserId: string = params.userId ?? ''
    const currentUserId: string = this.userRepository.getCurrentUserId()
    const userId: string = routeUserId.length > 0 ? routeUserId : currentUserId

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    await this.vm.loadPage(userId)
    this.syncFromVm()
  }

  private async reloadCurrentUserTickets(): Promise<void> {
    if (this.userId.length === 0) {
      return
    }

    if (!this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    await this.vm.refresh()
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.tickets = this.vm.tickets.slice()
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.pageVersion++
    this.startStateRefreshTimerIfNeeded()
  }

  private startStateRefreshTimerIfNeeded(): void {
    this.stopStateRefreshTimer()
    const hasVolatileTicket: boolean = this.tickets.some((item: TicketFolderItemVO): boolean => {
      return item.ticketStatus === TicketStatus.GENERATING || item.orderStatus === 'REFUNDING'
    })
    if (!hasVolatileTicket) return
    this.stateRefreshTimerId = setInterval(() => {
      this.reloadCurrentUserTickets()
    }, 20000)
  }

  private stopStateRefreshTimer(): void {
    if (this.stateRefreshTimerId >= 0) {
      clearInterval(this.stateRefreshTimerId)
      this.stateRefreshTimerId = -1
    }
  }

  build() {
    Column() {
      this.TopBar()

      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.isLoading && this.tickets.length === 0) {
          this.LoadingArea('正在加载票夹...')
        } else if (this.tickets.length === 0) {
          this.EmptyArea()
        } else {
          List() {
            ForEach(this.tickets, (item: TicketFolderItemVO) => {
              ListItem() {
                this.TicketCard(item)
              }
            }, (item: TicketFolderItemVO) => {
              return `${item.orderId}_${item.ticketId}_${item.ticketStatus}_${item.displayStatus}`
            })
          }
          .width('100%')
          .height('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 14 })
        }
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.handleRefresh()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private TopBar() {
    Row() {
      Row() {
        Image($r('app.media.fanhui'))
          .width(22)
          .height(22)
      }
      .width(40)
      .height(52)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        router.back()
      })

      Text('我的票夹')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 4, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private LoadingArea(message: string) {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color('#E33B3B')

      Text(message)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '您的票夹暂时无票')
        .fontSize(15)
        .fontColor(this.errorMessage.length > 0 ? '#E33B3B' : '#999999')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })

      if (this.errorMessage.length > 0) {
        Text('点击重试')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding({ left: 18, right: 18, top: 8, bottom: 8 })
          .margin({ top: 14 })
          .backgroundColor('#E33B3B')
          .borderRadius(18)
          .onClick(() => {
            this.reloadCurrentUserTickets()
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private TicketCard(item: TicketFolderItemVO) {
    Column() {
      Row() {
        Image(MediaResourceUtil.getMedia(item.posterUrl))
          .width(78)
          .height(104)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)

        Column() {
          Text(item.projectTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
            .width('100%')

          Text(item.startTime)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 7 })
            .textAlign(TextAlign.Start)
            .width('100%')

          Text(item.venueName)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
            .textAlign(TextAlign.Start)
            .width('100%')

          Text(item.skuName)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .layoutWeight(1)
        .height(104)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Divider()
        .strokeWidth(0.5)
        .color('#EEEEEE')
        .margin({ top: 12, bottom: 10 })

      Row() {
        Column() {
          Text(`${item.ticketCount} 张`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')

          Text(this.getTicketStatusText(item))
            .fontSize(12)
            .fontColor(this.getTicketStatusColor(item))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Button(this.getActionButtonText(item))
          .height(34)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#E33B3B')
          .borderRadius(17)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.jumpTicketDetail(item)
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(174)
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .opacity(this.isUnavailableTicket(item) ? 0.72 : 1)
  }

  private async handleRefresh(): Promise<void> {
    this.isRefreshing = true
    await this.reloadCurrentUserTickets()
    this.isRefreshing = false
  }

  private jumpTicketDetail(item: TicketFolderItemVO): void {
    const params: TicketDetailJumpParams = this.vm.buildTicketDetailJumpParams(item)

    router.pushUrl({
      url: 'pages/ticket/TicketDetailPage',
      params: params
    })
  }

  private isUnavailableTicket(item: TicketFolderItemVO): boolean {
    return item.orderStatus === 'REFUNDING' || item.orderStatus === 'REFUND_SUCCESS' ||
      item.ticketStatus === TicketStatus.CHECKED || item.ticketStatus === TicketStatus.EXPIRED
  }

  private getActionButtonText(item: TicketFolderItemVO): string {
    if (item.orderStatus === 'REFUNDING' || item.orderStatus === 'REFUND_SUCCESS') {
      return '查看详情'
    }

    if (item.deliveryType === 'PAPER_TICKET') {
      if (item.deliveryMode === 'EXPRESS') {
        return '查看物流'
      }
      return '查看取票信息'
    }

    if (item.ticketStatus === TicketStatus.UNUSED) {
      return '查看电子票'
    }

    return '查看详情'
  }

  private getTicketStatusText(item: TicketFolderItemVO): string {
    if (item.orderStatus === 'REFUNDING') return '退款中'
    if (item.orderStatus === 'REFUND_SUCCESS') return '已退款'

    if (item.deliveryType === 'PAPER_TICKET' && item.ticketStatus === TicketStatus.UNUSED) {
      return item.deliveryMode === 'EXPRESS' ? '纸质票配送中' : '待现场取票'
    }

    if (item.ticketStatus === TicketStatus.GENERATING) {
      return '生成中'
    }

    if (item.ticketStatus === TicketStatus.UNUSED) {
      return '未使用'
    }

    if (item.ticketStatus === TicketStatus.CHECKED) {
      return '已检票'
    }

    if (item.ticketStatus === TicketStatus.EXPIRED) {
      return '已失效'
    }

    if (item.ticketStatus === TicketStatus.ERROR) {
      return '异常'
    }

    return '不可用'
  }

  private getTicketStatusColor(item: TicketFolderItemVO): string {
    if (item.orderStatus === 'REFUNDING') return '#C07A00'
    if (item.orderStatus === 'REFUND_SUCCESS') return '#999999'

    if (item.ticketStatus === TicketStatus.UNUSED) {
      return '#E33B3B'
    }

    if (item.ticketStatus === TicketStatus.GENERATING) {
      return '#FF8A00'
    }

    if (item.ticketStatus === TicketStatus.ERROR) {
      return '#D93025'
    }

    return '#999999'
  }
}
