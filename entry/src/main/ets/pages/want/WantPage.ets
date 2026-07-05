import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  WantPerformanceItemVO
} from '../../model/vo/want/WantListPageVO'

import {
  WantViewModel,
  WantDetailJumpParams
} from '../../viewmodel/WantViewModel'

import { ProjectStatus } from '../../model/enums/ProjectStatus'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

interface WantRouteParams {
  userId?: string
}

@Entry
@Component
struct WantPage {
  private vm: WantViewModel = new WantViewModel()

  @State userId: string = ''
  @State items: WantPerformanceItemVO[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentWantList()
  }

  private loadPageData(): void {
    const params: WantRouteParams | undefined = router.getParams() as WantRouteParams | undefined
    const userId: string = params?.userId ?? 'user_001'

    this.vm.loadPage(userId)
    this.syncFromVm()
  }

  private reloadCurrentWantList(): void {
    if (this.userId.length === 0) {
      return
    }

    this.vm.loadPage(this.userId)
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.items = [...this.vm.items]
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.pageVersion++
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()

      if (this.items.length === 0) {
        this.EmptyArea()
      } else {
        List() {
          ForEach(this.items, (item: WantPerformanceItemVO) => {
            ListItem() {
              this.WantCard(item)
            }
          }, (item: WantPerformanceItemVO) => item.wantId)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12 })
        .clip(true)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
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

      Text('我的想看')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 8 })

      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private EmptyArea() {
    Column() {
      Text('暂无想看的演出')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private WantCard(item: WantPerformanceItemVO) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(MediaResourceUtil.getMedia(item.posterUrl))
            .width(92)
            .height(124)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)

          Text(item.categoryName)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .backgroundColor('#E33B3B')
            .borderRadius({ topLeft: 8, bottomRight: 8 })
        }

        Column() {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textAlign(TextAlign.Start)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(item.startTime)
            .fontSize(13)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
            .margin({ top: 8 })

          Text(item.venueName)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textAlign(TextAlign.Start)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })

          Text(this.getPriceText(item))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E33B3B')
            .textAlign(TextAlign.Start)
            .margin({ top: 8 })

          Text(this.getStatusText(item))
            .fontSize(12)
            .fontColor('#999999')
            .textAlign(TextAlign.Start)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      .onClick(() => {
        this.jumpDetail(item)
      })

      Row() {
        Text('取消想看')
          .fontSize(13)
          .fontColor('#999999')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#F1F1F1')
          .borderRadius(14)
          .onClick(() => {
            this.cancelWant(item.projectId)
          })

        Blank()

        Button(this.getActionButtonText(item))
          .height(34)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16 })
          .backgroundColor(this.canBuyOrReserve(item) ? '#E33B3B' : '#CCCCCC')
          .enabled(this.canBuyOrReserve(item))
          .onClick(() => {
            this.jumpDetail(item)
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private jumpDetail(item: WantPerformanceItemVO): void {
    const params: WantDetailJumpParams = this.vm.buildDetailJumpParams(item)

    router.pushUrl({
      url: 'pages/performance/PerformanceDetailPage',
      params: {
        projectId: params.projectId,
        sessionId: params.sessionId
      }
    })
  }

  private cancelWant(projectId: string): void {
    const success: boolean = this.vm.cancelWant(projectId)
    this.syncFromVm()

    promptAction.showToast({
      message: success ? '取消想看成功' : this.errorMessage
    })
  }

  private getPriceText(item: WantPerformanceItemVO): string {
    if (item.minPrice === undefined) {
      return ''
    }

    return '￥' + item.minPrice + ' 起'
  }

  private getActionButtonText(item: WantPerformanceItemVO): string {
    if (item.sessionStatus === SessionStatus.PRESALE) {
      return '预订'
    }

    if (item.sessionStatus === SessionStatus.ON_SALE) {
      return '购票'
    }

    if (item.sessionStatus === SessionStatus.SOLD_OUT) {
      return '已售罄'
    }

    return '不可购票'
  }

  private getStatusText(item: WantPerformanceItemVO): string {
    if (item.projectStatus === ProjectStatus.ENDED) {
      return '项目已结束'
    }

    if (item.sessionStatus === SessionStatus.PRESALE) {
      return '预售中'
    }

    if (item.sessionStatus === SessionStatus.ON_SALE) {
      return '售卖中'
    }

    if (item.sessionStatus === SessionStatus.SOLD_OUT) {
      return '已售罄'
    }

    if (item.sessionStatus === SessionStatus.ENDED) {
      return '已结束'
    }

    return ''
  }

  private canBuyOrReserve(item: WantPerformanceItemVO): boolean {
    return item.sessionStatus === SessionStatus.PRESALE ||
      item.sessionStatus === SessionStatus.ON_SALE
  }
}
