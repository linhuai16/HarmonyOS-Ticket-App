import { common } from '@kit.AbilityKit'
import { UIContext } from '@kit.ArkUI'

/**
 * 拉起系统导航类应用。经纬度存在时进入路线规划；缺少坐标时退化为场馆位置搜索。
 * 页面只传场馆公开信息，不传用户/订单/票源字段。
 */
export class VenueNavigationUtil {
  static open(context: common.UIAbilityContext, uiContext: UIContext, venueName: string, venueAddress: string,
              latitude?: number, longitude?: number): void {
    const destinationName: string = venueAddress.length > 0 ? venueName + ' ' + venueAddress : venueName
    if (destinationName.trim().length === 0) {
      uiContext.getPromptAction().showToast({ message: '暂无场馆导航信息' })
      return
    }

    let wantParam: Record<string, Object>
    if (latitude !== undefined && longitude !== undefined) {
      wantParam = {
        'sceneType': 1,
        'destinationLatitude': latitude,
        'destinationLongitude': longitude,
        'destinationName': destinationName,
        'vehicleType': 0
      }
    } else {
      wantParam = {
        'sceneType': 3,
        'destinationName': destinationName
      }
    }

    const callback: common.AbilityStartCallback = {
      onError: (_code: number, _name: string, _message: string): void => {
        uiContext.getPromptAction().showToast({ message: '暂未找到可用的地图导航应用' })
      },
      onResult: (_result): void => {
      }
    }
    context.startAbilityByType('navigation', wantParam, callback)
  }
}
