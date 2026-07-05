import { HomePage } from './home/HomePage'
import { MinePage } from './mine/MinePage'
import { WindowImmersiveUtil } from '../common/WindowImmersiveUtil'

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0

  aboutToAppear(): void {
    this.updateSystemBarColor(this.currentTabIndex)
  }

  onPageShow(): void {
    this.updateSystemBarColor(this.currentTabIndex)
  }

  build() {
    Column() {
      Stack() {
        if (this.currentTabIndex === 0) {
          HomePage()
        } else {
          MinePage()
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      this.BottomTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private BottomTabBar() {
    Row() {
      this.BottomTabItem('首页', 0)
      this.BottomTabItem('我的', 1)
    }
    .width('100%')
    .height(80)
    .padding({ bottom: 8 })
    .backgroundColor(this.currentTabIndex === 1 ? '#FFEDEF' : '#FFFFFF')
    // 底部导航栏本身可以延伸到导航条区域，保证底部沉浸式颜色连续；
    // 可交互文字仍通过 paddingBottom 保持在安全位置内。
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  private BottomTabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.currentTabIndex === index ? '#1677FF' : '#333333')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.currentTabIndex === index) {
        return
      }
      this.currentTabIndex = index
      this.updateSystemBarColor(index)
    })
  }

  private updateSystemBarColor(index: number): void {
    if (index === 1) {
      WindowImmersiveUtil.apply(this, '#FFEDEF', '#FFEDEF')
      return
    }

    WindowImmersiveUtil.apply(this, '#F5F5F5', '#FFFFFF')
  }
}
