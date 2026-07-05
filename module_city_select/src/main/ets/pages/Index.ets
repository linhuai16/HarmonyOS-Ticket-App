/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { SingleBtn } from '../components/SingleBtn';
import { Utils } from '../common/Utils';
import { ALL_CITY_LIST, HOT_CITY_LIST, LOCATION_TEXT_WIDTH } from '../common/Constant';
import { CitySelectController, ICityGroup } from '../common/Model';
import { LengthMetrics, MeasureUtils } from '@kit.ArkUI';


@Preview
@ComponentV2
export struct UICitySelect {
  @Param currentCity: string = '';
  @Param controller: CitySelectController = new CitySelectController();
  @Local uiContext: UIContext = this.getUIContext();
  @Local uiContextMeasure: MeasureUtils = this.uiContext.getMeasureUtils();
  @Local showSearchRsp: boolean = false;
  @Local searchKey: string = '';
  @Local searchList: string[] = [];
  @Local selectIndex: number = 0;
  @Local isLoading: boolean = false;
  @Local isShowPop: boolean = false;
  scrollerOut: Scroller = new Scroller();
  scroller: Scroller = new Scroller();
  alphaIndexList: string[] = Utils.generateAlphaList(ALL_CITY_LIST);
  flatList: string[] = [];

  @Computed
  get emptyLabel() {
    if (this.searchKey && this.searchList.length === 0) {
      return '暂未查询相关城市信息';
    }
    return '输入关键词查找结果';
  }

  @Event goBack: (city?: string) => void = () => {
  };
  @Event emitUpdateCityLocation: (city: string) => void = () => {
  };

  isOverFlow(str: string): boolean {
    const textWidth = this.uiContextMeasure.measureText({
      textContent: str,
      fontSize: $r('sys.float.Caption_L'),
      constraintWidth: LOCATION_TEXT_WIDTH,
      overflow: TextOverflow.Ellipsis,
      maxLines: 1,
      fontWeight: FontWeight.Regular,
    });
    return textWidth > vp2px(LOCATION_TEXT_WIDTH);
  }

  aboutToAppear(): void {
    this.isShowPop = true;
    this.controller.onBackPressed = () => {
      if (this.showSearchRsp) {
        this.searchKey = '';
        this.searchList = [];
        this.showSearchRsp = false;
        return true;
      }
      return false;
    };

    this.flatList = ALL_CITY_LIST.reduce((acc, obj) => {
      return acc.concat(obj.list);
    }, ['']);
  }

  build() {
    Stack() {
      Scroll(this.scrollerOut) {
        Column() {
          this.TopSearch();
          Stack() {
            Column({ space: 24 }) {
              Column({ space: 24 }) {
                this.CurrentLocation();
                this.HotCityList();
              }
              .padding({ left: 16, right: 16 });

              this.AllCityList();

            }
            .alignItems(HorizontalAlign.Start);

            if (this.showSearchRsp) {
              this.SearchRsp();
            }
          }
          .alignContent(Alignment.Top);
        };
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);

    }
    .alignContent(Alignment.End)
    .padding({ bottom: 10 });
  }

  onClickCity(city: string) {
    this.isShowPop = false;
    this.goBack(city);
  }

  @Builder
  TopSearch() {
    Row({ space: 10 }) {
      Search({ value: $$this.searchKey, placeholder: '搜索城市' }).layoutWeight(1)
        .onClick(() => {
          this.showSearchRsp = true;
        })
        .onChange(() => {
          if (!this.searchKey) {
            this.searchList = [];
            return;
          }
          this.searchList = this.flatList.filter(v => v.includes(this.searchKey));
        });

      Text('取消')
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_primary'))
        .focusable(true)
        .id('cancelBtn')
        .onClick(() => {
          this.showSearchRsp = false;
          this.searchKey = '';
          this.getUIContext().getFocusController().requestFocus('cancelBtn')
        });
    }
    .width('100%')
    .height(66)
    .padding({ left: 10, right: 10, bottom: 10 });
  }

