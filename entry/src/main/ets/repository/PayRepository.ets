import { OrderStatus } from '../model/enums/OrderStatus'
import { PayMethod } from '../model/enums/PayMethod'
import { ApiClient } from '../network/ApiClient'
import { UserSessionUtil } from '../utils/UserSessionUtil'
import { AppStorageVersionUtil } from '../utils/AppStorageVersionUtil'

export interface MockPaySuccessResponse {
  orderId: string
  orderNo: string
  orderStatus: OrderStatus
  payAmount: number
  payTime: string
}

interface BackendMockPaySuccessResponse {
  orderId: number | string
  orderNo: string
  orderStatus: string
  payAmount: number
  payTime: string
}

interface MockPaySuccessRequestBody {
  userId: number
  payMethod: PayMethod
}

/** 支付 Repository：调用 SpringBoot Mock 支付成功接口。 */
export class PayRepository {
  async mockPaySuccess(
    orderId: string,
    payMethod: PayMethod = PayMethod.ALIPAY,
    userId: string = UserSessionUtil.getCurrentUserId()
  ): Promise<MockPaySuccessResponse | undefined> {
    if (orderId.length === 0 || userId.length === 0) {
      return undefined
    }

    const body: MockPaySuccessRequestBody = {
      userId: Number(userId),
      payMethod: payMethod
    }
    const response: BackendMockPaySuccessResponse =
      await ApiClient.post<BackendMockPaySuccessResponse>('/api/mock/orders/' + encodeURIComponent(orderId) + '/pay-success', body)

    const result: MockPaySuccessResponse = {
      orderId: String(response.orderId),
      orderNo: response.orderNo,
      orderStatus: response.orderStatus as OrderStatus,
      payAmount: Number(response.payAmount),
      payTime: response.payTime
    }

    if (result.orderStatus === OrderStatus.WAIT_USE) {
      AppStorageVersionUtil.bumpOrderTicketRelatedVersions()
    }

    return result
  }
}
