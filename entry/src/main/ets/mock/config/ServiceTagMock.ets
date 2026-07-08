import { ServiceTag } from '../../model/entity/ServiceTag'

export const SERVICE_TAG_REALNAME: ServiceTag = {
  tagId: 'tag_realname',
  tagName: '实名制购票',
  iconUrl: 'item_shimingzhi',
  description: '一票一证入场'
}

export const SERVICE_TAG_ETICKET: ServiceTag = {
  tagId: 'tag_eticket',
  tagName: '电子票',
  iconUrl: 'ic_dianziticket',
  description: '电子票入场'
}

export const SERVICE_TAG_CONDITIONAL_REFUND: ServiceTag = {
  tagId: 'tag_conditional_refund',
  tagName: '条件退',
  iconUrl: 'ic_tiaojiantui',
  description: '符合规则可退款'
}

export const SERVICE_TAG_NO_REFUND: ServiceTag = {
  tagId: 'tag_no_refund',
  tagName: '不可退',
  iconUrl: 'ic_buketui',
  description: '订单不可退款'
}

export const serviceTagMockList: ServiceTag[] = [
  SERVICE_TAG_REALNAME,
  SERVICE_TAG_ETICKET,
  SERVICE_TAG_CONDITIONAL_REFUND,
  SERVICE_TAG_NO_REFUND
]
