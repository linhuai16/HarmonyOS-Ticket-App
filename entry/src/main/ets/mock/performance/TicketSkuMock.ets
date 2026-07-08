import { TicketSku } from '../../model/entity/TicketSku'
import { SkuStatus } from '../../model/enums/SkuStatus'

/**
 * 票档 Mock。
 *
 * 注意：每条 TicketSku 都必须保留 projectId + sessionId，
 * 用于模拟以后数据库按项目、场次查询票档，以及下单时校验项目-场次-票档一致性。
 */
export const ticketSkuMockList: TicketSku[] = [
  {
    skuId: 'sku_1001_bj_580',
    projectId: 'proj_1001',
    sessionId: 'sess_1001_bj_01',
    skuName: '看台 580',
    skuDesc: '看台区域，随机配座',
    price: 580,
    stockAvailable: 36,
    stockLocked: 4,
    soldCount: 40,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  },
  {
    skuId: 'sku_1001_bj_980',
    projectId: 'proj_1001',
    sessionId: 'sess_1001_bj_01',
    skuName: '内场 980',
    skuDesc: '内场区域，随机配座',
    price: 980,
    stockAvailable: 12,
    stockLocked: 3,
    soldCount: 45,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 2
  },
  {
    skuId: 'sku_1001_bj_1980',
    projectId: 'proj_1001',
    sessionId: 'sess_1001_bj_01',
    skuName: 'VIP 1980',
    skuDesc: 'VIP 区域，数量有限',
    price: 1980,
    stockAvailable: 0,
    stockLocked: 0,
    soldCount: 20,
    skuStatus: SkuStatus.SOLD_OUT,
    sortOrder: 3
  },
  {
    skuId: 'sku_1001_sh_680',
    projectId: 'proj_1001',
    sessionId: 'sess_1001_sh_01',
    skuName: '看台 680',
    skuDesc: '预售票档',
    price: 680,
    stockAvailable: 100,
    stockLocked: 0,
    soldCount: 0,
    skuStatus: SkuStatus.PRESALE,
    sortOrder: 1
  },
  {
    skuId: 'sku_1002_bj_180',
    projectId: 'proj_1002',
    sessionId: 'sess_1002_bj_01',
    skuName: '三楼 180',
    skuDesc: '三楼观演区',
    price: 180,
    stockAvailable: 60,
    stockLocked: 2,
    soldCount: 58,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  },
  {
    skuId: 'sku_1002_bj_680',
    projectId: 'proj_1002',
    sessionId: 'sess_1002_bj_01',
    skuName: '一楼 680',
    skuDesc: '一楼观演区',
    price: 680,
    stockAvailable: 18,
    stockLocked: 2,
    soldCount: 40,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 2
  },
  {
    skuId: 'sku_1002_bj_1080',
    projectId: 'proj_1002',
    sessionId: 'sess_1002_bj_01',
    skuName: 'VIP 1080',
    skuDesc: '前排观演区',
    price: 1080,
    stockAvailable: 3,
    stockLocked: 0,
    soldCount: 17,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 3
  },
  {
    skuId: 'sku_1003_sz_320',
    projectId: 'proj_1003',
    sessionId: 'sess_1003_sz_01',
    skuName: '单日票 320',
    skuDesc: '音乐节单日通票',
    price: 320,
    stockAvailable: 210,
    stockLocked: 10,
    soldCount: 280,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  },
  {
    skuId: 'sku_1003_sz_880',
    projectId: 'proj_1003',
    sessionId: 'sess_1003_sz_01',
    skuName: 'VIP 880',
    skuDesc: 'VIP 观演权益',
    price: 880,
    stockAvailable: 15,
    stockLocked: 5,
    soldCount: 60,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 2
  },
  {
    skuId: 'sku_1004_cd_99',
    projectId: 'proj_1004',
    sessionId: 'sess_1004_cd_01',
    skuName: '普通票 99',
    price: 99,
    stockAvailable: 0,
    stockLocked: 0,
    soldCount: 120,
    skuStatus: SkuStatus.SOLD_OUT,
    sortOrder: 1
  },
  {
    skuId: 'sku_1005_gz_268',
    projectId: 'proj_1005',
    sessionId: 'sess_1005_gz_01',
    skuName: '单人票 268',
    price: 268,
    stockAvailable: 28,
    stockLocked: 2,
    soldCount: 60,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  },
  {
    skuId: 'sku_1006_bj_120',
    projectId: 'proj_1006',
    sessionId: 'sess_1006_bj_01',
    skuName: '楼座 120',
    price: 120,
    stockAvailable: 45,
    stockLocked: 0,
    soldCount: 55,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  },
  {
    skuId: 'sku_1008_sh_280',
    projectId: 'proj_1008',
    sessionId: 'sess_1008_sh_01',
    skuName: '看台 280',
    price: 280,
    stockAvailable: 22,
    stockLocked: 1,
    soldCount: 57,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  }

  ,{
    skuId: 'sku_1001_bj_future_980',
    projectId: 'proj_1001',
    sessionId: 'sess_1001_bj_future_01',
    skuName: '状态验证票 980',
    skuDesc: '用于票夹各状态页面验证',
    price: 980,
    stockAvailable: 18,
    stockLocked: 0,
    soldCount: 2,
    skuStatus: SkuStatus.ON_SALE,
    sortOrder: 1
  }
]
