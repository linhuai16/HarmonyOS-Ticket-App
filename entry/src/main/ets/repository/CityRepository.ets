
const KEY_CURRENT_CITY = 'current_city'

/**
 1. 保存当前城市
 2. 获取当前城市
 3. 获取默认城市
 */

export class CityRepository {

  /**
   1. 保存当前城市
   */
  getCurrentCity(): string {
    const city = AppStorage.get<string>(KEY_CURRENT_CITY)

    if (city !== undefined && city.length > 0) {
      return this.normalizeCityName(city)
    }

    return this.getDefaultCity()
  }

  /**
   2. 获取当前城市
   */
  saveCurrentCity(cityName: string): void {
    AppStorage.setOrCreate(KEY_CURRENT_CITY, this.normalizeCityName(cityName))
  }

  /**
   3. 获取默认城市
   */
  getDefaultCity(): string {
    return '北京'
  }

  clearCurrentCity(): void {
    AppStorage.setOrCreate(KEY_CURRENT_CITY, '')
  }

  private normalizeCityName(cityName: string): string {
    let realCityName: string = cityName.trim()

    if (realCityName.endsWith('市')) {
      realCityName = realCityName.substring(0, realCityName.length - 1)
    }

    return realCityName.length === 0 ? this.getDefaultCity() : realCityName
  }
}
