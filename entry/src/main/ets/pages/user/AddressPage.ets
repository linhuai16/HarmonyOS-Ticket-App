
import { AddressItemVO } from '../../model/vo/user/AddressPageVO'
import { AddressViewModel } from '../../viewmodel/AddressViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
interface AddressRouteParams {
  userId?: string
}


@Entry
@Component
struct AddressPage {
  private vm: AddressViewModel = new AddressViewModel()
  private userRepository: UserRepository = new UserRepository()

  @State userId: string = ''
  @State addressList: AddressItemVO[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State pageVersion: number = 0
  @State breakPoint: string = 'sm'
  @State tabletListWidth: number = 0
  private hasShownOnce: boolean = false
  private isPageVisible: boolean = false
  private pendingExternalRefresh: boolean = false

  @StorageLink('address_list_version')
  @Watch('onAddressListVersionChanged')
  addressListVersion: number = 0

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
      this.reloadAddressList()
    }
    this.hasShownOnce = true
  }

  onPageHide(): void {
    this.isPageVisible = false
  }

  private onAddressListVersionChanged(): void {
    if (!this.isPageVisible) {
      this.pendingExternalRefresh = true
      return
    }
    this.reloadAddressList()
  }

  private async reloadAddressList(): Promise<void> {
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
    const params: AddressRouteParams = (this.getUIContext().getRouter().getParams() ?? {}) as AddressRouteParams
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
    this.addressList = this.vm.addressList.slice()
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

      Text('收货地址')
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
  private ListArea() {
    if (this.isLoading && this.addressList.length === 0) {
      this.LoadingArea('正在加载收货地址...')
    } else if (this.addressList.length === 0 && this.errorMessage.length > 0) {
      this.ErrorArea(this.errorMessage)
    } else if (this.addressList.length === 0) {
      Column() {
        Text('暂无收货地址')
          .fontSize(15)
          .fontColor('#999999')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.isTabletLayout()) {
      Grid() {
        ForEach(this.addressList, (item: AddressItemVO) => {
          GridItem() {
            this.AddressCard(item)
          }
        }, (item: AddressItemVO) => {
          return `${item.addressId}_${item.receiverName}_${item.maskedReceiverPhone}_${item.fullAddress}_${item.isDefault}`
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
        ForEach(this.addressList, (item: AddressItemVO) => {
          ListItem() {
            this.AddressCard(item)
          }
        }, (item: AddressItemVO) => {
          return `${item.addressId}_${item.receiverName}_${item.maskedReceiverPhone}_${item.fullAddress}_${item.isDefault}`
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8 })
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
          this.reloadAddressList()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private AddressCard(item: AddressItemVO) {
    Column() {
      Row() {
        Text(item.receiverName)
          .fontSize(this.isTabletLayout() ? 19 : 17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Text(item.maskedReceiverPhone)
          .fontSize(this.isTabletLayout() ? 15 : 14)
          .fontColor('#666666')
          .margin({ left: 10 })

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
          .onClick(() => {
            this.jumpEdit(item.addressId)
          })
      }
      .width('100%')

      Text(item.fullAddress)
        .fontSize(this.isTabletLayout() ? 15 : 14)
        .fontColor('#666666')
        .lineHeight(this.isTabletLayout() ? 23 : 20)
        .margin({ top: 10 })
        .width('100%')

      Row() {
        if (!item.isDefault) {
          Text('设为默认')
            .fontSize(13)
            .fontColor('#E33B3B')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#FFECEC')
            .borderRadius(14)
            .onClick(() => {
              this.setDefaultAddress(item.addressId)
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
            this.showDeleteDialog(item.addressId)
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 18 : 12)
    .margin({ top: this.isTabletLayout() ? 0 : 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private BottomButton() {
    Row() {
      Button('新增收货地址')
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
      url: 'pages/user/AddressEditPage',
      params: {
        userId: this.userId
      }
    })
  }

  private jumpEdit(addressId: string): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/user/AddressEditPage',
      params: {
        userId: this.userId,
        addressId: addressId
      }
    })
  }

  private async setDefaultAddress(addressId: string): Promise<void> {
    const success: boolean = await this.vm.setDefaultAddress(addressId)
    this.syncFromVm()

    this.getUIContext().getPromptAction().showToast({
      message: success ? '设置成功' : this.errorMessage
    })
  }

  private showDeleteDialog(addressId: string): void {
    this.getUIContext().showAlertDialog({
      title: '删除地址',
      message: '确认删除该收货地址吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.deleteAddress(addressId)
        }
      }
    })
  }

  private async deleteAddress(addressId: string): Promise<void> {
    const success: boolean = await this.vm.deleteAddress(addressId)
    this.syncFromVm()

    this.getUIContext().getPromptAction().showToast({
      message: success ? '删除成功' : this.errorMessage
    })
  }
}
