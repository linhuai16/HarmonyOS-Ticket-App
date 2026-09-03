export class HomeCategoryVO {
  categoryId: string = ''
  categoryName: string = ''
  iconUrl?: string
}

export class HomeBannerVO {
  bannerId: string = ''
  imageUrl: string = ''
  projectId: string = ''
}

export class HomeRecommendItemVO {
  projectId: string = ''
  sessionId: string = ''
  posterUrl: string = ''
  categoryName: string = ''
  title: string = ''
  cityName: string = ''
  venueName: string = ''
  startTime: string = ''
  minPrice?: number
}

export class HomePageVO {
  currentCityName: string = ''
  categories: HomeCategoryVO[] = []
  banners: HomeBannerVO[] = []
  recommendList: HomeRecommendItemVO[] = []
  hasMore: boolean = false
  limit: number = 0
  offset: number = 0
}
