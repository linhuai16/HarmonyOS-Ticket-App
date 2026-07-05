import { PerformanceDetailVO } from '../model/vo/performance/PerformanceDetailVO'
import { PerformanceSession } from '../model/entity/PerformanceSession'
import { PerformanceRepository } from '../repository/PerformanceRepository'
import { SessionRepository } from '../repository/SessionRepository'
import { WantRepository } from '../repository/WantRepository'
import { SessionStatus } from '../model/enums/SessionStatus'

export class PerformanceDetailViewModel {
  detailVO: PerformanceDetailVO | undefined = undefined

  projectId: string = ''
  selectedSessionId: string = ''
  userId: string = ''

  isLoading: boolean = false
  errorMessage: string = ''
  selectedSession: PerformanceSession | undefined = undefined

  private performanceRepository: PerformanceRepository = new PerformanceRepository()
  private sessionRepository: SessionRepository = new SessionRepository()
  private wantRepository: WantRepository = new WantRepository()

  loadDetail(projectId: string, sessionId: string, userId: string = ''): void {
    this.isLoading = true
    this.errorMessage = ''

    this.projectId = projectId
    this.userId = userId

    const success: boolean = this.refreshDetailBySession(projectId, sessionId)

    if (!success) {
      this.isLoading = false
      return
    }

    this.isLoading = false
  }

  changeSession(sessionId: string): void {
    if (this.projectId.length === 0) {
      return
    }

    this.errorMessage = ''
    this.refreshDetailBySession(this.projectId, sessionId)
  }

  toggleWant(): void {
    if (this.detailVO === undefined || this.userId.length === 0) {
      return
    }

    if (this.detailVO.isWanted) {
      const success: boolean = this.wantRepository.cancelWant(this.userId, this.projectId)

      if (success) {
        this.detailVO.isWanted = false
      }

      return
    }

    const success: boolean = this.wantRepository.addWant(this.userId, this.projectId)

    if (success) {
      this.detailVO.isWanted = true
    }
  }

  canBuyCurrentSession(): boolean {
    if (this.detailVO === undefined) {
      return false
    }

    const session: PerformanceSession | undefined =
      this.sessionRepository.getSessionDetail(this.detailVO.selectedSessionId)

    if (session === undefined) {
      return false
    }

    return session.sessionStatus === SessionStatus.ON_SALE ||
      session.sessionStatus === SessionStatus.PRESALE
  }

  loadDetailByProject(projectId: string, userId: string = ''): void {
    const sessions: PerformanceSession[] = this.sessionRepository.getProjectSessions(projectId)

    if (sessions.length === 0) {
      this.errorMessage = '该演出暂无可展示场次'
      return
    }

    this.loadDetail(projectId, sessions[0].sessionId, userId)
  }

  getSelectedSessionId(): string {
    return this.selectedSessionId
  }

  clearError(): void {
    this.errorMessage = ''
  }

  private refreshDetailBySession(projectId: string, sessionId: string): boolean {
    const session: PerformanceSession | undefined = this.sessionRepository.getSessionDetail(sessionId)

    if (session === undefined || session.projectId !== projectId) {
      this.errorMessage = '场次不存在'
      return false
    }

    const detail: PerformanceDetailVO | undefined = this.performanceRepository.getPerformanceDetail(
      projectId,
      sessionId,
      this.userId
    )

    if (detail === undefined) {
      this.errorMessage = '演出详情不存在'
      return false
    }

    detail.isWanted = this.wantRepository.isWanted(this.userId, projectId)
    this.selectedSession = session
    this.selectedSessionId = detail.selectedSessionId
    this.detailVO = detail
    return true
  }
}
