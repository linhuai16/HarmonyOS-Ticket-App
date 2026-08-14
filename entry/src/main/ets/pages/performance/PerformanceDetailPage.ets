import router from '@ohos.router'
import { webview } from '@kit.ArkWeb'
import { common } from '@kit.AbilityKit'

import {
  PerformanceDetailVO,
  PerformanceSessionItemVO,
  ServiceTagVO,
  NoticeItemVO,
  VenueDisplayVO
} from '../../model/vo/performance/PerformanceDetailVO'

import { PerformanceDetailViewModel } from '../../viewmodel/PerformanceDetailViewModel'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { CityRepository } from '../../repository/CityRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { RichTextHtmlUtil } from '../../common/RichTextHtmlUtil'
import { VenueNavigationUtil } from '../../utils/VenueNavigationUtil'
interface DetailRouteParams {
  projectId?: string
  sessionId?: string
  userId?: string
}


@Entry
@Component
export struct PerformanceDetailPage {
  private vm: PerformanceDetailViewModel = new PerformanceDetailViewModel()
  private userRepository: UserRepository = new UserRepository()
  private cityRepository: CityRepository = new CityRepository()
  private detailWebController: webview.WebviewController = new webview.WebviewController()

  @State detailVO: PerformanceDetailVO | undefined = undefined
  @State pageVersion: number = 0
  @State selectedSessionId: string = ''
  @State selectedStartTime: string = ''
  @State isWanted: boolean = false
  @State canBuy: boolean = false
  @State buyButtonText: string = '不可购票'
  @State selectedMinPrice: number | undefined = undefined
  @State selectedMaxPrice: number | undefined = undefined
  @State selectedVenueName: string = ''
  @State selectedVenueAddress: string = ''
  @State selectedVenueLongitude: number = 0
  @State selectedVenueLatitude: number = 0
  @State hasSelectedVenueCoordinate: boolean = false
  @State selectedDetailContent: string = ''
  @State errorMessage: string = ''
  @State isLoading: boolean = false
  @State isRefreshingPage: boolean = false
  @StorageLink('performance_changed_version') @Watch('onPerformanceDataChanged') performanceChangedVersion: number = 0
  @StorageLink('want_changed_version') @Watch('onPerformanceDataChanged') wantChangedVersion: number = 0
  @StorageLink('login_version') @Watch('onPerformanceDataChanged') loginVersion: number = 0
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    const params = router.getParams() as DetailRouteParams
    this.initPage(params)
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    this.pendingExternalRefresh = false
    this.reloadCurrentDetail()
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  private onPerformanceDataChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadCurrentDetail()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.RefreshMarker()
        this.TopBar()

