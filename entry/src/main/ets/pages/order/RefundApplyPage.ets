import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import {
  RefundApplyPageVO
} from '../../model/vo/order/RefundApplyPageVO'

import {
  RefundApplyViewModel
} from '../../viewmodel/RefundApplyViewModel'

import {
  RefundOrderResponse
} from '../../repository/RefundRepository'

import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface RefundApplyRouteParams {
  userId?: string
  orderId?: string
}


@Entry
@Component
struct RefundApplyPage {
  private vm: RefundApplyViewModel = new RefundApplyViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State pageVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  private loadPageData(): void {
    const params = router.getParams() as RefundApplyRouteParams

    const userId: string = params.userId ?? this.userRepository.getCurrentUserId()
    const orderId: string = params.orderId ?? ''

    if (userId.length === 0) {
      this.vm.errorMessage = '请先登录后申请退款'
      this.refreshPage()
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    if (orderId.length === 0) {
      this.vm.errorMessage = '退款订单参数不存在'
      this.refreshPage()
      return
    }

    this.vm.loadPage(userId, orderId)
    this.refreshPage()
  }

  build() {
    Column() {
      this.TopBar()

      if (this.vm.pageVO === undefined) {
        this.EmptyArea()
      } else {
        Scroll() {
          Column() {
            this.ProjectArea(this.vm.pageVO)
            this.RefundRuleArea(this.vm.pageVO)
            this.AmountArea(this.vm.pageVO)
            this.ReasonArea()
            Blank().height(92)
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 12 })
        }
        .layoutWeight(1)

        this.BottomButton(this.vm.pageVO)
      }
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

      Text('申请退款')
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
      Text(this.vm.errorMessage.length > 0 ? this.vm.errorMessage : '退款申请数据不存在')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private ProjectArea(pageVO: RefundApplyPageVO) {
    Row() {
      Image(MediaResourceUtil.getMedia(pageVO.posterUrl))
        .width(86)
        .height(114)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      Column() {
        Text(pageVO.projectTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(pageVO.startTime)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 8 })

        Text(pageVO.venueName)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 4 })

        Text(pageVO.skuName + ' x ' + pageVO.quantity)
          .fontSize(13)
          .fontColor('#333333')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private RefundRuleArea(pageVO: RefundApplyPageVO) {
    Column() {
      Text('退款规则')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Text(pageVO.refundRuleText)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(22)
        .margin({ top: 10 })
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private AmountArea(pageVO: RefundApplyPageVO) {
    Column() {
      Text('退款金额')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      this.InfoRow('实付金额', '￥' + pageVO.payAmount)
      this.InfoRow('手续费', '￥' + pageVO.feeAmount)
      this.InfoRow('预估退款金额', '￥' + pageVO.estimatedRefundAmount)

      Text('最终退款金额以退款审核结果为准')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 10 })
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')

      Blank()

      Text(value)
        .fontSize(14)
        .fontColor(label === '预估退款金额' ? '#E33B3B' : '#222222')
        .fontWeight(label === '预估退款金额' ? FontWeight.Bold : FontWeight.Normal)
    }
    .width('100%')
    .height(36)
  }

  @Builder
  private ReasonArea() {
    Column() {
      Text('退款原因')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      TextArea({
        placeholder: '请输入退款原因（选填）',
        text: this.vm.reason
      })
        .height(96)
        .margin({ top: 10 })
        .backgroundColor('#F7F7F7')
        .borderRadius(10)
        .onChange((value: string) => {
          this.vm.changeReason(value)
          this.refreshPage()
        })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private BottomButton(pageVO: RefundApplyPageVO) {
    Row() {
      Button('确认申请退款')
        .height(44)
        .width('100%')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.vm.canSubmit() ? '#E33B3B' : '#CCCCCC')
        .enabled(this.vm.canSubmit())
        .onClick(() => {
          this.submitRefund()
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private submitRefund(): void {
    const response: RefundOrderResponse | undefined = this.vm.submitRefund()

    if (response === undefined) {
      promptAction.showToast({
        message: this.vm.errorMessage.length > 0 ? this.vm.errorMessage : '退款申请失败'
      })
      this.refreshPage()
      return
    }

    promptAction.showToast({
      message: '退款申请已提交'
    })

    // 退款成功后回到来源页，由来源页 onPageShow / StorageLink 重新拉取订单详情。
    // 这里不能 replaceUrl 到新的订单详情页，否则旧订单详情页还留在路由栈里，返回时会看到旧状态。
    router.back()
  }

  private refreshPage(): void {
    this.pageVersion++
  }
}