import { NoticeItem } from '../../model/entity/NoticeItem'

export const noticeItemMockList: NoticeItem[] = [
  {
    noticeId: 'notice_limit_rule',
    title: '限购规则',
    iconUrl: 'item_xiangouguize',
    description: '每笔订单最多购买 6 张；同一账号、同一场次购买数量不得超过场次限购数量，具体以提交订单页展示为准。'
  },
  {
    noticeId: 'notice_entry_method',
    title: '入场方式',
    iconUrl: 'item_ruchangfangshi',
    description: '本项目支持电子票入场。电子票生成后，请在票夹中出示二维码，现场核验通过后入场。'
  },
  {
    noticeId: 'notice_child_ticket',
    title: '儿童购票',
    iconUrl: 'item_ertonggoupiao',
    description: '儿童是否需要购票以项目现场规则为准。实名制项目中，儿童如需入场也应按要求填写对应观演人信息。'
  },
  {
    noticeId: 'notice_invoice',
    title: '发票说明',
    iconUrl: 'item_fapiaoshuoming',
    description: '本期暂不支持在线申请电子发票。后续可在订单详情页补充发票申请入口。'
  },
  {
    noticeId: 'notice_real_name',
    title: '实名购票',
    iconUrl: 'item_shimingzhi',
    description: '本项目为实名制购票，一张票对应一名观演人。下单时需选择与购票数量一致的观演人，入场时需携带购票时填写的有效证件。'
  },
  {
    noticeId: 'notice_refund_rule',
    title: '退票规则',
    iconUrl: 'item_tuipiaoguize',
    description: '退票规则以演出项目配置为准。条件退项目会根据距离开演时间计算手续费；不可退项目支付成功后不支持主动退款。'
  },
  {
    noticeId: 'notice_forbidden_items',
    title: '禁带物品',
    iconUrl: 'item_jindaiwupin',
    description: '请勿携带易燃易爆物品、管制器具、瓶装饮料、大型行李、专业摄影摄像设备等影响现场安全或观演秩序的物品。'
  },
  {
    noticeId: 'notice_security_check',
    title: '安检说明',
    iconUrl: 'item_anjian',
    description: '入场前需配合现场工作人员进行票务核验、证件核验和安全检查。请预留充足入场时间，避免影响观演。'
  }
]
