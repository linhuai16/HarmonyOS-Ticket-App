import { PerformanceSessionItemVO, NoticeItemVO } from '../../model/vo/performance/PerformanceDetailVO'
import { SessionStatus } from '../../model/enums/SessionStatus'
import { MediaResourceUtil } from '../../common/MediaResourceUtil'
import { ResponsiveLayout } from '../../common/ResponsiveLayout'

@Component
export struct PerformanceSessionSelector {
  sessions: PerformanceSessionItemVO[] = []
  selectedSessionId: string = ''
  pageVersion: number = 0
  tablet: boolean = false
  onSelect: (sessionId: string) => void = (_sessionId: string): void => {}

  build() {
    Column() {
      Text('场次选择')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Scroll() {
        Row() {
          ForEach(this.sessions, (item: PerformanceSessionItemVO) => {
            Column() {
              Text(item.stationName)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.selectedSessionId === item.sessionId ? '#E33B3B' : '#222222')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(item.startTime)
                .fontSize(this.tablet ? 14 : 12)
                .fontColor('#666666')
                .margin({ top: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.sessionStatusText(item.sessionStatus))
                .fontSize(11)
                .fontColor(this.selectedSessionId === item.sessionId ? '#E33B3B' : '#999999')
                .margin({ top: 4 })
            }
            .width(this.tablet ? 170 : 120)
            .height(86)
            .padding(10)
            .margin({ right: 8, top: 10 })
            .backgroundColor(this.selectedSessionId === item.sessionId ? '#FFECEC' : '#F7F7F7')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.onSelect(item.sessionId)
            })
          }, (item: PerformanceSessionItemVO) => item.sessionId + '_' + item.sessionStatus + '_' + item.cityName + '_' + item.stationName + '_' + item.startTime + '_' + String(this.pageVersion))
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Top)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private sessionStatusText(status: SessionStatus): string {
    if (status === SessionStatus.PRESALE) return '预售'
    if (status === SessionStatus.ON_SALE) return '热卖'
    if (status === SessionStatus.SOLD_OUT) return '已售罄'
    if (status === SessionStatus.ENDED) return '已结束'
    return ''
  }
}

@Component
export struct PerformanceVenueCard {
  venueName: string = ''
  venueAddress: string = ''
  tablet: boolean = false
  onNavigate: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        Text(this.venueName.length > 0 ? this.venueName : '暂无场馆信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text('导航到场馆 >')
          .fontSize(this.tablet ? 15 : 13)
          .fontColor('#E33B3B')
          .margin({ left: 12 })
          .onClick(() => {
            this.onNavigate()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.venueAddress.length > 0 ? this.venueAddress : '暂无场馆地址')
        .fontSize(this.tablet ? 15 : 13)
        .fontColor('#666666')
        .margin({ top: 8 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}

@Component
export struct PerformanceNoticeGrid {
  items: NoticeItemVO[] = []
  tablet: boolean = false
  wide: boolean = false
  onSelect: (item: NoticeItemVO) => void = (_item: NoticeItemVO): void => {}
  onMeasured: (area: Area) => void = (_area: Area): void => {}

  build() {
    Column() {
      Text('观演须知')
        .fontSize(this.tablet ? 20 : 17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')

      Grid() {
        ForEach(this.items, (item: NoticeItemVO) => {
          GridItem() {
            Column() {
              Row() {
                if (item.iconUrl !== undefined) {
                  Image(MediaResourceUtil.getMedia(item.iconUrl))
                    .width(18)
                    .height(18)
                    .margin({ right: 6 })
                }

                Text(item.title)
                  .fontSize(this.tablet ? 15 : 13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')

              Text(item.description)
                .fontSize(this.tablet ? 13 : 11)
                .fontColor('#666666')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
                .width('100%')
            }
            .width('100%')
            .height(this.tablet ? 72 : 54)
            .padding(this.tablet ? 12 : 8)
            .backgroundColor('#F7F7F7')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.onSelect(item)
            })
          }
        }, (item: NoticeItemVO) => item.noticeId)
      }
      .columnsTemplate(this.tablet ? (this.wide ? '1fr 1fr 1fr 1fr' : '1fr 1fr 1fr') : '1fr 1fr')
      .columnsGap(this.tablet ? 12 : 8)
      .rowsGap(this.tablet ? 12 : 8)
      .margin({ top: 10 })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(this.tablet ? 18 : 12)
    .margin({ top: this.tablet ? 16 : 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.onMeasured(newValue)
    })
  }
}

@Component
export struct PerformanceBottomActionBar {
  @Prop wanted: boolean = false
  canBuy: boolean = false
  buyButtonText: string = ''
  onWant: () => void = (): void => {}
  onBuy: () => void = (): void => {}

  build() {
    Row() {
      Column() {
        Image($r('app.media.page_xiangkan'))
          .width(22)
          .height(22)
          .fillColor(this.wanted ? '#E33B3B' : '#666666')

        Text(this.wanted ? '已想看' : '想看')
          .fontSize(12)
          .fontColor(this.wanted ? '#E33B3B' : '#666666')
          .margin({ top: 2 })
      }
      .width(70)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.onWant()
      })

      Button(this.buyButtonText)
        .height(44)
        .layoutWeight(1)
        .fontSize(16)
        .backgroundColor(this.canBuy ? '#E33B3B' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .borderRadius(22)
        .enabled(this.canBuy)
        .onClick(() => {
          this.onBuy()
        })
    }
    .width('100%')
    .height(84)
    .padding({ left: 12, right: 12, top: 8, bottom: 20 })
    .backgroundColor('#FFFFFF')
  }
}

@Component
export struct PerformanceServiceTagDialog {
  title: string = ''
  description: string = ''
  items: string[] = []
  tablet: boolean = false
  onClose: () => void = (): void => {}

  build() {
    Column() {
      Column() {
        Row() {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .layoutWeight(1)

          Text('×')
            .fontSize(24)
            .fontColor('#888888')
            .width(32)
            .height(32)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.onClose()
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.isRefundTag() && this.items.length > 0) {
          Column() {
            Row() {
              Text('时间区间')
                .width('43%')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#444444')
                .padding({ left: 10, right: 8, top: 9, bottom: 9 })

              Text('退款规则')
                .layoutWeight(1)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#444444')
                .padding({ left: 10, right: 10, top: 9, bottom: 9 })
            }
            .width('100%')
            .backgroundColor('#F6F7F9')

            ForEach(this.items, (detail: string) => {
              Row() {
                Text(this.detailCondition(detail))
                  .width('43%')
                  .fontSize(12)
                  .fontColor('#555555')
                  .lineHeight(18)
                  .padding({ left: 10, right: 8, top: 10, bottom: 10 })

                Text(this.detailRule(detail))
                  .layoutWeight(1)
                  .fontSize(12)
                  .fontColor(this.detailRule(detail).includes('不可退') ? '#E5484D' : '#555555')
                  .lineHeight(18)
                  .padding({ left: 10, right: 10, top: 10, bottom: 10 })
              }
              .width('100%')
              .border({ width: { top: 0.5 }, color: '#E8E8E8' })
            }, (detail: string) => detail)
          }
          .width('100%')
          .margin({ top: 16 })
          .border({ width: 0.5, color: '#E2E4E8' })
          .borderRadius(10)
          .clip(true)
        } else {
          Text(this.description.length > 0 ? this.description : '暂无服务说明')
            .fontSize(14)
            .fontColor('#555555')
            .lineHeight(22)
            .width('100%')
            .margin({ top: 16 })
        }

        Button('知道了')
          .width('100%')
          .height(42)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor('#E33B3B')
          .borderRadius(21)
          .margin({ top: 18 })
          .onClick(() => {
            this.onClose()
          })
      }
      .width(this.tablet ? '68%' : '88%')
      .constraintSize({ maxWidth: ResponsiveLayout.DIALOG_MAX_WIDTH })
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#66000000')
    .zIndex(60)
  }

  private isRefundTag(): boolean {
    return this.title === '条件退' || this.title === '不可退'
  }

  private detailCondition(detail: string): string {
    const separator: number = this.detailSeparator(detail)
    if (separator < 0) return '退款阶段'
    return detail.substring(0, separator).replace(/^•\s*/, '').trim()
  }

  private detailRule(detail: string): string {
    const separator: number = this.detailSeparator(detail)
    if (separator < 0) return detail.replace(/^•\s*/, '').trim()
    return detail.substring(separator + 1).trim()
  }

  private detailSeparator(detail: string): number {
    const chineseSeparator: number = detail.indexOf('：')
    if (chineseSeparator >= 0) return chineseSeparator
    return detail.indexOf(':')
  }
}
