import { UserAddress } from '../../model/entity/UserAddress'

export const userAddressMockList: UserAddress[] = [
  {
    addressId: 'addr_001',
    userId: 'user_001',
    receiverName: '林淮',
    receiverPhone: '15863257845',
    province: '北京市',
    city: '北京市',
    district: '海淀区',
    detailAddress: '复兴路 69 号附近 8 号楼 1201',
    isDefault: true
  },
  {
    addressId: 'addr_002',
    userId: 'user_001',
    receiverName: '张三',
    receiverPhone: '18834522275',
    province: '山西省',
    city: '太原市',
    district: '迎泽区',
    detailAddress: '青年路 88 号 2 单元 502',
    isDefault: false
  }
]
