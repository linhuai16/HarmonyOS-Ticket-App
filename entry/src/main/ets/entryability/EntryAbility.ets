import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { EntryDispatcher } from '../navigation/EntryDispatcher';
import { ServiceCardRuntime } from '../servicecard/ServiceCardRuntime';
import { ServiceCardUpdater } from '../servicecard/ServiceCardUpdater';
import { PushRuntime } from '../notification/PushRuntime';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private runtimesRegistered: boolean = false;
  private foregroundPending: boolean = false;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    PushRuntime.restoreLoginSession(this.context);
    PushRuntime.registerLightweight(this);
    EntryDispatcher.receive(want);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    PushRuntime.unregister();
    ServiceCardRuntime.unregister();
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    EntryDispatcher.receive(want);
    ServiceCardRuntime.requestRefresh();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.prepareWindowStage(windowStage);
  }

  private prepareWindowStage(windowStage: window.WindowStage): void {
    this.configureWindowImmersive(windowStage).catch((err: Error): void => {
      hilog.error(DOMAIN, TAG, 'Failed to configure window immersive. Cause: %{public}s', JSON.stringify(err));
    });
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      this.runPostContentInitialization();
    });
  }

  private async configureWindowImmersive(windowStage: window.WindowStage): Promise<void> {
    const windowClass: window.Window = await windowStage.getMainWindow();
    await windowClass.setWindowLayoutFullScreen(false);
    await windowClass.setSpecificSystemBarEnabled('status', true);
    await windowClass.setSpecificSystemBarEnabled('navigationIndicator', true);
    await windowClass.setWindowSystemBarProperties({
      statusBarColor: '#F5F5F5',
      statusBarContentColor: '#000000',
      navigationBarColor: '#FFFFFF',
      navigationBarContentColor: '#000000'
    });
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
    this.foregroundPending = true;
    if (this.runtimesRegistered) {
      this.refreshForegroundRuntimes();
    }
  }

  onBackground(): void {
  }

  private runPostContentInitialization(): void {
    if (this.runtimesRegistered) {
      return;
    }
    ServiceCardRuntime.register(this.context, (): Promise<void> => {
      return ServiceCardUpdater.refreshAll(this.context);
    });
    const userId: string = AppStorage.get<string>('login_user_id') ?? '';
    const loggedIn: boolean = (AppStorage.get<boolean>('login_status') ?? false) && userId.length > 0;
    PushRuntime.syncDeferred(loggedIn ? userId : '');
    this.runtimesRegistered = true;
    if (this.foregroundPending) {
      ServiceCardRuntime.requestRefresh();
      this.foregroundPending = false;
    }
  }

  private refreshForegroundRuntimes(): void {
    if (!this.foregroundPending) {
      return;
    }
    this.foregroundPending = false;
    ServiceCardRuntime.requestRefresh();
    const userId: string = AppStorage.get<string>('login_user_id') ?? '';
    if ((AppStorage.get<boolean>('login_status') ?? false) && userId.length > 0) {
      PushRuntime.foreground(userId);
    }
  }
}
