import { window } from '@kit.ArkUI'

export class WindowImmersiveUtil {
  static applyLight(component: Object): void {
    WindowImmersiveUtil.apply(component, '#FFFFFF', '#F5F5F5')
  }

  static applyGray(component: Object): void {
    WindowImmersiveUtil.apply(component, '#F5F5F5', '#F5F5F5')
  }

  static applyMine(component: Object): void {
    WindowImmersiveUtil.apply(component, '#FFEDEF', '#FFEDEF')
  }

  static apply(component: Object, statusBarColor: string, navigationBarColor: string): void {
    try {
      window.getLastWindow(getContext(component)).then((windowClass: window.Window) => {
        windowClass.setWindowSystemBarProperties({
          statusBarColor: statusBarColor,
          statusBarContentColor: '#000000',
          navigationBarColor: navigationBarColor,
          navigationBarContentColor: '#000000'
        })
      }).catch(() => {
      })
    } catch (err) {
    }
  }
}
