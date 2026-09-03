
import { AddressViewModel } from '../../viewmodel/AddressViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'
import { KeyboardAvoidMode } from '@kit.ArkUI'
import { AddressRegionUtil } from '../../utils/AddressRegionUtil'
interface AddressEditRouteParams {
  userId?: string
  addressId?: string
  from?: string
}


@Entry
@Component
struct AddressEditPage {
  private vm: AddressViewModel = new AddressViewModel()
  private userRepository: UserRepository = new UserRepository()

  private routeUserId: string = ''
  private routeAddressId: string = ''
  private routeFrom: string = ''
  private hasLoadedPageData: boolean = false
  private lastLoadKey: string = ''
  private isWaitingLoginBack: boolean = false

  @State inputRefreshVersion: number = 0
  @State userId: string = ''
  @State from: string = ''
  @State receiverName: string = ''
  @State receiverPhone: string = ''
  @State province: string = ''
  @State city: string = ''
  @State district: string = ''
  @State detailAddress: string = ''
  @State isDefault: boolean = false
  @State canSaveValue: boolean = false
  @State errorMessage: string = ''
  @State breakPoint: string = 'sm'
  @State isSaving: boolean = false

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE)
    this.loadPageData(true)
  }

  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET)
  }

  onPageShow(): void {
    WindowImmersiveUtil.applyLight(this)
    if (this.isWaitingLoginBack || !this.hasLoadedPageData) {
      this.loadPageData(false)
    }
  }

  private async loadPageData(allowLoginRedirect: boolean): Promise<void> {
    const params: AddressEditRouteParams = this.getRouteParams()
    const userId: string = this.resolveEffectiveUserId(params.userId ?? '')
    const addressId: string = params.addressId ?? ''
    const from: string = params.from ?? ''

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      if (allowLoginRedirect && !this.isWaitingLoginBack) {
        this.isWaitingLoginBack = true
        this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      }
      return
    }

    const loadKey: string = `${userId}_${addressId}_${from}`
    if (this.hasLoadedPageData && this.lastLoadKey === loadKey) {
      return
    }

    this.from = from

    if (addressId.length > 0) {
      await this.vm.loadDetail(userId, addressId)
    } else {
      this.vm.resetForm(userId)
    }

    this.hasLoadedPageData = true
    this.lastLoadKey = loadKey
    this.isWaitingLoginBack = false
    this.syncFromVm()
    this.refreshInputText()
  }

  private getRouteParams(): AddressEditRouteParams {
    const rawParams: AddressEditRouteParams | undefined = this.getUIContext().getRouter().getParams() as AddressEditRouteParams | undefined

    if (rawParams !== undefined && rawParams !== null) {
      if (rawParams.userId !== undefined) {
        this.routeUserId = rawParams.userId
      }
      if (rawParams.addressId !== undefined) {
        this.routeAddressId = rawParams.addressId
      }
      if (rawParams.from !== undefined) {
        this.routeFrom = rawParams.from
      }
    }

    const params: AddressEditRouteParams = {
      userId: this.routeUserId,
      addressId: this.routeAddressId,
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
    this.receiverName = this.vm.receiverName
    this.receiverPhone = this.vm.receiverPhone
    this.province = this.vm.province
    this.city = this.vm.city
    this.district = this.vm.district
    this.detailAddress = this.vm.detailAddress
    this.isDefault = this.vm.isDefault
    this.errorMessage = this.vm.errorMessage
    this.canSaveValue = this.vm.canSave()
  }

  private refreshInputText(): void {
    this.inputRefreshVersion++
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
              this.TopBar()

              Scroll() {
                Column() {
                  this.FormArea()
                  Blank().height(this.isTabletLayout() ? 76 : 68)
                }
                .width('100%')
                .constraintSize({ maxWidth: ResponsiveLayout.FORM_MAX_WIDTH })
                .padding({
                  left: this.isTabletLayout() ? 0 : 12,
                  right: this.isTabletLayout() ? 0 : 12,
                  bottom: 12
                })
              }
              .width('100%')
              .layoutWeight(1)
              .align(Alignment.Top)
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

      Text(this.isEditMode() ? '编辑地址' : '新增地址')
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
  private FormArea() {
    Column() {
      this.ReceiverNameInputRow()

      this.ReceiverPhoneInputRow()

      this.ProvinceSelectRow()
      this.CitySelectRow()
      this.DistrictSelectRow()

      this.DetailAddressInputRow()

      Row() {
        Text('设为默认地址')
          .fontSize(this.isTabletLayout() ? 17 : 15)
          .fontColor('#222222')

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isDefault })
          .onChange((isOn: boolean) => {
            this.vm.isDefault = isOn
            this.syncFromVm()
          })
      }
      .width('100%')
      .height(this.isTabletLayout() ? 60 : 52)
    }
    .width('100%')
    .padding(this.isTabletLayout() ? 20 : 12)
    .margin({ top: this.isTabletLayout() ? 8 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private ReceiverNameInputRow() {
    Column() {
      Text('收货人')
        .fontSize(this.isTabletLayout() ? 16 : 14)
        .fontColor('#666666')
        .width('100%')

      ForEach(['receiverName_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入收货人姓名', text: this.receiverName })
          .height(this.isTabletLayout() ? 50 : 42)
          .fontSize(this.isTabletLayout() ? 17 : 15)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.vm.receiverName = value
            this.syncFromVm()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private ReceiverPhoneInputRow() {
    Column() {
      Text('手机号')
        .fontSize(this.isTabletLayout() ? 16 : 14)
        .fontColor('#666666')
        .width('100%')

      ForEach(['receiverPhone_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入手机号', text: this.receiverPhone })
          .height(this.isTabletLayout() ? 50 : 42)
          .fontSize(this.isTabletLayout() ? 17 : 15)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.vm.receiverPhone = value
            this.syncFromVm()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private DetailAddressInputRow() {
    Column() {
      Text('门牌号')
        .fontSize(this.isTabletLayout() ? 16 : 14)
        .fontColor('#666666')
        .width('100%')

      ForEach(['detailAddress_' + this.inputRefreshVersion.toString()], (inputKey: string) => {
        TextInput({ placeholder: '请输入详细地址', text: this.detailAddress })
          .height(this.isTabletLayout() ? 50 : 42)
          .fontSize(this.isTabletLayout() ? 17 : 15)
          .backgroundColor('#F7F7F7')
          .borderRadius(8)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.vm.detailAddress = value
            this.syncFromVm()
          })
      }, (inputKey: string) => inputKey)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private ProvinceSelectRow() {
    Column() {
      Text('省份')
        .fontSize(this.isTabletLayout() ? 16 : 14)
        .fontColor('#666666')
        .width('100%')

      Select(this.getProvinceOptions())
        .height(this.isTabletLayout() ? 50 : 42)
        .width('100%')
        .selected(this.getProvinceIndex())
        .value(this.province.length > 0 ? this.province : '请选择省份')
        .font({ size: this.isTabletLayout() ? 17 : 15 })
        .fontColor(this.province.length > 0 ? '#222222' : '#999999')
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .margin({ top: 8 })
        .onSelect((index: number, value?: string) => {
          const selectedValue: string = value ?? ''
          this.vm.province = selectedValue
          this.vm.city = ''
          this.vm.district = ''
          this.syncFromVm()
        })
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private CitySelectRow() {
    Column() {
      Text('城市')
        .fontSize(this.isTabletLayout() ? 16 : 14)
        .fontColor('#666666')
        .width('100%')

      Select(this.getCityOptions())
        .height(this.isTabletLayout() ? 50 : 42)
        .width('100%')
        .selected(this.getCityIndex())
        .value(this.city.length > 0 ? this.city : (this.province.length > 0 ? '请选择城市' : '请先选择省份'))
        .font({ size: this.isTabletLayout() ? 17 : 15 })
        .fontColor(this.city.length > 0 ? '#222222' : '#999999')
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .margin({ top: 8 })
        .onSelect((index: number, value?: string) => {
          const cities: string[] = this.getCityValues()
          if (cities.length === 0) {
            this.getUIContext().getPromptAction().showToast({ message: '请先选择省份' })
            return
          }

          const selectedValue: string = value ?? ''
          this.vm.city = selectedValue
          this.vm.district = ''
          this.syncFromVm()
        })
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private DistrictSelectRow() {
    Column() {
      Text('区县')
        .fontSize(this.isTabletLayout() ? 16 : 14)
        .fontColor('#666666')
        .width('100%')

      Select(this.getDistrictOptions())
        .height(this.isTabletLayout() ? 50 : 42)
        .width('100%')
        .selected(this.getDistrictIndex())
        .value(this.district.length > 0 ? this.district : (this.city.length > 0 ? '请选择区县' : '请先选择城市'))
        .font({ size: this.isTabletLayout() ? 17 : 15 })
        .fontColor(this.district.length > 0 ? '#222222' : '#999999')
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .margin({ top: 8 })
        .onSelect((index: number, value?: string) => {
          const districts: string[] = this.getDistrictValues()
          if (districts.length === 0) {
            this.getUIContext().getPromptAction().showToast({ message: this.province.length === 0 ? '请先选择省份' : '请先选择城市' })
            return
          }

          const selectedValue: string = value ?? ''
          this.vm.district = selectedValue
          this.syncFromVm()
        })
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private BottomButton() {
    Row() {
      Button(this.isSaving ? '保存中...' : '保存地址')
        .height(this.isTabletLayout() ? 50 : 44)
        .width('100%')
        .constraintSize({ maxWidth: this.isTabletLayout() ? 520 : 1000 })
        .fontSize(this.isTabletLayout() ? 17 : 16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.canSaveValue && !this.isSaving ? '#E33B3B' : '#CCCCCC')
        .enabled(this.canSaveValue && !this.isSaving)
        .onClick(() => {
          this.saveAddress()
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

  private async saveAddress(): Promise<void> {
    if (!this.canSaveValue || this.isSaving) {
      return
    }
    const effectiveUserId: string = this.resolveEffectiveUserId(this.vm.userId)
    if (effectiveUserId.length === 0 || !this.userRepository.isLogin()) {
      this.getUIContext().getPromptAction().showToast({ message: '请先登录后再保存收货地址' })
      this.isWaitingLoginBack = true
      this.getUIContext().getRouter().pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.vm.userId = effectiveUserId
    this.userId = effectiveUserId
    this.isSaving = true

    const success: boolean = this.isEditMode() ?
      await this.vm.updateAddress() :
      await this.vm.createAddress()

    this.isSaving = false
    this.syncFromVm()

    if (!success) {
      this.getUIContext().getPromptAction().showToast({
        message: this.errorMessage.length > 0 ? this.errorMessage : '需完善信息才能提交'
      })
      return
    }

    this.getUIContext().getPromptAction().showToast({ message: '保存成功' })
    this.getUIContext().getRouter().back()
  }

  private isEditMode(): boolean {
    return this.vm.addressId.length > 0
  }

  private getProvinceIndex(): number {
    const provinces: string[] = this.getProvinceValues()
    return this.getSelectedIndex(provinces, this.province)
  }

  private getCityIndex(): number {
    const cities: string[] = this.getCityValues()
    return this.getSelectedIndex(cities, this.city)
  }

  private getDistrictIndex(): number {
    const districts: string[] = this.getDistrictValues()
    return this.getSelectedIndex(districts, this.district)
  }

  private getProvinceOptions(): Array<SelectOption> {
    return this.buildSelectOptions(this.getProvinceValues(), '请选择省份')
  }

  private getCityOptions(): Array<SelectOption> {
    const placeholder: string = this.province.length > 0 ? '请选择城市' : '请先选择省份'
    return this.buildSelectOptions(this.getCityValues(), placeholder)
  }

  private getDistrictOptions(): Array<SelectOption> {
    const placeholder: string = this.city.length > 0 ? '请选择区县' : '请先选择城市'
    return this.buildSelectOptions(this.getDistrictValues(), placeholder)
  }

  private getProvinceValues(): string[] {
    return AddressRegionUtil.getProvinceNames()
  }

  private getCityValues(): string[] {
    return AddressRegionUtil.getCityNames(this.province)
  }

  private getDistrictValues(): string[] {
    return AddressRegionUtil.getDistrictNames(this.province, this.city)
  }

  private getSelectedIndex(values: string[], currentValue: string): number {
    const index: number = values.indexOf(currentValue)
    return index < 0 ? 0 : index
  }

  private buildSelectOptions(values: string[], emptyText: string): Array<SelectOption> {
    if (values.length === 0) {
      return [{ value: emptyText }]
    }

    return values.map((item: string): SelectOption => {
      return { value: item }
    })
  }
}
