import { HomeBannerVO, HomeCategoryVO, HomeRecommendItemVO } from '../model/vo/home/HomePageVO'
import { CategoryPerformanceItemVO } from '../model/vo/performance/CategoryPageVO'
import { SearchResultItemVO } from '../model/vo/performance/SearchPageVO'

const HOME_PERSISTENT_CACHE_KEY: string = 'home_first_screen_cache'
const MEMORY_CACHE_TTL: number = 5 * 60 * 1000
const HOME_PERSISTENT_CACHE_TTL: number = 24 * 60 * 60 * 1000

PersistentStorage.persistProp(HOME_PERSISTENT_CACHE_KEY, '')

export class HomeCacheSnapshot {
  cityName: string = ''
  categories: HomeCategoryVO[] = []
  banners: HomeBannerVO[] = []
  recommendList: HomeRecommendItemVO[] = []
  hasMore: boolean = false
  offset: number = 0
  updatedAt: number = 0
}

export class CategoryCacheSnapshot {
  key: string = ''
  cityName: string = ''
  performanceList: CategoryPerformanceItemVO[] = []
  hasMore: boolean = false
  offset: number = 0
  updatedAt: number = 0
}

export class SearchCacheSnapshot {
  key: string = ''
  cityName: string = ''
  keyword: string = ''
  resultList: SearchResultItemVO[] = []
  hasMore: boolean = false
  offset: number = 0
  updatedAt: number = 0
}

export class PerformancePageCache {
  private static homeMemory: Map<string, HomeCacheSnapshot> = new Map<string, HomeCacheSnapshot>()
  private static categoryMemory: Map<string, CategoryCacheSnapshot> = new Map<string, CategoryCacheSnapshot>()
  private static searchMemory: Map<string, SearchCacheSnapshot> = new Map<string, SearchCacheSnapshot>()
  private static homePersistentCacheRead: boolean = false

  static getHome(cityName: string): HomeCacheSnapshot | undefined {
    const memory: HomeCacheSnapshot | undefined = PerformancePageCache.homeMemory.get(cityName)
    if (memory !== undefined && PerformancePageCache.isFresh(memory.updatedAt, MEMORY_CACHE_TTL)) {
      return PerformancePageCache.cloneHome(memory)
    }

    if (PerformancePageCache.homePersistentCacheRead) {
      return undefined
    }
    PerformancePageCache.homePersistentCacheRead = true
    const raw: string = AppStorage.get<string>(HOME_PERSISTENT_CACHE_KEY) ?? ''
    if (raw.length === 0) {
      return undefined
    }

    const snapshot: HomeCacheSnapshot | undefined = PerformancePageCache.parseHome(raw)
    if (snapshot === undefined) {
      return undefined
    }
    if (snapshot.cityName !== cityName || !PerformancePageCache.isFresh(snapshot.updatedAt, HOME_PERSISTENT_CACHE_TTL)) {
      return undefined
    }

    const cloned: HomeCacheSnapshot = PerformancePageCache.cloneHome(snapshot)
    PerformancePageCache.homeMemory.set(cityName, cloned)
    return PerformancePageCache.cloneHome(cloned)
  }

  static saveHomeMemory(snapshot: HomeCacheSnapshot): void {
    PerformancePageCache.homeMemory.set(snapshot.cityName, PerformancePageCache.cloneHome(snapshot))
  }

  static saveHomeFirstScreen(snapshot: HomeCacheSnapshot): void {
    const cloned: HomeCacheSnapshot = PerformancePageCache.cloneHome(snapshot)
    PerformancePageCache.homeMemory.set(snapshot.cityName, cloned)
    PerformancePageCache.homePersistentCacheRead = true
    AppStorage.setOrCreate(HOME_PERSISTENT_CACHE_KEY, JSON.stringify(cloned))
  }

