import media from '@ohos.multimedia.media'
import { BusinessError } from '@kit.BasicServicesKit'
import { AppNavigator } from '../../navigation/AppNavigation'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'

@Component
export struct PerformanceVideoPlayer {
  @Consume('appNavStack') navStack: NavPathStack
  videoUrl: string = ''
  posterUrl: string = ''
  title: string = ''
  initialPositionMs: number = 0
  initialMuted: boolean = false
  autoPlay: boolean = false
  fullScreenMode: boolean = false
  onExitFullScreen: () => void = () => {}

  @State isPlaying: boolean = false
  @State isLoading: boolean = false
  @State hasStarted: boolean = false
  @State hasError: boolean = false
  @State currentTimeMs: number = 0
  @State durationMs: number = 0
  @State isMuted: boolean = false
  @StorageLink('performance_video_pause_version') @Watch('onPauseVersionChanged') pauseVersion: number = 0
  @StorageLink('performance_video_resume_version') @Watch('onResumeVersionChanged') resumeVersion: number = 0

  private avPlayer: media.AVPlayer | undefined = undefined
  private xComponentController: XComponentController = new XComponentController()
  private surfaceId: string = ''
  private pendingAutoPlay: boolean = false
  private sourceAssigned: boolean = false

  aboutToAppear(): void {
    this.currentTimeMs = Math.max(0, this.initialPositionMs)
    this.isMuted = this.initialMuted
    this.pendingAutoPlay = this.autoPlay
  }

