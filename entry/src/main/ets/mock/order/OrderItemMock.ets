import { OrderItem } from '../../model/entity/OrderItem'

export const orderItemMockList: OrderItem[] = [
  {
    orderItemId: 'order_item_001',
    orderId: 'order_001',
    skuId: 'sku_1001_bj_980',
    skuName: '内场 980',
    unitPrice: 980,
    quantity: 2,
    subtotalAmount: 1960,
  },
  {
    orderItemId: 'order_item_002',
    orderId: 'order_002',
    skuId: 'sku_1002_bj_680',
    skuName: '一楼 680',
    unitPrice: 680,
    quantity: 1,
    subtotalAmount: 680,
  },
  {
    orderItemId: 'order_item_003',
    orderId: 'order_003',
    skuId: 'sku_1006_bj_120',
    skuName: '楼座 120',
    unitPrice: 120,
    quantity: 2,
    subtotalAmount: 240,
  },
  {
    orderItemId: 'order_item_004',
    orderId: 'order_004',
    skuId: 'sku_1005_gz_268',
    skuName: '单人票 268',
    unitPrice: 268,
    quantity: 1,
    subtotalAmount: 268,
  },
  {
    orderItemId: 'order_item_005',
    orderId: 'order_005',
    skuId: 'sku_1003_sz_320',
    skuName: '单日票 320',
    unitPrice: 320,
    quantity: 1,
    subtotalAmount: 320,
  }

  ,{
    orderItemId: 'order_item_006',
    orderId: 'order_006',
    skuId: 'sku_1001_bj_future_980',
    skuName: '状态验证票 980',
    unitPrice: 980,
    quantity: 1,
    subtotalAmount: 980,
  },
  {
    orderItemId: 'order_item_007',
    orderId: 'order_007',
    skuId: 'sku_1001_bj_future_980',
    skuName: '状态验证票 980',
    unitPrice: 980,
    quantity: 1,
    subtotalAmount: 980,
  }
]
