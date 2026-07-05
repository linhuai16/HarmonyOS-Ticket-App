import { SkuStatus } from "../enums/SkuStatus"

/**
 * 票档 / 票品
 * 注解：
 * 表示某个场次下的单个价格档位。
 * 例如：看台380、内场880、VIP1280。
 */
export interface TicketSku {
  /** 本系统票档ID */
  skuId: string

  /** 所属项目ID */
  projectId: string

  /** 所属场次ID */
  sessionId: string

  /** 票档名称 */
  skuName: string

  /** 票档描述，如“看台A区” */
  skuDesc?: string

  /** 单张票价，单位：元 */
  price: number

  /** 可售库存 */
  stockAvailable: number

  /** 锁定库存，下单未支付时占用 */
  stockLocked: number

  /** 已售数量 */
  soldCount: number

  /** 票档状态 */
  skuStatus: SkuStatus

  /** 票档展示排序值 */
  sortOrder?: number
}
