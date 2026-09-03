import { AiPerformanceCardVO } from '../model/AiChatVO'
import { AppNavigator } from '../../../navigation/AppNavigation'
import { MediaResourceUtil } from '../../../common/MediaResourceUtil'

@Component
export struct AiPerformanceCard {
  @Consume('appNavStack') navStack: NavPathStack
  @State item: AiPerformanceCardVO = new AiPerformanceCardVO()
  wide: boolean = false
  onOpen: (item: AiPerformanceCardVO) => void = (_item: AiPerformanceCardVO): void => {}

  build() {
    Row() {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(MediaResourceUtil.getMedia(this.item.posterUrl))
          .width(this.wide ? 108 : 92)
          .height(this.wide ? 144 : 124)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#ECECEC')
          .borderRadius(10)

        if (this.item.categoryName.length > 0) {
          Text(this.item.categoryName)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .backgroundColor('#E33B3B')
            .borderRadius({ topLeft: 10, bottomRight: 8 })
        }
      }
      .width(this.wide ? 108 : 92)
      .height(this.wide ? 144 : 124)

      Column() {
        Text(this.item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(this.wide ? 3 : 2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.item.startTime.length > 0) {
          Text(this.item.startTime)
            .fontSize(13)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })
            .width('100%')
        }

        Text(this.locationText())
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(this.wide ? 2 : 1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
          .width('100%')

        Row() {
          Text(this.priceText())
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E33B3B')
          Blank()
          Text('查看详情 ›')
            .fontSize(13)
            .fontColor('#1677FF')
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .layoutWeight(1)
      .constraintSize({ minHeight: this.wide ? 144 : 124 })
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .constraintSize({ minWidth: 280, maxWidth: this.wide ? 560 : 680 })
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: 1, color: '#E8E8E8' })
    .onClick(() => {
      this.onOpen(this.item)
      AppNavigator.openPerformanceDetail(this.navStack, {
        projectId: this.item.projectId,
        sessionId: this.item.sessionId,
        posterUrl: this.item.posterUrl,
        title: this.item.title,
        categoryName: this.item.categoryName,
        startTime: this.item.startTime,
        cityName: this.item.cityName,
        venueName: this.item.venueName,
        minPrice: this.item.minPrice,
        maxPrice: this.item.maxPrice,
        source: 'AI_' + this.item.projectId
      })
    })
  }

  private locationText(): string {
    if (this.item.cityName.length > 0 && this.item.venueName.length > 0) {
      return this.item.cityName + ' | ' + this.item.venueName
    }
    return this.item.cityName + this.item.venueName
  }

  private priceText(): string {
    if (this.item.minPrice === undefined) return '价格待定'
    if (this.item.maxPrice !== undefined && this.item.maxPrice !== this.item.minPrice) {
      return '¥' + this.item.minPrice + ' - ¥' + this.item.maxPrice
    }
    return '¥' + this.item.minPrice + ' 起'
  }
}