  aboutToDisappear(): void {
    if (this.fullScreenMode) {
      AppStorage.setOrCreate('performance_video_resume_url', this.videoUrl)
      AppStorage.setOrCreate('performance_video_resume_position_ms', this.currentTimeMs)
      const currentVersion: number = AppStorage.get<number>('performance_video_resume_version') ?? 0
      AppStorage.setOrCreate('performance_video_resume_version', currentVersion + 1)
    }
    this.releasePlayer()
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      XComponent({
        id: this.fullScreenMode ? 'performanceVideoFullscreenSurface' : 'performanceVideoInlineSurface',
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .onLoad(() => {
          this.surfaceId = this.xComponentController.getXComponentSurfaceId()
          if (this.autoPlay && this.avPlayer === undefined) {
            this.pendingAutoPlay = true
            this.initializePlayer()
          } else {
            this.tryPreparePlayer()
          }
        })

      if (!this.hasStarted && this.posterUrl.length > 0) {
        Image(MediaResourceUtil.getMedia(this.posterUrl))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      if (!this.hasStarted) {
        Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor('#33000000')
      }

      if (this.hasError) {
        Column({ space: 10 }) {
          Text('视频加载失败')
            .fontSize(15)
            .fontColor('#FFFFFF')
          Button('重试')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor('#E33B3B')
            .height(36)
            .onClick(() => {
              this.retry()
            })
        }
        .justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        LoadingProgress()
          .width(42)
          .height(42)
          .color('#FFFFFF')
      } else if (!this.isPlaying) {
        Button(this.hasStarted ? '继续播放' : '播放')
          .height(42)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#99000000')
          .borderRadius(21)
          .onClick(() => {
            this.playOrPause()
          })
      }

      Column() {
        Blank()

        Row() {
          Text(this.isPlaying ? '暂停' : '播放')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 6, right: 6, top: 6, bottom: 6 })
            .onClick(() => {
              this.playOrPause()
            })

          Text(this.formatTime(this.currentTimeMs))
            .fontSize(11)
            .fontColor('#FFFFFF')
            .margin({ left: 4 })

          Slider({
            value: this.currentTimeMs,
            min: 0,
            max: this.getSliderMax(),
            step: 1000,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .margin({ left: 8, right: 8 })
            .selectedColor('#E33B3B')
            .trackColor('#88FFFFFF')
            .blockColor('#FFFFFF')
            .trackThickness(2)
            .onChange((value: number) => {
              this.seekTo(value)
            })

          Text(this.formatTime(this.durationMs))
            .fontSize(11)
            .fontColor('#FFFFFF')

          Text(this.isMuted ? '声音' : '静音')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
            .onClick(() => {
              this.toggleMute()
            })

          Text(this.fullScreenMode ? '退出全屏' : '全屏')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 6, top: 6, bottom: 6 })
            .onClick(() => {
              this.handleFullScreen()
            })
        }
        .width('100%')
        .height(48)
        .padding({ left: 6, right: 6 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#88000000')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }


  private onPauseVersionChanged(): void {
    if (this.avPlayer !== undefined && this.avPlayer.state === 'playing') {
      this.avPlayer.pause()
    }
  }

  private onResumeVersionChanged(): void {
    if (this.fullScreenMode) {
      return
    }
    const resumeUrl: string = AppStorage.get<string>('performance_video_resume_url') ?? ''
    if (resumeUrl.length === 0 || resumeUrl !== this.videoUrl) {
      return
    }
    const resumePosition: number = AppStorage.get<number>('performance_video_resume_position_ms') ?? 0
    this.currentTimeMs = Math.max(0, resumePosition)
    if (this.avPlayer !== undefined && (this.avPlayer.state === 'prepared' || this.avPlayer.state === 'playing' ||
      this.avPlayer.state === 'paused' || this.avPlayer.state === 'completed')) {
      this.avPlayer.seek(Math.floor(this.currentTimeMs), media.SeekMode.SEEK_PREV_SYNC)
    }
  }

  private async initializePlayer(): Promise<void> {
    if (this.videoUrl.length === 0 || this.avPlayer !== undefined) {
      return
    }

    this.isLoading = true
    this.hasError = false
    try {
      const player: media.AVPlayer = await media.createAVPlayer()
      this.avPlayer = player
      this.bindPlayerCallbacks(player)
      player.url = this.videoUrl
      this.sourceAssigned = true
    } catch (err) {
      this.isLoading = false
      this.hasError = true
    }
  }

  private bindPlayerCallbacks(player: media.AVPlayer): void {
    player.on('timeUpdate', (time: number) => {
      this.currentTimeMs = time
    })

    player.on('seekDone', (time: number) => {
      this.currentTimeMs = time
    })

    player.on('error', (err: BusinessError) => {
      console.error('[PerformanceVideo] error code=' + err.code + ', message=' + err.message)
      this.isLoading = false
      this.isPlaying = false
      this.hasError = true
    })

    player.on('stateChange', (state: string) => {
      if (state === 'initialized') {
        this.tryPreparePlayer()
        return
      }

      if (state === 'prepared') {
        this.durationMs = player.duration
        this.isLoading = false
        this.hasError = false
        this.applyVolume()
        if (this.initialPositionMs > 0) {
          player.seek(Math.min(this.initialPositionMs, Math.max(0, player.duration - 1)), media.SeekMode.SEEK_PREV_SYNC)
          this.currentTimeMs = Math.min(this.initialPositionMs, player.duration)
        }
        if (this.pendingAutoPlay) {
          this.pendingAutoPlay = false
          player.play()
        }
        return
      }

      if (state === 'playing') {
        this.isPlaying = true
        this.isLoading = false
        this.hasStarted = true
        return
      }

      if (state === 'paused') {
        this.isPlaying = false
        this.hasStarted = true
        return
      }

      if (state === 'completed') {
        this.isPlaying = false
        this.hasStarted = true
        this.currentTimeMs = this.durationMs
        return
      }

      if (state === 'released') {
        this.isPlaying = false
      }
    })
  }

  private tryPreparePlayer(): void {
    const player: media.AVPlayer | undefined = this.avPlayer
    if (player === undefined || this.surfaceId.length === 0 || !this.sourceAssigned) {
      return
    }
    if (player.state === 'initialized') {
      player.surfaceId = this.surfaceId
      player.prepare()
    }
  }

  private playOrPause(): void {
    if (this.avPlayer === undefined) {
      this.pendingAutoPlay = true
      this.initializePlayer()
      return
    }

    if (this.avPlayer.state === 'playing') {
      this.avPlayer.pause()
      return
    }

    if (this.avPlayer.state === 'completed') {
      this.avPlayer.seek(0, media.SeekMode.SEEK_PREV_SYNC)
      this.currentTimeMs = 0
      this.avPlayer.play()
      return
    }

    if (this.avPlayer.state === 'prepared' || this.avPlayer.state === 'paused') {
      this.avPlayer.play()
    }
  }

  private seekTo(value: number): void {
    this.currentTimeMs = value
    if (this.avPlayer === undefined) {
      return
    }
    if (this.avPlayer.state === 'prepared' || this.avPlayer.state === 'playing' ||
      this.avPlayer.state === 'paused' || this.avPlayer.state === 'completed') {
      this.avPlayer.seek(Math.floor(value), media.SeekMode.SEEK_PREV_SYNC)
    }
  }

  private toggleMute(): void {
    this.isMuted = !this.isMuted
    this.applyVolume()
  }

  private applyVolume(): void {
    if (this.avPlayer === undefined) {
      return
    }
    if (this.avPlayer.state === 'prepared' || this.avPlayer.state === 'playing' ||
      this.avPlayer.state === 'paused' || this.avPlayer.state === 'completed') {
      this.avPlayer.setVolume(this.isMuted ? 0 : 1)
    }
  }

  private handleFullScreen(): void {
    if (this.fullScreenMode) {
      this.onExitFullScreen()
      return
    }

    if (this.avPlayer !== undefined && this.avPlayer.state === 'playing') {
      this.avPlayer.pause()
    }

    AppNavigator.openPerformanceVideoFullscreen(this.navStack, {
      videoUrl: this.videoUrl,
      posterUrl: this.posterUrl,
      title: this.title,
      startPositionMs: this.currentTimeMs,
      isMuted: this.isMuted
    })
  }

  private retry(): void {
    this.releasePlayer()
    this.currentTimeMs = Math.max(0, this.initialPositionMs)
    this.durationMs = 0
    this.hasStarted = false
    this.hasError = false
    this.pendingAutoPlay = true
    this.initializePlayer()
  }

  private releasePlayer(): void {
    const player: media.AVPlayer | undefined = this.avPlayer
    this.avPlayer = undefined
    this.sourceAssigned = false
    if (player === undefined) {
      return
    }
    try {
      player.off('timeUpdate')
      player.off('seekDone')
      player.off('error')
      player.off('stateChange')
      player.release()
    } catch (err) {
    }
  }

  private getSliderMax(): number {
    return this.durationMs > 0 ? this.durationMs : 1
  }

  private formatTime(milliseconds: number): string {
    const totalSeconds: number = Math.max(0, Math.floor(milliseconds / 1000))
    const hours: number = Math.floor(totalSeconds / 3600)
    const minutes: number = Math.floor((totalSeconds % 3600) / 60)
    const seconds: number = totalSeconds % 60
    const minuteText: string = minutes < 10 ? '0' + minutes : String(minutes)
    const secondText: string = seconds < 10 ? '0' + seconds : String(seconds)
    if (hours > 0) {
      const hourText: string = hours < 10 ? '0' + hours : String(hours)
      return hourText + ':' + minuteText + ':' + secondText
    }
    return minuteText + ':' + secondText
  }
}
