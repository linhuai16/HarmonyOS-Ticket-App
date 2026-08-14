import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { AddressItemVO } from '../../model/vo/user/AddressPageVO'
import { AddressViewModel } from '../../viewmodel/AddressViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
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

  @StorageLink('address_list_version')
  @Watch('onAddressListVersionChanged')
  addressListVersion: number = 0

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadAddressList()
  }

  private onAddressListVersionChanged(): void {
    this.reloadAddressList()
  }

  private async reloadAddressList(): Promise<void> {
    if (!this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
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
    const params: AddressRouteParams = (router.getParams() ?? {}) as AddressRouteParams
    const routeUserId: string = params.userId ?? ''
    const currentUserId: string = this.userRepository.getCurrentUserId().trim()
    const userId: string = routeUserId.length > 0 ? routeUserId : currentUserId

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

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
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.ListArea()
      this.BottomButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
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
          router.back()
        })

      Text('收货地址')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .margin({ left: 8 })

      Blank()
      Text('刷新')
        .fontSize(14)
        .fontColor('#E33B3B')
        .height(44)
        .padding({ left: 10, right: 4 })
        .textAlign(TextAlign.Center)
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
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Text(item.maskedReceiverPhone)
          .fontSize(14)
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
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(20)
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
    .padding(12)
    .margin({ top: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private BottomButton() {
    Row() {
      Button('新增收货地址')
        .height(44)
        .width('100%')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#E33B3B')
        .onClick(() => {
          this.jumpCreate()
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private jumpCreate(): void {
    if (this.userId.length === 0) {
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    router.pushUrl({
      url: 'pages/user/AddressEditPage',
      params: {
        userId: this.userId
      }
    })
  }

  private jumpEdit(addressId: string): void {
    router.pushUrl({
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

    promptAction.showToast({
      message: success ? '设置成功' : this.errorMessage
    })
  }

  private showDeleteDialog(addressId: string): void {
    AlertDialog.show({
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

    promptAction.showToast({
      message: success ? '删除成功' : this.errorMessage
    })
  }
}
