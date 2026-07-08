import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

import { AddressViewModel } from '../../viewmodel/AddressViewModel'
import { UserRepository } from '../../repository/UserRepository'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'
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

  private loadPageData(allowLoginRedirect: boolean): void {
    const params: AddressEditRouteParams = this.getRouteParams()
    const userId: string = this.resolveEffectiveUserId(params.userId ?? '')
    const addressId: string = params.addressId ?? ''
    const from: string = params.from ?? ''

    if (userId.length === 0 || !this.userRepository.isLogin()) {
      if (allowLoginRedirect && !this.isWaitingLoginBack) {
        this.isWaitingLoginBack = true
        router.pushUrl({ url: 'pages/user/LoginPage' })
      }
      return
    }

    const loadKey: string = `${userId}_${addressId}_${from}`
    if (this.hasLoadedPageData && this.lastLoadKey === loadKey) {
      return
    }

    this.from = from

    if (addressId.length > 0) {
      this.vm.loadDetail(userId, addressId)
    } else {
      this.vm.resetForm(userId)
    }

    this.hasLoadedPageData = true
    this.lastLoadKey = loadKey
    this.isWaitingLoginBack = false
    this.syncFromVm()
  }

  private getRouteParams(): AddressEditRouteParams {
    const rawParams: AddressEditRouteParams | undefined = router.getParams() as AddressEditRouteParams | undefined

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

  build() {
    Column() {
      this.TopBar()

      Scroll() {
        Column() {
          this.FormArea()
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
      this.InputRow('收货人', '请输入收货人姓名', this.receiverName, (value: string) => {
        this.vm.receiverName = value
        this.syncFromVm()
      })

      this.InputRow('手机号', '请输入手机号', this.receiverPhone, (value: string) => {
        this.vm.receiverPhone = value
        this.syncFromVm()
      })

      this.ProvinceSelectRow()
      this.CitySelectRow()
      this.DistrictSelectRow()

      this.InputRow('门牌号', '请输入详细地址', this.detailAddress, (value: string) => {
        this.vm.detailAddress = value
        this.syncFromVm()
      })

      Row() {
        Text('设为默认地址')
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
  private InputRow(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      TextInput({
        placeholder: placeholder,
        text: value
      })
        .height(42)
        .fontSize(15)
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .margin({ top: 8 })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private ProvinceSelectRow() {
    Column() {
      Text('省份')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      Select(this.getProvinceOptions())
        .height(42)
        .width('100%')
        .selected(this.getProvinceIndex())
        .value(this.province.length > 0 ? this.province : '请选择省份')
        .font({ size: 15 })
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
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      Select(this.getCityOptions())
        .height(42)
        .width('100%')
        .selected(this.getCityIndex())
        .value(this.city.length > 0 ? this.city : (this.province.length > 0 ? '请选择城市' : '请先选择省份'))
        .font({ size: 15 })
        .fontColor(this.city.length > 0 ? '#222222' : '#999999')
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .margin({ top: 8 })
        .onSelect((index: number, value?: string) => {
          const cities: string[] = this.getCityValues()
          if (cities.length === 0) {
            promptAction.showToast({ message: '请先选择省份' })
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
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      Select(this.getDistrictOptions())
        .height(42)
        .width('100%')
        .selected(this.getDistrictIndex())
        .value(this.district.length > 0 ? this.district : (this.city.length > 0 ? '请选择区县' : '请先选择城市'))
        .font({ size: 15 })
        .fontColor(this.district.length > 0 ? '#222222' : '#999999')
        .backgroundColor('#F7F7F7')
        .borderRadius(8)
        .margin({ top: 8 })
        .onSelect((index: number, value?: string) => {
          const districts: string[] = this.getDistrictValues()
          if (districts.length === 0) {
            promptAction.showToast({ message: this.province.length === 0 ? '请先选择省份' : '请先选择城市' })
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
      Button('保存地址')
        .height(44)
        .width('100%')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.canSaveValue ? '#E33B3B' : '#CCCCCC')
        .onClick(() => {
          this.saveAddress()
        })
    }
    .width('100%')
    .height(68)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  private saveAddress(): void {
    const effectiveUserId: string = this.resolveEffectiveUserId(this.vm.userId)
    if (effectiveUserId.length === 0 || !this.userRepository.isLogin()) {
      promptAction.showToast({ message: '请先登录后再保存收货地址' })
      this.isWaitingLoginBack = true
      router.pushUrl({ url: 'pages/user/LoginPage' })
      return
    }

    this.vm.userId = effectiveUserId
    this.userId = effectiveUserId

    const success: boolean = this.isEditMode() ?
      this.vm.updateAddress() :
      this.vm.createAddress()

    this.syncFromVm()

    if (!success) {
      promptAction.showToast({
        message: this.errorMessage.length > 0 ? this.errorMessage : '需完善信息才能提交'
      })
      return
    }

    promptAction.showToast({ message: '保存成功' })
    router.back()
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
