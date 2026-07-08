/**
 * 场馆
 * 注解：
 * 存储演出举办地点。一个场馆可被多个场次复用。
 */
export interface Venue {
  /** 场馆ID */
  venueId: string

  /** 场馆名称 */
  venueName: string

  /** 所属城市 */
  cityName: string

  /** 场馆地址 */
  address: string

  /** 经度，用于距离展示和地图导航 */
  longitude?: number

  /** 纬度，用于距离展示和地图导航 */
  latitude?: number
}
