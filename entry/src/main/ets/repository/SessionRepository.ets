import { PerformanceSession } from '../model/entity/PerformanceSession'
import { TicketSku } from '../model/entity/TicketSku'
import { Venue } from '../model/entity/Venue'
import { PerformanceDataUtil } from '../utils/PerformanceDataUtil'

export class SessionRepository {
  /**
   * 获取项目下所有可展示场次。
   */
  getProjectSessions(projectId: string): PerformanceSession[] {
    return PerformanceDataUtil.findVisibleSessionsByProjectId(projectId)
  }

  /**
   * 获取指定城市下的默认场次。
   *
   * 规则：
   * 1. 优先返回当前城市的场次；
   * 2. 城市名统一去掉“市”，避免北京 / 北京市不一致；
   * 3. 如果当前城市没有场次，则返回项目下第一个可展示场次。
   */
  getDefaultSessionByCity(projectId: string, cityName: string): PerformanceSession | undefined {
    const sessions: PerformanceSession[] = this.getProjectSessions(projectId)
    const normalizedCityName: string = PerformanceDataUtil.normalizeCityName(cityName)

    const citySession: PerformanceSession | undefined = sessions.find((item: PerformanceSession) => {
      return PerformanceDataUtil.normalizeCityName(item.cityName) === normalizedCityName
    })

    if (citySession !== undefined) {
      return citySession
    }

    return sessions.length > 0 ? sessions[0] : undefined
  }

  /**
   * 获取场次详情。
   */
  getSessionDetail(sessionId: string): PerformanceSession | undefined {
    return PerformanceDataUtil.findVisibleSession(sessionId)
  }

  /**
   * 根据场次获取场馆。
   */
  getVenueBySession(sessionId: string): Venue | undefined {
    const session: PerformanceSession | undefined = this.getSessionDetail(sessionId)

    if (session === undefined) {
      return undefined
    }

    return PerformanceDataUtil.findVenue(session.venueId)
  }

  /**
   * 根据场次获取票档。
   */
  getTicketSkusBySession(sessionId: string): TicketSku[] {
    return PerformanceDataUtil.getTicketSkusBySessionId(sessionId)
  }

  /**
   * 判断当前场次是否存在可售票档。
   */
  hasAvailableSku(sessionId: string): boolean {
    return PerformanceDataUtil.hasAvailableSku(sessionId)
  }
}
