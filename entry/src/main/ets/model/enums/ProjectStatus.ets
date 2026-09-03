/**
 * 项目状态
 *
 * 注解：
 * 项目整体状态只表示项目是否整体可展示/可售；
 * 具体按钮仍以场次状态 SessionStatus 为准。
 */
export enum ProjectStatus {
  /** 即将开始 / 预热 */
  COMING_SOON = 'COMING_SOON',

  /** 项目整体可售 */
  ON_SALE = 'ON_SALE',

  /** 项目整体已结束 */
  ENDED = 'ENDED',

  /** 项目已下架 */
  OFFLINE = 'OFFLINE'
}