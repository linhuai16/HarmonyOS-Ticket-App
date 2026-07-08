import { OrderAddress } from "../../model/entity/OrderAddress";

export const orderAddressMockList: OrderAddress[] = [
  {
    orderAddressId: 'order_addr_001',
    orderId: 'order_002',
    receiverName: '张三',
    receiverPhone: '15863257845',
    province: '北京市',
    city: '北京市',
    district: '海淀区',
    detailAddress: '复兴路 69 号附近 8 号楼 1201'
  },
  {
    orderAddressId: 'order_addr_002',
    orderId: 'order_001',
    receiverName: '李四',
    receiverPhone: '15863257845',
    province: '北京市',
    city: '北京市',
    district: '海淀区',
    detailAddress: '复兴路 69 号附近 8 号楼 1203'
  }
]
