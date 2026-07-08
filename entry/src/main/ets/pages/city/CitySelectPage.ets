import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { UICitySelect } from 'module_city_select'
import { CityViewModel } from '../../viewmodel/CityViewModel'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

@Entry
@Component
struct CitySelectPage {
  private vm: CityViewModel = new CityViewModel()

  @State pageVersion: number = 0
  @State currentCityName: string = '北京'

  aboutToAppear(): void {
    WindowImmersiveUtil.applyLight(this)
    this.vm.loadCurrentCity()
    this.syncFromVm()
  }

  build() {
    Column() {
      this.RefreshMarker()
      this.TopBar()

      UICitySelect({
        currentCity: this.currentCityName,
        goBack: (city?: string) => {
          this.onSelectCity(city)
        },
        emitUpdateCityLocation: (city: string) => {
          this.onUpdateLocationCity(city)
        }
      })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
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
      .justifyContent(FlexAlign.Start)
      .onClick(() => {
        router.back()
      })

      Text('选择城市')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .layoutWeight(1)

      Blank()
        .width(40)
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
  }

  private onSelectCity(city?: string): void {
    const cityName: string = city === undefined ? '' : city.trim()

    if (cityName.length === 0) {
      router.back()
      return
    }

    const success: boolean = this.vm.saveSelectedCity(cityName)
    this.syncFromVm()

    if (!success) {
      promptAction.showToast({ message: this.vm.errorMessage })
      return
    }

    router.back()
  }

  private onUpdateLocationCity(city: string): void {
    const cityName: string = city.trim()

    if (cityName.length === 0) {
      promptAction.showToast({ message: '定位失败，请点击城市手动选择' })
      return
    }

    const success: boolean = this.vm.saveSelectedCity(cityName)
    this.syncFromVm()

    if (success) {
      promptAction.showToast({ message: '已定位到' + this.currentCityName })
    } else {
      promptAction.showToast({ message: this.vm.errorMessage })
    }
  }

  private syncFromVm(): void {
    this.currentCityName = this.vm.currentCityName
    this.pageVersion++
  }

  @Builder
  private RefreshMarker() {
    Text(this.pageVersion.toString())
      .width(0)
      .height(0)
      .opacity(0)
  }
}