  @Builder
  SearchRsp() {
    Scroll() {
      Column() {
        if (!this.searchList.length) {
          Column({ space: 10 }) {
            Image($r('app.media.ic_empty')).width(56).height(47);
            Text(this.emptyLabel).fontColor('#565656').fontSize(14);
          }
          .width('100%')
          .margin({ top: 200 });
        } else {
          ForEach(this.searchList, (item: string) => {
            Column() {
              Text(item).height(40);
              Divider();
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)
            .onClick(() => {
              this.onClickCity(item);
            });
          }, (v: string) => v);
        }
      };
    }
    .padding({ left: 10, right: 10 })
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .height('calc(100% - 66vp)')
    .backgroundColor($r('sys.color.background_primary'));

  }

  @Builder
  CurrentLocation() {
    Column({ space: 12 }) {
      Text('定位')
        .baseTitleExtend();

      Row() {
        Button() {
          Row({ space: 4 }) {
            Image($r('app.media.local_fill')).width(16).height(16);
            Text(this.currentCity || '无法获取')
              .constraintSize({ maxWidth: LOCATION_TEXT_WIDTH })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize($r('sys.float.Caption_L'))
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular);

          };
        }
        .width(76)
        .height(28)
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .bindPopup(this.isOverFlow(this.currentCity) && this.isShowPop, {
          message: this.currentCity,
        })
        .onClick(() => {
          if (this.currentCity) {
            this.onClickCity(this.currentCity);
          }
        });


        Blank();
        if (this.isLoading) {
          LoadingProgress().width(24).height(24).color($r('app.color.common_theme_color')).margin({ left: 10 });
        } else {
          Text('重新定位')
            .fontSize(14)
            .fontColor($r('app.color.common_theme_color'))
            .onClick(() => {
              this.isLoading = true;
              Utils.applyLocationPermission().then((cityLoc: string) => {
                this.isLoading = false;
                this.emitUpdateCityLocation(cityLoc);
              });
            });
        }

      }
      .width('100%');
    }
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  HotCityList() {
    Column({ space: 12 }) {
      Text('热门城市').baseTitleExtend();
      Grid() {
        ForEach(HOT_CITY_LIST, (item: string) => {
          GridItem() {
            Button(item)
              .width(76)
              .height(28)
              .padding(0)
              .borderRadius(8)
              .fontSize($r('sys.float.Caption_L'))
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Regular)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onClick(() => {
                this.onClickCity(item);
              });
          };
        }, (v: string) => v);
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8);
    }
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  AllCityList() {
    Column({ space: 24 }) {
      Column({ space: 12 }) {
        Text('字母索引').baseTitleExtend();
        Grid() {
          ForEach(this.alphaIndexList, (item: string, index) => {
            GridItem() {
              Text(item)
                .fontColor($r('sys.color.font_primary'))
                .fontSize($r('sys.float.Caption_L'))
                .fontWeight(FontWeight.Regular);
            }.height(28).borderRadius(8).backgroundColor($r('sys.color.comp_background_tertiary')).onClick(() => {
              this.scrollerOut.scrollEdge(Edge.Bottom);
              this.scroller.scrollToIndex(index);
            });

          }, (item: string) => item);
        }.rowsGap(8).columnsGap(8).columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr');

      }.width('100%').alignItems(HorizontalAlign.Start);

      List({
        space: 10,
        scroller: this.scroller,
      }) {
        ForEach(ALL_CITY_LIST, (item: ICityGroup) => {
          ListItem() {
            Column() {
              Text(item.name).baseTitleExtend().margin({ bottom: 12 });
              ForEach(item.list, (city: string) => {
                Column() {
                  Text(city)
                    .width('100%')
                    .height(48)
                    .baseTitleExtend()
                    .onClick(() => {
                      this.onClickCity(city);
                    });
                  Divider();
                };
              }, (v: string) => v);
            }
            .alignItems(HorizontalAlign.Start);
          };
        }, (item: ICityGroup) => item.name);
      }
      .width('100%')
      .height('calc(100% - 189vp)')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST,
      })
      .onScrollIndex((start: number) => {
        this.selectIndex = start;
      });
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16 });
  }
}

@Extend(Text)
function baseTitleExtend() {
  .fontSize($r('sys.float.Body_L'))
  .fontWeight(FontWeight.Medium)
  .fontColor($r('sys.color.font_primary'));
}