        if (this.detailVO === undefined) {
          this.EmptyArea()
        } else {
          Scroll() {
            Column() {
              this.ProjectInfo()
              this.SessionArea()
              this.VenueArea()
              this.ServiceTagArea()
              this.DetailContentArea()
              this.NoticeArea()
              Blank().height(80)
            }
            .width('100%')
            .padding({ left: 12, right: 12, bottom: 12 })
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      this.BottomActionBar()
    }
    .width('100%')
    .height('100%')
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

      Text('演出详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 4 })

      Blank()
      Text(this.isRefreshingPage ? '刷新中' : '刷新')
        .fontSize(14)
        .fontColor(this.isRefreshingPage ? '#BBBBBB' : '#E33B3B')
        .height(44)
        .padding({ left: 10, right: 4 })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (!this.isRefreshingPage) this.manualRefreshDetail()
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 8, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text(this.errorMessage.length > 0 ? this.errorMessage : '演出详情不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private ProjectInfo() {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia((this.detailVO as PerformanceDetailVO).posterUrl))
          .width(118)
          .height(158)
          .objectFit(ImageFit.Cover)
          .borderRadius(10)

        Text((this.detailVO as PerformanceDetailVO).categoryName)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#E33B3B')
          .borderRadius({ topLeft: 10, bottomRight: 8 })
      }

      Column() {
        Text((this.detailVO as PerformanceDetailVO).title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.selectedStartTime)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 12 })
          .width('100%')

        Text(this.getSelectedPriceRangeText())
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E33B3B')
          .margin({ top: 12 })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private SessionArea() {
    Column() {
      Text('场次选择')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Scroll() {
        Row() {
          ForEach((this.detailVO as PerformanceDetailVO).sessions, (item: PerformanceSessionItemVO) => {
            Column() {
              Text(item.stationName)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.selectedSessionId === item.sessionId ? '#E33B3B' : '#222222')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(item.startTime)
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.getSessionStatusText(item.sessionStatus))
                .fontSize(11)
                .fontColor(this.selectedSessionId === item.sessionId ? '#E33B3B' : '#999999')
                .margin({ top: 4 })
            }
            .width(120)
            .height(86)
            .padding(10)
            .margin({ right: 8, top: 10 })
            .backgroundColor(this.selectedSessionId === item.sessionId ? '#FFECEC' : '#F7F7F7')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.handleChangeSession(item.sessionId)
            })
          }, (item: PerformanceSessionItemVO) => item.sessionId + '_' + item.sessionStatus + '_' + item.cityName + '_' + item.stationName + '_' + item.startTime + '_' + String(this.pageVersion))
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Top)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private VenueArea() {
    Column() {
      Text(this.selectedVenueName.length > 0 ? this.selectedVenueName : '暂无场馆信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Text(this.selectedVenueAddress.length > 0 ? this.selectedVenueAddress : '暂无场馆地址')
        .fontSize(13)
        .fontColor('#666666')
        .margin({ top: 8 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      VenueNavigationUtil.open(context, this.selectedVenueName, this.selectedVenueAddress,
        this.hasSelectedVenueCoordinate ? this.selectedVenueLatitude : undefined,
        this.hasSelectedVenueCoordinate ? this.selectedVenueLongitude : undefined)
    })
  }

  @Builder
  private ServiceTagArea() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach((this.detailVO as PerformanceDetailVO).serviceTags, (item: ServiceTagVO) => {
        Row() {
          if (item.iconUrl !== undefined) {
            Image(MediaResourceUtil.getMedia(item.iconUrl))
              .width(16)
              .height(16)
              .margin({ right: 4 })
          }

          Text(item.tagName)
            .fontSize(13)
            .fontColor('#333333')
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .margin({ right: 8, top: 10 })
        .backgroundColor('#F7F7F7')
        .borderRadius(15)
        .onClick(() => {
          this.showServiceTagDialog(item)
        })
      }, (item: ServiceTagVO) => item.tagId)
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private DetailContentArea() {
    Column() {
      Text('演出详情')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Web({
        src: RichTextHtmlUtil.buildDataUrl(this.selectedDetailContent),
        controller: this.detailWebController
      })
        .width('100%')
        .height(RichTextHtmlUtil.estimateHeight(this.selectedDetailContent))
        .margin({ top: 8 })
        .javaScriptAccess(false)
        .domStorageAccess(false)
        .zoomAccess(false)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private NoticeArea() {
    Column() {
      Text('观演须知')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Grid() {
        ForEach((this.detailVO as PerformanceDetailVO).noticeItems, (item: NoticeItemVO) => {
          GridItem() {
            Column() {
              Row() {
                if (item.iconUrl !== undefined) {
                  Image(MediaResourceUtil.getMedia(item.iconUrl))
                    .width(18)
                    .height(18)
                    .margin({ right: 6 })
                }

                Text(item.title)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')

              Text(item.description)
                .fontSize(11)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
                .width('100%')
            }
            .width('100%')
            .height(54)
            .padding(8)
            .backgroundColor('#F7F7F7')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.showNoticeDialog(item)
            })
          }
        }, (item: NoticeItemVO) => item.noticeId)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .margin({ top: 10 })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private BottomActionBar() {
    Row() {
      Column() {
        Image($r('app.media.page_xiangkan'))
          .width(22)
          .height(22)
          .fillColor(this.isWanted ? '#E33B3B' : '#666666')

        Text(this.isWanted ? '已想看' : '想看')
          .fontSize(12)
          .fontColor(this.isWanted ? '#E33B3B' : '#666666')
          .margin({ top: 2 })
      }
      .width(70)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        const currentUserId: string = this.getCurrentUserId()

        if (currentUserId.length === 0 || !this.userRepository.isLogin()) {
          router.pushUrl({ url: 'pages/user/LoginPage' })
          return
        }

        this.vm.userId = currentUserId
        this.toggleWant()
        this.syncFromVm()
      })

      Button(this.buyButtonText)
        .height(44)
        .layoutWeight(1)
        .fontSize(16)
        .backgroundColor(this.canBuy ? '#E33B3B' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .borderRadius(22)
        .enabled(this.canBuy)
        .onClick(() => {
          if (!this.canBuy) {
            return
          }

          router.pushUrl({
            url: 'pages/performance/TicketSelectPage',
            params: {
              projectId: this.vm.projectId,
              selectedSessionId: this.selectedSessionId
            }
          })
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private showServiceTagDialog(item: ServiceTagVO): void {
    AlertDialog.show({
      title: item.tagName,
      message: item.description ?? '暂无服务说明',
      primaryButton: { value: '知道了', action: () => {} }
    })
  }

  private showNoticeDialog(item: NoticeItemVO): void {
    AlertDialog.show({
      title: item.title,
      message: item.description,
      primaryButton: { value: '知道了', action: () => {} }
    })
  }

  private async initPage(params: DetailRouteParams): Promise<void> {
    const projectId: string = params.projectId ?? ''
    const sessionId: string = params.sessionId ?? ''
    const userId: string = params.userId ?? this.getCurrentUserId()
    const cityName: string = this.cityRepository.getCurrentCity()

    if (projectId.length === 0) {
      this.vm.errorMessage = '演出项目不存在'
      this.syncFromVm()
      return
    }

    if (sessionId.length > 0) {
      await this.vm.loadDetail(projectId, cityName, sessionId, userId)
    } else {
      await this.vm.loadDetailByProject(projectId, cityName, userId)
    }

    this.syncFromVm()
  }

  private async reloadCurrentDetail(): Promise<void> {
    const currentUserId: string = this.getCurrentUserId()

    if (this.vm.projectId.length > 0 && this.vm.getSelectedSessionId().length > 0) {
      await this.vm.loadDetail(this.vm.projectId, this.cityRepository.getCurrentCity(), this.vm.getSelectedSessionId(), currentUserId)
      this.syncFromVm()
    }
  }

  private async manualRefreshDetail(): Promise<void> {
    if (this.isRefreshingPage) return
    this.isRefreshingPage = true
    await this.reloadCurrentDetail()
    this.isRefreshingPage = false
  }

  private async handleChangeSession(sessionId: string): Promise<void> {
    await this.vm.changeSession(sessionId, this.cityRepository.getCurrentCity())
    this.syncFromVm()
  }

  private getCurrentUserId(): string {
    const user = this.userRepository.getCurrentUser()
    return user?.userId ?? ''
  }

  private getSelectedPriceRangeText(): string {
    if (this.selectedMinPrice === undefined && this.selectedMaxPrice === undefined) {
      return ''
    }

    if (this.selectedMinPrice !== undefined && this.selectedMaxPrice !== undefined && this.selectedMinPrice !== this.selectedMaxPrice) {
      return '￥' + this.selectedMinPrice + ' - ' + this.selectedMaxPrice
    }

    if (this.selectedMinPrice !== undefined) {
      return '￥' + this.selectedMinPrice + ' 起'
    }

    return '￥' + this.selectedMaxPrice
  }

  private getSessionStatusText(status: SessionStatus): string {
    if (status === SessionStatus.PRESALE) return '预售'
    if (status === SessionStatus.ON_SALE) return '热卖'
    if (status === SessionStatus.SOLD_OUT) return '已售罄'
    if (status === SessionStatus.ENDED) return '已结束'
    return ''
  }

  private syncFromVm(): void {
    const detail: PerformanceDetailVO | undefined = this.vm.detailVO

    this.detailVO = this.cloneDetailVO(detail)
    this.selectedSessionId = this.vm.getSelectedSessionId()
    this.selectedStartTime = this.vm.selectedSession?.startTime ?? ''
    this.selectedMinPrice = detail?.minPrice
    this.selectedMaxPrice = detail?.maxPrice
    this.selectedVenueName = detail?.venue.venueName ?? ''
    this.selectedVenueAddress = detail?.venue.venueAddress ?? ''
    this.hasSelectedVenueCoordinate = detail?.venue.latitude !== undefined && detail?.venue.longitude !== undefined
    this.selectedVenueLatitude = detail?.venue.latitude ?? 0
    this.selectedVenueLongitude = detail?.venue.longitude ?? 0
    this.selectedDetailContent = detail?.detailContent ?? ''
    this.isWanted = detail?.isWanted ?? false
    this.canBuy = this.vm.canBuyCurrentSession()
    this.buyButtonText = this.buildBuyButtonText()
    this.errorMessage = this.vm.errorMessage
    this.isLoading = this.vm.isLoading
    this.pageVersion++
  }

  private buildBuyButtonText(): string {
    if (this.vm.selectedSession === undefined) {
      return '不可购票'
    }

    if (this.vm.selectedSession.sessionStatus === SessionStatus.PRESALE) {
      return '立即预订'
    }

    if (this.vm.selectedSession.sessionStatus === SessionStatus.ON_SALE) {
      return '立即购票'
    }

    if (this.vm.selectedSession.sessionStatus === SessionStatus.SOLD_OUT) {
      return '已售罄'
    }

    return '不可购票'
  }

  private cloneDetailVO(source: PerformanceDetailVO | undefined): PerformanceDetailVO | undefined {
    if (source === undefined) {
      return undefined
    }

    const sessions: PerformanceSessionItemVO[] = []
    source.sessions.forEach((item: PerformanceSessionItemVO) => {
      sessions.push({
        sessionId: item.sessionId,
        cityName: item.cityName,
        stationName: item.stationName,
        startTime: item.startTime,
        sessionStatus: item.sessionStatus
      })
    })

    const venue: VenueDisplayVO = {
      venueId: source.venue.venueId,
      venueName: source.venue.venueName,
      venueAddress: source.venue.venueAddress,
      longitude: source.venue.longitude,
      latitude: source.venue.latitude
    }

    const serviceTags: ServiceTagVO[] = []
    source.serviceTags.forEach((item: ServiceTagVO) => {
      serviceTags.push({
        tagId: item.tagId,
        tagName: item.tagName,
        iconUrl: item.iconUrl,
        description: item.description
      })
    })

    const noticeItems: NoticeItemVO[] = []
    source.noticeItems.forEach((item: NoticeItemVO) => {
      noticeItems.push({
        noticeId: item.noticeId,
        title: item.title,
        iconUrl: item.iconUrl,
        description: item.description
      })
    })

    const result: PerformanceDetailVO = {
      projectId: source.projectId,
      selectedSessionId: source.selectedSessionId,
      posterUrl: source.posterUrl,
      title: source.title,
      categoryName: source.categoryName,
      minPrice: source.minPrice,
      maxPrice: source.maxPrice,
      isWanted: source.isWanted,
      sessions: sessions,
      venue: venue,
      serviceTags: serviceTags,
      detailContent: source.detailContent,
      noticeItems: noticeItems
    }

    return result
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
  private async toggleWant(): Promise<void> {
    await this.vm.toggleWant()
    this.syncFromVm()
  }

}
