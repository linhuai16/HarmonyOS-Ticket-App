import { ApiClient } from '../network/ApiClient'

// 图片资源映射工具：兼容应用内资源名、完整网络 URL 和后端 /media/** 相对地址。
export class MediaResourceUtil {
  static getMedia(name: string | undefined | null): ResourceStr {
    const safeName: string = name?.trim() ?? ''
    if (safeName.length === 0) {
      return $r('app.media.background')
    }

    if (safeName.startsWith('http://') ||
      safeName.startsWith('https://') ||
      safeName.startsWith('data:image/') ||
      safeName.startsWith('/')) {
      const resolvedUrl: string = ApiClient.resolveMediaUrl(safeName)
      return resolvedUrl.length > 0 ? resolvedUrl : $r('app.media.background')
    }

    switch (safeName) {
      case 'yanchanghui':
        return $r('app.media.yanchanghui')
      case 'huajugeju':
        return $r('app.media.huajugeju')
      case 'yinlejie':
        return $r('app.media.yinlejie')
      case 'tuokouxiu':
        return $r('app.media.tuokouxiu')
      case 'hongsejuchang':
        return $r('app.media.hongsejuchang')
      case 'xiangsheng':
        return $r('app.media.xiangsheng')
      case 'xiqu':
        return $r('app.media.xiqu')
      case 'wudao':
        return $r('app.media.wudao')
      case 'yanchanghui_ZhouJieLunYanchu':
      case 'ZhouJieLunYanchu':
        return $r('app.media.yanchanghui_ZhouJieLunYanchu')
      case 'huajuYanchu':
      case 'aiyueZhiChengYanchu':
        return $r('app.media.huajuYanchu')
      case 'YinyuejieYanchu':
        return $r('app.media.YinyuejieYanchu')
      case 'TuokouxiuYanchu':
        return $r('app.media.TuokouxiuYanchu')
      case 'juchang_MichengYanchu':
      case 'MichengYanchu':
        return $r('app.media.juchang_MichengYanchu')
      case 'XiangShengYanchu':
        return $r('app.media.XiangShengYanchu')
      case 'xiqu_muDanTingYanchu':
        return $r('app.media.xiqu_muDanTingYanchu')
      case 'WujuYanchu':
        return $r('app.media.WujuYanchu')
      case 'page_xiangkan':
        return $r('app.media.page_xiangkan')
      case 'page_xiala_shang':
        return $r('app.media.page_xiala_shang')
      case 'page_xiala_xia':
        return $r('app.media.page_xiala_xia')
      case 'item_xiangouguize':
        return $r('app.media.item_xiangouguize')
      case 'item_ruchangfangshi':
        return $r('app.media.item_ruchangfangshi')
      case 'item_ertonggoupiao':
        return $r('app.media.item_ertonggoupiao')
      case 'item_fapiaoshuoming':
        return $r('app.media.item_fapiaoshuoming')
      case 'item_shimingzhi':
        return $r('app.media.item_shimingzhi')
      case 'item_tuipiaoguize':
        return $r('app.media.item_tuipiaoguize')
      case 'item_jindaiwupin':
        return $r('app.media.item_jindaiwupin')
      case 'item_anjian':
        return $r('app.media.item_anjian')
      case 'ic_dianziticket':
        return $r('app.media.ic_dianziticket')
      case 'ic_tiaojiantui':
        return $r('app.media.ic_tiaojiantui')
      case 'ic_buketui':
        return $r('app.media.ic_buketui')
      default:
        return $r('app.media.background')
    }
  }
}
