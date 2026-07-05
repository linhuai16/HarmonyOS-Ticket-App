import { CityRepository } from '../repository/CityRepository'

/**
 * 接收组件回传城市并保存当前城市
 */

export class CityViewModel {
  currentCityName: string = ''
  defaultCityName: string = ''

  errorMessage: string = ''

  private cityRepository: CityRepository = new CityRepository()

  constructor() {
    this.defaultCityName = this.cityRepository.getDefaultCity()
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  loadCurrentCity(): void {
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  saveSelectedCity(cityName: string): boolean {
    const realCityName: string = cityName.trim()

    if (realCityName.length === 0) {
      this.errorMessage = '城市名称不能为空'
      return false
    }

    this.cityRepository.saveCurrentCity(realCityName)
    this.currentCityName = this.cityRepository.getCurrentCity()
    this.errorMessage = ''

    return true
  }

  resetToDefaultCity(): void {
    this.cityRepository.saveCurrentCity(this.defaultCityName)
    this.currentCityName = this.defaultCityName
    this.errorMessage = ''
  }

  clearCurrentCity(): void {
    this.cityRepository.clearCurrentCity()
    this.currentCityName = this.cityRepository.getCurrentCity()
  }

  clearError(): void {
    this.errorMessage = ''
  }
}