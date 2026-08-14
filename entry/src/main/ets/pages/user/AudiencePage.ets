import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { AudienceItemVO } from '../../model/vo/user/AudiencePageVO'
import { AudienceViewModel } from '../../viewmodel/AudienceViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
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

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData()
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    this.reloadCurrentUserList()
  }

  private onAudienceChanged(): void {
    this.reloadCurrentUserList()
  }

  private async reloadCurrentUserList(): Promise<void> {
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
    const params: AudienceRouteParams = (router.getParams() ?? {}) as AudienceRouteParams
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
    this.audienceList = [...this.vm.audienceList]
    this.isLoading = this.vm.isLoading
    this.errorMessage = this.vm.errorMessage
    this.pageVersion++
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()
      this.TipArea()
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

      Text('观演人信息')
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
  private TipArea() {
    Text('温馨提示：实名制演出需要添加观演人信息，购票时请确保信息准确无误')
      .fontSize(13)
      .fontColor('#E33B3B')
      .lineHeight(20)
      .width('100%')
      .padding(12)
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
          .fontSize(17)
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
    .padding(14)
    .margin({ top: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
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
      url: 'pages/user/AudienceEditPage',
      params: {
        userId: this.userId
      }
    })
  }

  private jumpEdit(audienceId: string): void {
    router.pushUrl({
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

    promptAction.showToast({
      message: success ? '设置成功' : this.errorMessage
    })
  }

  private showDeleteDialog(audienceId: string): void {
    AlertDialog.show({
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

    promptAction.showToast({
      message: success ? '删除成功' : this.errorMessage
    })
  }
}
