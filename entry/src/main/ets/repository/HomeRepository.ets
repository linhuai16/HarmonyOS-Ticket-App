import {
  HomePageVO,
  HomeCategoryVO,
  HomeBannerVO,
  HomeRecommendItemVO
} from '../model/vo/home/HomePageVO'

import { ApiClient, ApiQueryParam } from '../network/ApiClient'

interface ApiHomePageVO {
  banners?: ApiBannerItemVO[]
  categories?: ApiCategoryItemVO[]
  recommends?: ApiHomeRecommendItemVO[]
}

interface ApiBannerItemVO {
  bannerId?: number
  title?: string
  bannerTitle?: string
  imageUrl?: string
  targetProjectId?: number
  targetSessionId?: number
  sortOrder?: number
}

interface ApiCategoryItemVO {
  categoryId?: number
  categoryCode?: string
  categoryName?: string
  iconUrl?: string
  sortOrder?: number
}

interface ApiHomeRecommendItemVO {
  projectId?: number
  sessionId?: number
  categoryId?: number
  categoryName?: string
  title?: string
  posterUrl?: string
  cityName?: string
  venueName?: string
  startTime?: string
  minPrice?: number
  maxPrice?: number
}

const DEFAULT_LIMIT: number = 10

/**
 * 首页 Repository：已从 Mock 切换为 SpringBoot 接口。
 */
export class HomeRepository {
  async getHomeIndex(cityName: string, limit: number = DEFAULT_LIMIT, offset: number = 0): Promise<HomePageVO> {
    const data: ApiHomePageVO = await ApiClient.get<ApiHomePageVO>('/api/home/index', [
      new ApiQueryParam('cityName', cityName),
      new ApiQueryParam('limit', limit),
      new ApiQueryParam('offset', offset)
    ])

    const recommends: ApiHomeRecommendItemVO[] = data.recommends ?? []

    return {
      currentCityName: cityName,
      categories: this.buildHomeCategories(data.categories ?? []),
      banners: this.buildHomeBanners(data.banners ?? []),
      recommendList: this.buildRecommendList(recommends),
      hasMore: recommends.length >= limit
    }
  }

  private buildHomeCategories(list: ApiCategoryItemVO[]): HomeCategoryVO[] {
    return list.map((item: ApiCategoryItemVO): HomeCategoryVO => {
      return {
        categoryId: this.toId(item.categoryId),
        categoryName: item.categoryName ?? '',
        iconUrl: item.iconUrl
      }
    })
  }

  private buildHomeBanners(list: ApiBannerItemVO[]): HomeBannerVO[] {
    return list.map((item: ApiBannerItemVO): HomeBannerVO => {
      return {
        bannerId: this.toId(item.bannerId),
        imageUrl: item.imageUrl ?? '',
        projectId: this.toId(item.targetProjectId)
      }
    }).filter((item: HomeBannerVO) => item.projectId.length > 0)
  }

  private buildRecommendList(list: ApiHomeRecommendItemVO[]): HomeRecommendItemVO[] {
    return list.map((item: ApiHomeRecommendItemVO): HomeRecommendItemVO => {
      return {
        projectId: this.toId(item.projectId),
        sessionId: this.toId(item.sessionId),
        posterUrl: item.posterUrl ?? '',
        categoryName: item.categoryName ?? '',
        title: item.title ?? '',
        cityName: item.cityName ?? '',
        startTime: this.formatDateTime(item.startTime),
        minPrice: item.minPrice
      }
    })
  }

  private toId(value: number | string | undefined): string {
    if (value === undefined) {
      return ''
    }
    return String(value)
  }

  private formatDateTime(value: string | undefined): string {
    if (value === undefined) {
      return ''
    }
    return value.replace('T', ' ')
  }
}
