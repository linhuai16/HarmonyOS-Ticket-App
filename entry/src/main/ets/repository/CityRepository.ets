
import { ServiceCardRuntime } from '../servicecard/ServiceCardRuntime'

const KEY_CURRENT_CITY = 'current_city'

/**
 1. 保存当前城市
 2. 获取当前城市
 3. 获取默认城市
 */

export class CityRepository {
  private static currentCityName: string | undefined = undefined

  /**
   1. 保存当前城市
   */
  getCurrentCity(): string {
    if (CityRepository.currentCityName !== undefined) {
      return CityRepository.currentCityName
    }
    const city = AppStorage.get<string>(KEY_CURRENT_CITY)

    if (city !== undefined && city.length > 0) {
      CityRepository.currentCityName = this.normalizeCityName(city)
      return CityRepository.currentCityName
    }

    CityRepository.currentCityName = this.getDefaultCity()
    return CityRepository.currentCityName
  }

  /**
   2. 获取当前城市
   */
  saveCurrentCity(cityName: string): void {
    const normalizedCity: string = this.normalizeCityName(cityName)
    CityRepository.currentCityName = normalizedCity
    AppStorage.setOrCreate(KEY_CURRENT_CITY, normalizedCity)
    ServiceCardRuntime.saveCity(normalizedCity)
  }

  /**
   3. 获取默认城市
   */
  getDefaultCity(): string {
    return '北京'
  }

  clearCurrentCity(): void {
    CityRepository.currentCityName = this.getDefaultCity()
    AppStorage.setOrCreate(KEY_CURRENT_CITY, '')
    ServiceCardRuntime.saveCity(CityRepository.currentCityName)
  }

  private normalizeCityName(cityName: string): string {
    let realCityName: string = cityName.trim()

    if (realCityName.endsWith('市')) {
      realCityName = realCityName.substring(0, realCityName.length - 1)
    }

    return realCityName.length === 0 ? this.getDefaultCity() : realCityName
  }
}
