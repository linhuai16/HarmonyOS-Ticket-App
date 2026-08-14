import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { AudienceViewModel } from '../../viewmodel/AudienceViewModel'
import { CertificateType } from '../../model/enums/CertificateType'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
interface AudienceEditRouteParams {
  userId?: string
  audienceId?: string
  from?: string
}


@Entry
@Component
struct AudienceEditPage {
  private vm: AudienceViewModel = new AudienceViewModel()
  private userRepository: UserRepository = new UserRepository()

  private routeUserId: string = ''
  private routeAudienceId: string = ''
  private routeFrom: string = ''
  private hasLoadedPageData: boolean = false
  private lastLoadKey: string = ''
  private isWaitingLoginBack: boolean = false

  @State inputRefreshVersion: number = 0
  @State userId: string = ''
  @State from: string = ''
  @State realName: string = ''
  @State certificateType: CertificateType = CertificateType.ID_CARD
  @State certificateNo: string = ''
  @State phone: string = ''
  @State isDefault: boolean = false
  @State isAgreeRule: boolean = false
  @State canSaveValue: boolean = false
  @State errorMessage: string = ''

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.loadPageData(true)
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    if (this.isWaitingLoginBack || !this.hasLoadedPageData) {
      this.loadPageData(false)
    }
  }

  private async loadPageData(allowLoginRedirect: boolean): Promise<void> {
    const params: AudienceEditRouteParams = this.getRouteParams()
    const userId: string = this.resolveEffectiveUserId(params.userId ?? '')
    const audienceId: string = params.audienceId ?? ''
    const from: string = params.from ?? ''

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      if (allowLoginRedirect && !this.isWaitingLoginBack) {
        this.isWaitingLoginBack = true
        router.pushUrl({ url: 'pages/user/LoginPage' })
      }
      return
    }

    const loadKey: string = `${userId}_${audienceId}_${from}`
    if (this.hasLoadedPageData && this.lastLoadKey === loadKey) {
      return
    }

    this.from = from

    if (audienceId.length > 0) {
      await this.vm.loadDetail(userId, audienceId)
      this.isAgreeRule = true
    } else {
      this.vm.resetForm(userId)
      this.isAgreeRule = false
    }

    this.hasLoadedPageData = true
    this.lastLoadKey = loadKey
    this.isWaitingLoginBack = false
    this.syncFromVm()
    this.refreshInputText()
  }

  private getRouteParams(): AudienceEditRouteParams {
    const rawParams: AudienceEditRouteParams | undefined = router.getParams() as AudienceEditRouteParams | undefined

    if (rawParams !== undefined && rawParams !== null) {
      if (rawParams.userId !== undefined) {
        this.routeUserId = rawParams.userId
      }
      if (rawParams.audienceId !== undefined) {
        this.routeAudienceId = rawParams.audienceId
      }
      if (rawParams.from !== undefined) {
        this.routeFrom = rawParams.from
      }
    }

    const params: AudienceEditRouteParams = {
      userId: this.routeUserId,
      audienceId: this.routeAudienceId,
      from: this.routeFrom
    }
    return params
  }

  private resolveEffectiveUserId(routeUserId: string = ''): string {
    const normalizedRouteUserId: string = routeUserId.trim()
    if (normalizedRouteUserId.length > 0) {
      return normalizedRouteUserId
    }

    const normalizedStateUserId: string = this.userId.trim()
    if (normalizedStateUserId.length > 0) {
      return normalizedStateUserId
    }

    return this.userRepository.getCurrentUserId().trim()
  }

  private syncFromVm(): void {
    this.userId = this.vm.userId
    this.realName = this.vm.realName
    this.certificateType = this.vm.certificateType
    this.certificateNo = this.vm.certificateNo
    this.phone = this.vm.phone
    this.isDefault = this.vm.isDefault
    this.errorMessage = this.vm.errorMessage
    this.canSaveValue = this.vm.canSave() && this.isAgreeRule
  }

  private refreshInputText(): void {
    this.inputRefreshVersion++
  }

  build() {
    Column() {
      this.TopBar()

      Scroll() {
        Column() {
          this.TipArea()
          this.FormArea()
          this.RuleArea()
          Blank().height(80)
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 12 })
      }
      .layoutWeight(1)

      this.BottomButton()
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

      Text(this.isEditMode() ? '编辑观演人' : '添加观演人')
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
  private TipArea() {
    Text('特别提示：实名制入场项目要求本人持购票时填写的有效证件入场')
      .fontSize(13)
      .fontColor('#E33B3B')
      .lineHeight(20)
      .width('100%')
      .padding(12)
      .margin({ top: 12 })
      .backgroundColor('#FFF1F1')
      .borderRadius(10)
  }

  @Builder
  private FormArea() {
    Column() {
      this.RealNameInputRow()

      this.CertificateTypeArea()

      this.CertificateNoInputRow()

      this.PhoneInputRow()

      Row() {
        Text('设为默认观演人')
          .fontSize(15)
          .fontColor('#222222')

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isDefault })
          .onChange((isOn: boolean) => {
            this.vm.isDefault = isOn
            this.syncFromVm()
          })
      }
      .width('100%')
      .height(52)
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private RealNameInputRow() {
    Column() {
      Text('姓名')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      ForEach(['realName_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入姓名', text: this.realName })
          .height(42)
          .fontSize(15)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.vm.realName = value
            this.syncFromVm()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private CertificateNoInputRow() {
    Column() {
      Text('证件号')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      ForEach(['certificateNo_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入证件号', text: this.certificateNo })
          .height(42)
          .fontSize(15)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.vm.certificateNo = value
            this.syncFromVm()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private PhoneInputRow() {
    Column() {
      Text('手机号')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      ForEach(['phone_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入手机号', text: this.phone })
          .height(42)
          .fontSize(15)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.vm.phone = value
            this.syncFromVm()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private CertificateTypeArea() {
    Column() {
      Text('证件类型')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      Row() {
        this.CertificateTypeItem(CertificateType.ID_CARD, '身份证')
        this.CertificateTypeItem(CertificateType.PASSPORT, '护照')
        this.CertificateTypeItem(CertificateType.HK_MACAO_PASS, '港澳通行证')
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private CertificateTypeItem(type: CertificateType, text: string) {
    Row() {
      Text(text)
        .fontSize(13)
        .fontColor(this.certificateType === type ? '#E33B3B' : '#333333')
    }
    .height(32)
    .padding({ left: 12, right: 12 })
    .margin({ right: 8 })
    .backgroundColor(this.certificateType === type ? '#FFECEC' : '#F1F1F1')
    .borderRadius(16)
    .onClick(() => {
      this.vm.setCertificateType(type)
      this.syncFromVm()
    })
  }

  @Builder
  private RuleArea() {
    Row() {
      Text(this.isAgreeRule ? '✓' : '')
        .fontSize(13)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(18)
        .height(18)
        .backgroundColor(this.isAgreeRule ? '#E33B3B' : '#FFFFFF')
        .border({ width: 1, color: this.isAgreeRule ? '#E33B3B' : '#CCCCCC' })
        .borderRadius(4)

      Text('我已阅读并同意《实名制须知》')
        .fontSize(13)
        .fontColor('#666666')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.isAgreeRule = !this.isAgreeRule
      this.syncFromVm()
    })
  }

  @Builder
  private BottomButton() {
    Row() {
      Button('保存')
        .height(44)
        .width('100%')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.canSaveValue ? '#E33B3B' : '#CCCCCC')
        .onClick(() => {
          this.saveAudience()
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private async saveAudience(): Promise<void> {
    if (!this.isAgreeRule) {
      promptAction.showToast({ message: '请先阅读并同意实名制须知' })
      return
    }

    const effectiveUserId: string = this.resolveEffectiveUserId(this.vm.userId)
    if (effectiveUserId.length === 0 || !this.userRepository.isLogin()) {
      promptAction.showToast({ message: '请先登录后再保存观演人' })
      this.isWaitingLoginBack = true
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.vm.userId = effectiveUserId
    this.userId = effectiveUserId

    const success: boolean = this.isEditMode() ?
      await this.vm.updateAudience() :
      await this.vm.createAudience()

    this.syncFromVm()

    if (!success) {
      promptAction.showToast({
        message: this.errorMessage.length > 0 ? this.errorMessage : '保存失败'
      })
      return
    }

    promptAction.showToast({ message: '保存成功' })
    router.back()
  }

  private isEditMode(): boolean {
    return this.vm.audienceId.length > 0
  }
}
