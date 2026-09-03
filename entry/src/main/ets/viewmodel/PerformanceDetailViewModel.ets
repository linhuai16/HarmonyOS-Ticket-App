import { PerformanceDetailVO, PerformanceSessionItemVO } from '../model/vo/performance/PerformanceDetailVO'
import { PerformanceRepository } from '../repository/PerformanceRepository'
import { WantRepository } from '../repository/WantRepository'
import { SessionStatus } from '../model/enums/SessionStatus'

export class PerformanceDetailViewModel {
  detailVO: PerformanceDetailVO | undefined = undefined

  projectId: string = ''
  selectedSessionId: string = ''
  userId: string = ''

  isLoading: boolean = false
  errorMessage: string = ''
  selectedSession: PerformanceSessionItemVO | undefined = undefined

  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private wantRepository: WantRepository = new WantRepository()

  async loadDetail(
    projectId: string,
    cityName: string,
    sessionId: string | undefined = undefined,
    userId: string = ''
  ): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''

    this.projectId = projectId
    this.userId = userId

    try {
      await this.refreshDetail(projectId, cityName, sessionId)
    } finally {
      this.isLoading = false
    }
  }

  async changeSession(sessionId: string, cityName: string = ''): Promise<void> {
    if (this.projectId.length === 0) {
      return
    }

    this.errorMessage = ''
    await this.refreshDetail(this.projectId, cityName, sessionId)
  }

  async toggleWant(): Promise<void> {
    if (this.detailVO === undefined || this.userId.length === 0) {
      return
    }

    if (this.detailVO.isWanted) {
      const success: boolean = await this.wantRepository.cancelWant(this.userId, this.projectId)

      if (success) {
        this.detailVO.isWanted = false
      }

      return
    }

    const success: boolean = await this.wantRepository.addWant(this.userId, this.projectId)

    if (success) {
      this.detailVO.isWanted = true
    }
  }

  canBuyCurrentSession(): boolean {
    const session: PerformanceSessionItemVO | undefined = this.selectedSession

    if (session === undefined) {
      return false
    }

    return session.sessionStatus === SessionStatus.ON_SALE ||
      session.sessionStatus === SessionStatus.PRESALE
  }

  async loadDetailByProject(projectId: string, cityName: string, userId: string = ''): Promise<void> {
    await this.loadDetail(projectId, cityName, undefined, userId)
  }

  getSelectedSessionId(): string {
    return this.selectedSessionId
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private async refreshDetail(projectId: string, cityName: string, sessionId: string | undefined): Promise<boolean> {
    try {
      const detail: PerformanceDetailVO | undefined = await this.performanceRepository.getPerformanceDetail(
        projectId,
        cityName,
        sessionId,
        this.userId
      )

      if (detail === undefined) {
        this.errorMessage = '演出详情不存在'
        return false
      }

      let selectedSession: PerformanceSessionItemVO | undefined = detail.sessions.find((item: PerformanceSessionItemVO) => {
        return item.sessionId === detail.selectedSessionId
      })

      if (selectedSession === undefined && detail.sessions.length > 0) {
        selectedSession = detail.sessions[0]
      }
      if (selectedSession === undefined) {
        this.errorMessage = '当前演出暂无可展示场次'
        return false
      }

      this.selectedSession = selectedSession
      this.selectedSessionId = selectedSession.sessionId
      this.detailVO = detail
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '演出详情加载失败'
      return false
    }
  }
}
