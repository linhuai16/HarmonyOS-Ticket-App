import { HomePage } from './home/HomePage'
import { MinePage } from './mine/MinePage'
import { AiChatPage } from '../features/ai/pages/AiChatPage'
import { SearchPage } from './search/SearchPage'
import { SearchResultPage } from './search/SearchResultPage'
import { CategoryPage } from './performance/CategoryPage'
import { PerformanceDetailPage } from './performance/PerformanceDetailPage'
import { PerformanceVideoFullscreenPage } from './performance/PerformanceVideoFullscreenPage'
import { TicketSelectPage } from './performance/TicketSelectPage'
import { SubmitOrderPage } from './order/SubmitOrderPage'
import { PaySuccessPage } from './order/PaySuccessPage'
import { OrderListPage } from './order/OrderListPage'
import { OrderDetailPage } from './order/OrderDetailPage'
import { RefundApplyPage } from './order/RefundApplyPage'
import { TicketFolderPage } from './ticket/TicketFolderPage'
import { TicketDetailPage } from './ticket/TicketDetailPage'
import { WantPage } from './want/WantPage'
import { WindowImmersiveUtil } from '../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../common/ResponsiveLayout'
import { EntryDispatcher, EntryDispatchRequest } from '../navigation/EntryDispatcher'
import { ServiceCardTarget } from '../servicecard/ServiceCardData'
import {
  AppNavRoute,
  AppNavigator,
  SearchNavParams,
  SearchResultNavParams,
  CategoryNavParams,
  WantNavParams,
  PerformanceDetailNavParams,
  PerformanceVideoFullscreenNavParams,
  TicketSelectNavParams,
  SubmitOrderNavParams,
  PaySuccessNavParams,
  OrderListNavParams,
  OrderDetailNavParams,
  RefundApplyNavParams,
  TicketFolderNavParams,
  TicketDetailNavParams
} from '../navigation/AppNavigation'

@Entry
@Component
struct Index {
  @Provide('appNavStack') navStack: NavPathStack = new NavPathStack()
  @State currentTabIndex: number = 0
  @State rootWidth: number = 0
  @StorageLink('entry_request_version') @Watch('onEntryRequestChanged') entryRequestVersion: number = 0
  @StorageLink('ai_keyboard_visible') aiKeyboardVisible: boolean = false
  @StorageLink('ai_history_visible') aiHistoryVisible: boolean = false

  aboutToAppear(): void {
    this.updateSystemBarColor(this.currentTabIndex)
    setTimeout((): void => {
      this.dispatchEntryRequest()
    }, 0)
  }

  onPageShow(): void {
    this.updateSystemBarColor(this.currentTabIndex)
  }

  onBackPress(): boolean {
    if (this.currentTabIndex === 1 && this.aiHistoryVisible) {
      this.aiHistoryVisible = false
      return true
    }
    return false
  }

  build() {
    Navigation(this.navStack) {
      Column() {
        Row() {
          if (this.useSideNavigation()) {
            this.SideTabBar()
          }
          this.RootPageContent()
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')

        if (!this.useSideNavigation() && !(this.currentTabIndex === 1 && this.aiKeyboardVisible)) {
          this.BottomTabBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const nextWidth: number = Number(newValue.width ?? 0)
        if (Math.abs(nextWidth - this.rootWidth) > 0.5) {
          this.rootWidth = nextWidth
        }
      })
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
  }

  @Builder
  private RootPageContent() {
    Stack() {
      if (this.currentTabIndex === 0) {
        HomePage()
      } else if (this.currentTabIndex === 1) {
        AiChatPage()
      } else {
        MinePage()
      }
    }
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .backgroundColor('#F5F5F5')
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, currentRatio: number) => {
      if (isVisible && currentRatio > 0) {
        this.updateSystemBarColor(this.currentTabIndex)
      }
    })
  }

