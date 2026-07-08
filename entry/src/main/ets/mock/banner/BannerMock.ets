import { BannerItem } from "../../model/entity/BannerItem"
import { EnableStatus } from "../../model/enums/EnableStatus"


export const bannerMockList: BannerItem[] = [
  {
    bannerId: 'banner_001',
    imageUrl: 'ZhouJieLunYanchu',
    relatedProjectId: 'proj_1001',
    enableStatus: EnableStatus.ENABLED,
    sortOrder: 1,
    startTime: '2026-05-01 00:00:00',
    endTime: '2026-07-01 00:00:00'
  },
  {
    bannerId: 'banner_002',
    imageUrl: 'aiyueZhiChengYanchu',
    relatedProjectId: 'proj_1002',
    enableStatus: EnableStatus.ENABLED,
    sortOrder: 2,
    startTime: '2026-05-01 00:00:00',
    endTime: '2026-07-01 00:00:00'
  },
  {
    bannerId: 'banner_003',
    imageUrl: 'YinyuejieYanchu',
    relatedProjectId: 'proj_1003',
    enableStatus: EnableStatus.ENABLED,
    sortOrder: 3,
    startTime: '2026-05-01 00:00:00',
    endTime: '2026-07-01 00:00:00'
  }
]
