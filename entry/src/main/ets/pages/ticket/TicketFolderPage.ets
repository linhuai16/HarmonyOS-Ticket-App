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

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentUserTickets()
  }

  private onTicketChanged(): void {
    this.reloadCurrentUserTickets()
  }

  private loadPageData(): void {
    const params = router.getParams() as TicketFolderRouteParams
    const routeUserId: string = params.userId ?? ''
    const currentUserId: string = this.userRepository.getCurrentUserId()
    const userId: string = routeUserId.length > 0 ? routeUserId : currentUserId

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.vm.loadPage(userId)
    this.syncFromVm()
  }

  private reloadCurrentUserTickets(): void {
    if (this.userId.length === 0) {
      return
    }

    if (!this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.vm.refresh()
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.tickets = this.vm.tickets.slice()
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.pageVersion++
  }

  build() {
    Column() {
      this.TopBar()

      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.tickets.length === 0) {
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
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '您的票夹暂时无票')
        .fontSize(15)
        .fontColor('#999999')
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

  private handleRefresh(): void {
    this.isRefreshing = true
    this.reloadCurrentUserTickets()
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
    return item.ticketStatus === TicketStatus.CHECKED || item.ticketStatus === TicketStatus.EXPIRED
  }

  private getActionButtonText(item: TicketFolderItemVO): string {
    if (item.ticketStatus === TicketStatus.UNUSED) {
      return '查看电子票'
    }

    return '查看详情'
  }

  private getTicketStatusText(item: TicketFolderItemVO): string {
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
