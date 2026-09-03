
import { AudienceItemVO } from '../../model/vo/user/AudiencePageVO'
import { AudienceViewModel } from '../../viewmodel/AudienceViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
interface AudienceRouteParams {
  userId?: string
}


@Entry
@Component
struct AudiencePage {
  private vm: AudienceViewModel = new AudienceViewModel()
  private userRepository: UserRepository = new UserRepository()

  @StorageLink('audience_changed_version')
  @Watch('onAudienceChanged')
  audienceChangedVersion: number = 0

  @State userId: string = ''
  @State audienceList: AudienceItemVO[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0
  @State breakPoint: string = 'sm'
  @State tabletListWidth: number = 0
  private hasShownOnce: boolean = false
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.isPageVisible = true
    if (this.hasShownOnce) {
      this.pendingExternalRefresh = false
      this.reloadCurrentUserList()
    }
    this.hasShownOnce = true
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  private onAudienceChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadCurrentUserList()
  }

  private async reloadCurrentUserList(): Promise<void> {
    if (!this.userRepository.isLogin()) {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    const effectiveUserId: string = this.userId.length > 0 ? this.userId : currentUserId

    if (effectiveUserId.length === 0) {
      return
    }

    await this.vm.loadList(effectiveUserId)
    this.syncFromVm()
  }

  private async loadPageData(): Promise<void> {
    const params: AudienceRouteParams = (this.getUIContext().getRouter().getParams() ?? {}) as AudienceRouteParams
    const routeUserId: string = params.userId ?? ''
    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    const userId: string = routeUserId.length > 0 ? routeUserId : currentUserId

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.isLoading = true
    await this.vm.loadList(userId)
    this.syncFromVm()
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.audienceList = [...this.vm.audienceList]
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.pageVersion++
  }

  build() {
    GridRow({
        columns: { sm: 4, md: 8, lg: 12, xl: 12 },
      breakpoints: {
          value: ['600vp', '840vp', '1440vp'],
        reference: BreakpointsReference.WindowSize
      }
      }) {
        GridCol({ span: { sm: 4, md: 8, lg: 12, xl: 12 } }) {
          Stack({ alignContent: Alignment.Bottom }) {
            Column() {
              this.RefreshMarker()
              this.TopBar()

              Column() {
                this.TipArea()
                this.ListArea()
                Blank().height(this.isTabletLayout() ? 76 : 68)
              }
              .width('100%')
              .constraintSize({ maxWidth: ResponsiveLayout.COLLECTION_MAX_WIDTH })
              .layoutWeight(1)
            }
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#F5F5F5')

            this.BottomButton()
          }
          .width('100%')
          .height('100%')
        }
    }
    .width('100%')
    .height('100%')
    .onBreakpointChange((breakpoint: string) => {
      this.breakPoint = breakpoint
    })
  }

  @Builder
  private RefreshMarker() {
    Text(`${this.pageVersion}`)
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
          this.getUIContext().getRouter().back()
        })