  @Builder
  private SideTabBar() {
    Column() {
      Text('麦麦')
        .fontSize(this.isLargeTabletLayout() ? 22 : 20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ top: 28, bottom: 24 })

      this.SideTabItem('首页', 0)
      this.SideTabItem('麦麦AI', 1)
      this.SideTabItem('我的', 2)
      Blank()
    }
    .width(ResponsiveLayout.getNavigationWidth(this.rootWidth))
    .height('100%')
    .backgroundColor('#FFFFFF')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private SideTabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTabIndex === index ? '#1677FF' : '#555555')
    }
    .width(this.isLargeTabletLayout() ? 88 : 76)
    .height(this.isLargeTabletLayout() ? 52 : 48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentTabIndex === index ? '#EEF5FF' : '#00000000')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.changeRootTab(index)
    })
  }

  @Builder
  private PageMap(name: string, param: object) {
    if (name === AppNavRoute.SEARCH) {
      SearchPage({ navParams: param as SearchNavParams })
    } else if (name === AppNavRoute.SEARCH_RESULT) {
      SearchResultPage({ navParams: param as SearchResultNavParams })
    } else if (name === AppNavRoute.CATEGORY) {
      CategoryPage({ navParams: param as CategoryNavParams })
    } else if (name === AppNavRoute.WANT) {
      WantPage({ navParams: param as WantNavParams })
    } else if (name === AppNavRoute.PERFORMANCE_DETAIL) {
      PerformanceDetailPage({ navParams: param as PerformanceDetailNavParams })
    } else if (name === AppNavRoute.PERFORMANCE_VIDEO_FULLSCREEN) {
      PerformanceVideoFullscreenPage({ navParams: param as PerformanceVideoFullscreenNavParams })
    } else if (name === AppNavRoute.TICKET_SELECT) {
      TicketSelectPage({ navParams: param as TicketSelectNavParams })
    } else if (name === AppNavRoute.SUBMIT_ORDER) {
      SubmitOrderPage({ navParams: param as SubmitOrderNavParams })
    } else if (name === AppNavRoute.PAY_SUCCESS) {
      PaySuccessPage({ navParams: param as PaySuccessNavParams })
    } else if (name === AppNavRoute.ORDER_LIST) {
      OrderListPage({ navParams: param as OrderListNavParams })
    } else if (name === AppNavRoute.ORDER_DETAIL) {
      OrderDetailPage({ navParams: param as OrderDetailNavParams })
    } else if (name === AppNavRoute.REFUND_APPLY) {
      RefundApplyPage({ navParams: param as RefundApplyNavParams })
    } else if (name === AppNavRoute.TICKET_FOLDER) {
      TicketFolderPage({ navParams: param as TicketFolderNavParams })
    } else if (name === AppNavRoute.TICKET_DETAIL) {
      TicketDetailPage({ navParams: param as TicketDetailNavParams })
    }
  }

  @Builder
  private BottomTabBar() {
    Row() {
      this.BottomTabItem('首页', 0)
      this.BottomTabItem('麦麦AI', 1)
      this.BottomTabItem('我的', 2)
    }
    .width('100%')
    .height(80)
    .padding({ bottom: 8 })
    .backgroundColor('#FFFFFF')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  private BottomTabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTabIndex === index ? '#1677FF' : '#333333')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.changeRootTab(index)
    })
  }

  private changeRootTab(index: number): void {
    if (this.currentTabIndex === index) {
      return
    }
    this.navStack.clear()
    if (this.currentTabIndex === 1) {
      this.aiHistoryVisible = false
      this.aiKeyboardVisible = false
    }
    this.currentTabIndex = index
    this.updateSystemBarColor(index)
  }

  private onEntryRequestChanged(): void {
    this.dispatchEntryRequest()
  }

  private dispatchEntryRequest(): void {
    const request: EntryDispatchRequest | undefined = EntryDispatcher.consume()
    if (request === undefined) {
      return
    }
    if (request.target === ServiceCardTarget.LOGIN) {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' }).catch((): void => {
      })
      return
    }
    const accountTarget: boolean = request.target === ServiceCardTarget.ORDER_DETAIL ||
      request.target === ServiceCardTarget.TICKET_DETAIL
    if (accountTarget) {
      const currentUserId: string = AppStorage.get<string>('login_user_id') ?? ''
      const loggedIn: boolean = AppStorage.get<boolean>('login_status') ?? false
      if (!loggedIn || currentUserId.length === 0) {
        this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' }).catch((): void => {
        })
        return
      }
      if (request.userId !== currentUserId) {
        this.navStack.clear()
        this.currentTabIndex = 0
        this.updateSystemBarColor(0)
        return
      }
    }
    if (request.target === ServiceCardTarget.ORDER_DETAIL && request.userId.length > 0 && request.orderId.length > 0) {
      AppNavigator.openOrderDetail(this.navStack, {
        userId: request.userId,
        orderId: request.orderId
      })
      return
    }
    if (request.target === ServiceCardTarget.TICKET_DETAIL && request.userId.length > 0 && request.orderId.length > 0) {
      AppNavigator.openTicketDetail(this.navStack, {
        userId: request.userId,
        orderId: request.orderId,
        ticketId: request.ticketId
      })
      return
    }
    if (request.target === ServiceCardTarget.PERFORMANCE_DETAIL && request.projectId.length > 0) {
      AppNavigator.openPerformanceDetail(this.navStack, {
        projectId: request.projectId,
        sessionId: request.sessionId
      })
      return
    }
    this.navStack.clear()
    this.currentTabIndex = 0
    this.updateSystemBarColor(0)
  }

  private updateSystemBarColor(index: number): void {
    if (index === 2) {
      WindowImmersiveUtil.apply(this, '#FFEDEF', '#FFFFFF')
      return
    }

    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
  }

  private useSideNavigation(): boolean {
    return ResponsiveLayout.useSideNavigation(this.rootWidth)
  }

  private isLargeTabletLayout(): boolean {
    const sideWidth: number = ResponsiveLayout.getNavigationWidth(this.rootWidth)
    return ResponsiveLayout.isLargeTabletWidth(Math.max(0, this.rootWidth - sideWidth))
  }
}
