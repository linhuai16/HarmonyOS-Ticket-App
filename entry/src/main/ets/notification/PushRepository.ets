import { ApiClient } from '../network/ApiClient'
import { ServiceCardBinding } from '../servicecard/ServiceCardStore'

class PushDeviceRequest {
  userId: number
  deviceId: string
  pushToken: string
  serviceCards: ServiceCardBinding[]

  constructor(userId: string, deviceId: string, pushToken: string, serviceCards: ServiceCardBinding[]) {
    this.userId = Number(userId)
    this.deviceId = deviceId
    this.pushToken = pushToken
    this.serviceCards = serviceCards
  }
}

interface PushDeviceResponse {
  bound?: boolean
  unbound?: boolean
  bindingId?: number | string
}

export class PushRepository {
  static async bind(userId: string, deviceId: string, pushToken: string,
    serviceCards: ServiceCardBinding[]): Promise<boolean> {
    const result: PushDeviceResponse = await ApiClient.post<PushDeviceResponse>('/api/push/devices/bind',
      new PushDeviceRequest(userId, deviceId, pushToken, serviceCards))
    return result.bound === true
  }

  static async unbind(userId: string, deviceId: string, pushToken: string): Promise<boolean> {
    const result: PushDeviceResponse = await ApiClient.post<PushDeviceResponse>('/api/push/devices/unbind',
      new PushDeviceRequest(userId, deviceId, pushToken, []))
    return result.unbound === true
  }
}