      Text('观演人信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 8 })

      Blank()
      Button() {
        Image($r('app.media.refrech'))
          .width(18)
          .height(18)
          .fillColor(this.isLoading ? '#BBBBBB' : '#666666')
      }
        .width(40)
        .height(40)
        .backgroundColor('#00000000')
        .enabled(!this.isLoading)
        .onClick(() => { this.loadPageData() })
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  private TipArea() {
    Text('温馨提示：实名制演出需要添加观演人信息，购票时请确保信息准确无误')
      .fontSize(this.isTabletLayout() ? 15 : 13)
      .fontColor('#E33B3B')
      .lineHeight(this.isTabletLayout() ? 24 : 20)
      .width('100%')
      .padding(this.isTabletLayout() ? 16 : 12)
      .backgroundColor('#FFF1F1')
  }

  @Builder
  private ListArea() {
    if (this.isLoading && this.audienceList.length === 0) {
      this.LoadingArea('正在加载观演人信息...')
    } else if (this.audienceList.length === 0 && this.errorMessage.length > 0) {
      this.ErrorArea(this.errorMessage)
    } else if (this.audienceList.length === 0) {
      Column() {
        Text('暂无观演人信息')
          .fontSize(15)
          .fontColor('#999999')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.isTabletLayout()) {
      Grid() {
        ForEach(this.audienceList, (item: AudienceItemVO) => {
          GridItem() {
            this.AudienceCard(item)
          }
        }, (item: AudienceItemVO) => {
          return `${item.audienceId}_${item.realName}_${item.maskedCertificateNo}_${item.maskedPhone ?? ''}_${item.isDefault}`
        })
      }
      .columnsTemplate(ResponsiveLayout.getGridTemplate(this.getTabletGridColumnCount()))
      .columnsGap(16)
      .rowsGap(16)
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const nextWidth: number = Number(newValue.width ?? 0)
        if (Math.abs(nextWidth - this.tabletListWidth) > 0.5) {
          this.tabletListWidth = nextWidth
        }
      })
    } else {
      List() {
        ForEach(this.audienceList, (item: AudienceItemVO) => {
          ListItem() {
            this.AudienceCard(item)
          }
        }, (item: AudienceItemVO) => {
          return `${item.audienceId}_${item.realName}_${item.maskedCertificateNo}_${item.maskedPhone ?? ''}_${item.isDefault}`
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
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
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private ErrorArea(message: string) {
    Column() {
      Text(message)
        .fontSize(15)
        .fontColor('#E33B3B')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })

      Text('点击重试')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .padding({ left: 18, right: 18, top: 8, bottom: 8 })
        .margin({ top: 14 })
        .backgroundColor('#E33B3B')
        .borderRadius(18)
        .onClick(() => {
          this.reloadCurrentUserList()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private AudienceCard(item: AudienceItemVO) {
    Column() {
      Row() {
        Text(item.realName)
          .fontSize(this.isTabletLayout() ? 19 : 17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        if (item.isDefault) {
          Text('默认')
            .fontSize(11)
            .fontColor('#E33B3B')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 8 })
            .backgroundColor('#FFECEC')
            .borderRadius(8)
        }

        Blank()

        Text('编辑')
          .fontSize(13)
          .fontColor('#E33B3B')
          .padding({ left: 8, right: 4, top: 6, bottom: 6 })
          .onClick(() => {
            this.jumpEdit(item.audienceId)
          })
      }
      .width('100%')

      this.InfoRow('证件号', item.maskedCertificateNo)
      this.InfoRow('手机号', this.getDisplayPhone(item.maskedPhone))

      Row() {
        if (!item.isDefault) {
          Text('设为默认')
            .fontSize(13)
            .fontColor('#E33B3B')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#FFECEC')
            .borderRadius(14)
            .onClick(() => {
              this.setDefaultAudience(item.audienceId)
            })
        }

        Blank()

        Text('删除')
          .fontSize(13)
          .fontColor('#999999')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#F1F1F1')
          .borderRadius(14)
          .onClick(() => {
            this.showDeleteDialog(item.audienceId)
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 14)
    .margin({ top: this.isTabletLayout() ? 0 : 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(this.isTabletLayout() ? 15 : 14)
        .fontColor('#666666')

      Blank()

      Text(value)
        .fontSize(this.isTabletLayout() ? 15 : 14)
        .fontColor('#222222')
    }
    .width('100%')
    .margin({ top: 10 })
  }


  private getDisplayPhone(maskedPhone: string | undefined): string {
    if (maskedPhone === undefined || maskedPhone.length === 0) {
      return '未填写'
    }

    return maskedPhone
  }

  @Builder
  private BottomButton() {
    Row() {
      Button('添加观演人')
        .height(this.isTabletLayout() ? 50 : 44)
        .width('100%')
        .constraintSize({ maxWidth: this.isTabletLayout() ? 520 : 1000 })
        .fontSize(this.isTabletLayout() ? 17 : 16)
        .fontColor('#FFFFFF')
        .backgroundColor('#E33B3B')
        .onClick(() => {
          this.jumpCreate()
        })
    }
    .width('100%')
    .height(this.isTabletLayout() ? 76 : 68)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private isTabletLayout(): boolean {
    return ResponsiveLayout.isTabletBreakpoint(this.breakPoint)
  }

  private getTabletGridColumnCount(): number {
    return Math.min(3, ResponsiveLayout.getTabletGridColumnCount(this.tabletListWidth))
  }

  private jumpCreate(): void {
    if (this.userId.length === 0) {
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/user/AudienceEditPage',
      params: {
        userId: this.userId
      }
    })
  }

  private jumpEdit(audienceId: string): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/user/AudienceEditPage',
      params: {
        userId: this.userId,
        audienceId: audienceId
      }
    })
  }

  private async setDefaultAudience(audienceId: string): Promise<void> {
    const success: boolean = await this.vm.setDefaultAudience(audienceId)
    this.syncFromVm()

    this.getUIContext().getPromptAction().showToast({
      message: success ? '设置成功' : this.errorMessage
    })
  }

  private showDeleteDialog(audienceId: string): void {
    this.getUIContext().showAlertDialog({
      title: '删除观演人',
      message: '确认删除该观演人信息吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.deleteAudience(audienceId)
        }
      }
    })
  }

  private async deleteAudience(audienceId: string): Promise<void> {
    const success: boolean = await this.vm.deleteAudience(audienceId)
    this.syncFromVm()

    this.getUIContext().getPromptAction().showToast({
      message: success ? '删除成功' : this.errorMessage
    })
  }
}