  static getCategory(key: string): CategoryCacheSnapshot | undefined {
    const snapshot: CategoryCacheSnapshot | undefined = PerformancePageCache.categoryMemory.get(key)
    if (snapshot === undefined || !PerformancePageCache.isFresh(snapshot.updatedAt, MEMORY_CACHE_TTL)) {
      return undefined
    }
    return PerformancePageCache.cloneCategory(snapshot)
  }

  static saveCategory(snapshot: CategoryCacheSnapshot): void {
    PerformancePageCache.categoryMemory.set(snapshot.key, PerformancePageCache.cloneCategory(snapshot))
  }

  static getSearch(key: string): SearchCacheSnapshot | undefined {
    const snapshot: SearchCacheSnapshot | undefined = PerformancePageCache.searchMemory.get(key)
    if (snapshot === undefined || !PerformancePageCache.isFresh(snapshot.updatedAt, MEMORY_CACHE_TTL)) {
      return undefined
    }
    return PerformancePageCache.cloneSearch(snapshot)
  }

  static saveSearch(snapshot: SearchCacheSnapshot): void {
    PerformancePageCache.searchMemory.set(snapshot.key, PerformancePageCache.cloneSearch(snapshot))
  }

  private static parseHome(raw: string): HomeCacheSnapshot | undefined {
    try {
      const value: Record<string, Object> = JSON.parse(raw)
      const snapshot: HomeCacheSnapshot = new HomeCacheSnapshot()
      snapshot.cityName = value['cityName'] as string
      snapshot.categories = value['categories'] as HomeCategoryVO[]
      snapshot.banners = value['banners'] as HomeBannerVO[]
      snapshot.recommendList = value['recommendList'] as HomeRecommendItemVO[]
      snapshot.hasMore = value['hasMore'] as boolean
      snapshot.offset = value['offset'] as number
      snapshot.updatedAt = value['updatedAt'] as number
      if (snapshot.cityName === undefined || snapshot.categories === undefined || snapshot.banners === undefined ||
        snapshot.recommendList === undefined || snapshot.hasMore === undefined || snapshot.offset === undefined ||
        snapshot.updatedAt === undefined) {
        return undefined
      }
      return snapshot
    } catch (error) {
      return undefined
    }
  }

  private static isFresh(updatedAt: number, ttl: number): boolean {
    return updatedAt > 0 && Date.now() - updatedAt <= ttl
  }

  private static cloneHome(snapshot: HomeCacheSnapshot): HomeCacheSnapshot {
    const cloned: HomeCacheSnapshot = new HomeCacheSnapshot()
    cloned.cityName = snapshot.cityName
    cloned.categories = snapshot.categories.slice()
    cloned.banners = snapshot.banners.slice()
    cloned.recommendList = snapshot.recommendList.slice()
    cloned.hasMore = snapshot.hasMore
    cloned.offset = snapshot.offset
    cloned.updatedAt = snapshot.updatedAt
    return cloned
  }

  private static cloneCategory(snapshot: CategoryCacheSnapshot): CategoryCacheSnapshot {
    const cloned: CategoryCacheSnapshot = new CategoryCacheSnapshot()
    cloned.key = snapshot.key
    cloned.cityName = snapshot.cityName
    cloned.performanceList = snapshot.performanceList.slice()
    cloned.hasMore = snapshot.hasMore
    cloned.offset = snapshot.offset
    cloned.updatedAt = snapshot.updatedAt
    return cloned
  }

  private static cloneSearch(snapshot: SearchCacheSnapshot): SearchCacheSnapshot {
    const cloned: SearchCacheSnapshot = new SearchCacheSnapshot()
    cloned.key = snapshot.key
    cloned.cityName = snapshot.cityName
    cloned.keyword = snapshot.keyword
    cloned.resultList = snapshot.resultList.slice()
    cloned.hasMore = snapshot.hasMore
    cloned.offset = snapshot.offset
    cloned.updatedAt = snapshot.updatedAt
    return cloned
  }
}
