import { PerformanceVideoFullscreenNavParams } from '../../navigation/AppNavigation'
import { PerformanceVideoPlayer } from '../../components/performance/PerformanceVideoPlayer'
import { WindowImmersiveUtil } from '../../common/WindowImmersiveUtil'

@Entry
@Component
export struct PerformanceVideoFullscreenPage {
  @Consume('appNavStack') navStack: NavPathStack
  navParams: PerformanceVideoFullscreenNavParams = {}

  aboutToAppear(): void {
    WindowImmersiveUtil.applyVideoFullscreen(this)
  }

  aboutToDisappear(): void {
    WindowImmersiveUtil.restoreDetailFromVideo(this)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        if ((this.navParams.videoUrl ?? '').length > 0) {
          PerformanceVideoPlayer({
            videoUrl: this.navParams.videoUrl ?? '',
            posterUrl: this.navParams.posterUrl ?? '',
            title: this.navParams.title ?? '',
            initialPositionMs: this.navParams.startPositionMs ?? 0,
            initialMuted: this.navParams.isMuted ?? false,
            autoPlay: true,
            fullScreenMode: true,
            onExitFullScreen: () => {
              this.exitFullscreen()
            }
          })
        } else {
          Text('暂无可播放视频')
            .fontSize(15)
            .fontColor('#FFFFFF')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
    }
    .hideTitleBar(true)
    .backgroundColor('#000000')
    .onBackPressed(() => {
      this.exitFullscreen()
      return true
    })
    .onShown(() => {
      WindowImmersiveUtil.applyVideoFullscreen(this)
    })
  }

  private exitFullscreen(): void {
    WindowImmersiveUtil.restoreDetailFromVideo(this)
    this.navStack.pop()
  }
}
