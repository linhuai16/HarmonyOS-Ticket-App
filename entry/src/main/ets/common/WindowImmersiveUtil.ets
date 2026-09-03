import { UIContext, window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'

interface UIContextProvider {
  getUIContext(): UIContext
}

export class WindowImmersiveUtil {
  private static operation: Promise<void> = Promise.resolve()

  static applyLight(component: UIContextProvider): void {
    WindowImmersiveUtil.apply(component, '#FFFFFF', '#F5F5F5')
  }

  static applyGray(component: UIContextProvider): void {
    WindowImmersiveUtil.apply(component, '#F5F5F5', '#F5F5F5')
  }

  static applyMine(component: UIContextProvider): void {
    WindowImmersiveUtil.apply(component, '#FFEDEF', '#FFFFFF')
  }

  static apply(component: UIContextProvider, statusBarColor: string, navigationBarColor: string): void {
    WindowImmersiveUtil.enqueue(async (): Promise<void> => {
      const context = component.getUIContext().getHostContext() as common.UIAbilityContext
      const windowClass: window.Window = await window.getLastWindow(context)
      await windowClass.setWindowLayoutFullScreen(false)
      await WindowImmersiveUtil.enableSystemBars(windowClass)
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: statusBarColor,
        statusBarContentColor: '#000000',
        navigationBarColor: navigationBarColor,
        navigationBarContentColor: '#000000'
      })
    })
  }

  static exitDetail(component: UIContextProvider): void {
    WindowImmersiveUtil.enqueue(async (): Promise<void> => {
      const context = component.getUIContext().getHostContext() as common.UIAbilityContext
      const windowClass: window.Window = await window.getLastWindow(context)
      await windowClass.setWindowLayoutFullScreen(false)
      await WindowImmersiveUtil.enableSystemBars(windowClass)
    })
  }

  static applyDetail(component: UIContextProvider, darkStatusContent: boolean = false): void {
    WindowImmersiveUtil.enqueue(async (): Promise<void> => {
      const context = component.getUIContext().getHostContext() as common.UIAbilityContext
      const windowClass: window.Window = await window.getLastWindow(context)
      await windowClass.setWindowLayoutFullScreen(true)
      await WindowImmersiveUtil.enableSystemBars(windowClass)
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: darkStatusContent ? '#000000' : '#FFFFFF',
        navigationBarColor: '#FFFFFF',
        navigationBarContentColor: '#000000'
      })
    })
  }

  static updateDetailStatusContent(component: UIContextProvider, darkStatusContent: boolean): void {
    WindowImmersiveUtil.enqueue(async (): Promise<void> => {
      const context = component.getUIContext().getHostContext() as common.UIAbilityContext
      const windowClass: window.Window = await window.getLastWindow(context)
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: darkStatusContent ? '#000000' : '#FFFFFF',
        navigationBarColor: '#FFFFFF',
        navigationBarContentColor: '#000000'
      })
    })
  }

  static applyVideoFullscreen(component: UIContextProvider): void {
    WindowImmersiveUtil.enqueue(async (): Promise<void> => {
      const context = component.getUIContext().getHostContext() as common.UIAbilityContext
      const windowClass: window.Window = await window.getLastWindow(context)
      await windowClass.setWindowLayoutFullScreen(true)
      await WindowImmersiveUtil.disableSystemBars(windowClass)
      await windowClass.setPreferredOrientation(window.Orientation.LANDSCAPE)
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: '#000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: '#000000',
        navigationBarContentColor: '#FFFFFF'
      })
    })
  }

  static restoreDetailFromVideo(component: UIContextProvider): void {
    WindowImmersiveUtil.enqueue(async (): Promise<void> => {
      const context = component.getUIContext().getHostContext() as common.UIAbilityContext
      const windowClass: window.Window = await window.getLastWindow(context)
      await windowClass.setPreferredOrientation(window.Orientation.UNSPECIFIED)
      await WindowImmersiveUtil.enableSystemBars(windowClass)
      await windowClass.setWindowLayoutFullScreen(true)
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#FFFFFF',
        navigationBarColor: '#FFFFFF',
        navigationBarContentColor: '#000000'
      })
    })
  }

  private static async enableSystemBars(windowClass: window.Window): Promise<void> {
    await windowClass.setSpecificSystemBarEnabled('status', true)
    await windowClass.setSpecificSystemBarEnabled('navigationIndicator', true)
  }

  private static async disableSystemBars(windowClass: window.Window): Promise<void> {
    await windowClass.setSpecificSystemBarEnabled('status', false)
    await windowClass.setSpecificSystemBarEnabled('navigationIndicator', false)
  }

  private static enqueue(operation: () => Promise<void>): void {
    WindowImmersiveUtil.operation = WindowImmersiveUtil.operation.then(operation).catch((): void => {
    })
  }
}
