import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  OrderListItemVO
} from '../../model/vo/order/OrderListPageVO'

import {
  OrderListViewModel
} from '../../viewmodel/OrderListViewModel'

import {
  OrderListTab
} from '../../repository/OrderRepository'
import { UserRepository } from '../../repository/UserRepository'

import { OrderStatus } from '../../model/enums/OrderStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

interface OrderListRouteParams {
  userId?: string
  tab?: OrderListTab
}

interface OrderTabItem {
  tab: OrderListTab
  title: string
}

@Entry
@Component
struct OrderListPage {
  private vm: OrderListViewModel = new OrderListViewModel()
  private userRepository: UserRepository = new UserRepository()

  private tabs: OrderTabItem[] = [
    { tab: OrderListTab.ALL, title: '全部' },
    { tab: OrderListTab.WAIT_PAY, title: '待支付' },
    { tab: OrderListTab.WAIT_USE, title: '待使用' },
    { tab: OrderListTab.FINISHED, title: '已完成' }
  ]

  @State userId: string = ''
  @State currentTab: OrderListTab = OrderListTab.ALL
  @State orders: OrderListItemVO[] = []
  @State hasMore: boolean = false
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0

  @StorageLink('order_changed_version')
  @Watch('onOrderChanged')
  orderChangedVersion: number = 0

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentList()
  }

  private onOrderChanged(_propName?: string): void {
    this.reloadCurrentList()
  }

  private reloadCurrentList(): void {
    const effectiveUserId: string = this.resolveUserId(this.userId)

    if (effectiveUserId.length === 0) {
      this.loadPageData()
      return
    }

    // 页面从订单详情、支付完成、票夹、退款等页面返回时，订单状态可能已经变化。
    // 这里不只 refresh VM 旧状态，而是使用当前页面选中的 tab 重新加载第一页，保证状态和按钮同步。
    this.vm.loadPage(effectiveUserId, this.currentTab).then(() => {
      this.syncFromVm()
    })
  }

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  private async loadPageData(): Promise<void> {
    const params: OrderListRouteParams | undefined = router.getParams() as OrderListRouteParams | undefined

    const userId: string = this.resolveUserId(params?.userId)
    const tab: OrderListTab = params?.tab ?? this.currentTab ?? OrderListTab.ALL

    if (userId.length === 0) {
      this.errorMessage = '请先登录后查看订单'
      this.orders = []
      this.refreshPage()
      promptAction.showToast({ message: '请先登录后查看订单' })
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    await this.vm.loadPage(userId, tab)
    this.syncFromVm()
  }

  private resolveUserId(routeUserId?: string): string {
    const normalizedRouteUserId: string = routeUserId === undefined ? '' : routeUserId.trim()
    if (normalizedRouteUserId.length > 0) {
      return normalizedRouteUserId
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.TabBar()
      this.OrderListArea()
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
      .justifyContent(FlexAlign.Center)
        .width(36)
        .height(44)
        .onClick(() => {
          router.back()
        })

      Text('我的订单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4 })

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 8, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private TabBar() {
    Row() {
      ForEach(this.tabs, (item: OrderTabItem) => {
        Text(item.title)
          .fontSize(15)
          .fontWeight(this.currentTab === item.tab ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentTab === item.tab ? '#E33B3B' : '#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height(44)
          .onClick(() => {
            this.changeTab(item.tab)
          })
      }, (item: OrderTabItem) => item.tab)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  private async changeTab(tab: OrderListTab): Promise<void> {
    if (this.userId.length === 0) {
      promptAction.showToast({ message: '请先登录后查看订单' })
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    await this.vm.changeTab(tab)
    this.syncFromVm()
  }

  @Builder
  private OrderListArea() {
    if (this.orders.length === 0) {
      Column() {
        Text(this.errorMessage.length > 0 ? this.errorMessage : '暂无订单')
          .fontSize(15)
          .fontColor('#999999')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.orders, (item: OrderListItemVO) => {
          ListItem() {
            this.OrderCard(item)
          }
        }, (item: OrderListItemVO) => this.buildOrderListItemKey(item))

        ListItem() {
          this.LoadMoreArea()
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })
      .clip(true)
    }
  }

  @Builder
  private OrderCard(item: OrderListItemVO) {
    Column() {
      Row() {
        Text(this.getOrderStatusText(item.orderStatus))
          .fontSize(14)
          .fontColor('#E33B3B')
          .fontWeight(FontWeight.Bold)

        Blank()

        Text(item.orderNo)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Row() {
        Image(MediaResourceUtil.getMedia(item.posterUrl))
          .width(82)
          .height(110)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)

        Column() {
          Text(item.projectTitle)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.startTime)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 8 })

          Text(item.venueName)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })

          Text(item.skuName + ' ￥' + item.unitPrice + ' x ' + item.quantity)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .margin({ top: 12 })
      .onClick(() => {
        this.jumpOrderDetail(item.orderId)
      })

      Row() {
        Text('合计 ￥' + item.payAmount)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Blank()

        this.ActionButton(item)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private ActionButton(item: OrderListItemVO) {
    if (item.actionType === 'CONTINUE_PAY') {
      Button('去支付')
        .height(34)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .padding({ left: 16, right: 16 })
        .backgroundColor('#E33B3B')
        .onClick(() => {
          this.jumpOrderDetail(item.orderId)
        })
    } else if (item.actionType === 'VIEW_TICKET') {
      Button('查看电子票')
        .height(34)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .padding({ left: 16, right: 16 })
        .backgroundColor('#E33B3B')
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ticket/TicketDetailPage',
            params: {
              userId: this.userId,
              orderId: item.orderId
            }
          })
        })
    } else if (item.actionType === 'TICKETING') {
      Button('出票中')
        .height(34)
        .fontSize(13)
        .fontColor('#999999')
        .padding({ left: 16, right: 16 })
        .backgroundColor('#EEEEEE')
        .enabled(false)
    }
  }

  private jumpOrderDetail(orderId: string): void {
    router.pushUrl({
      url: 'pages/order/OrderDetailPage',
      params: {
        userId: this.userId,
        orderId: orderId
      }
    })
  }

  @Builder
  private LoadMoreArea() {
    Column() {
      if (this.hasMore) {
        Text(this.isLoading ? '加载中...' : '加载更多')
          .fontSize(13)
          .fontColor('#999999')
          .padding(16)
          .onClick(() => {
            this.loadMore()
          })
      } else {
        Text('已经到底了')
          .fontSize(13)
          .fontColor('#999999')
          .padding(16)
      }
    }
    .width('100%')
  }

  private async loadMore(): Promise<void> {
    await this.vm.loadMore()
    this.syncFromVm()
  }

  private getOrderStatusText(status: OrderStatus): string {
    if (status === OrderStatus.WAIT_PAY) {
      return '待支付'
    }

    if (status === OrderStatus.WAIT_USE) {
      return '待使用'
    }

    if (status === OrderStatus.FINISHED) {
      return '已完成'
    }

    if (status === OrderStatus.REFUNDING) {
      return '退款中'
    }

    if (status === OrderStatus.REFUND_SUCCESS) {
      return '退款成功'
    }

    if (status === OrderStatus.CANCELED) {
      return '已取消'
    }

    return ''
  }

  private buildOrderListItemKey(item: OrderListItemVO): string {
    // 订单支付、取消、出票后，orderId 不会变，但 orderStatus/actionType 会变。
    // key 中加入这些字段和 pageVersion，避免 ForEach 复用旧卡片导致页面显示旧状态。
    return item.orderId + '_' + item.orderStatus + '_' + item.actionType + '_' + this.pageVersion
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.currentTab = this.vm.currentTab
    this.orders = this.vm.orders.slice()
    this.hasMore = this.vm.hasMore
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.refreshPage()
  }

  private refreshPage(): void {
    this.pageVersion++
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
}
