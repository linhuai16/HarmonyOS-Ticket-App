export interface AddressListPageVO {
  addresses: AddressItemVO[]
}
export interface AddressItemVO {
  addressId: string
  receiverName: string
  maskedReceiverPhone: string
  fullAddress: string
  isDefault: boolean
}
