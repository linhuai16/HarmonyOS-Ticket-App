import {
  WantListPageVO,
  WantPerformanceItemVO
} from '../model/vo/want/WantListPageVO'
import { WantRepository } from '../repository/WantRepository'

export interface WantDetailJumpParams {
  projectId: string
  sessionId: string
}

export class WantViewModel {
  items: WantPerformanceItemVO[] = []
  userId: string = ''
  isLoading: boolean = false
  errorMessage: string = ''

  private wantRepository: WantRepository = new WantRepository()

  async loadPage(userId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    this.userId = userId

    try {
      const pageVO: WantListPageVO = await this.wantRepository.getWantList(userId)
      this.items = pageVO.items
      this.isLoading = false
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '想看列表加载失败'
      this.isLoading = false
    }
  }

  async refresh(): Promise<void> {
    if (this.userId.length === 0) {
      return
    }
    await this.loadPage(this.userId)
  }

  async cancelWant(projectId: string): Promise<boolean> {
    try {
      const success: boolean = await this.wantRepository.cancelWant(this.userId, projectId)
      if (!success) {
        this.errorMessage = '取消想看失败'
        return false
      }
      await this.loadPage(this.userId)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '取消想看失败'
      return false
    }
  }

  async addWant(projectId: string): Promise<boolean> {
    try {
      const success: boolean = await this.wantRepository.addWant(this.userId, projectId)
      if (!success) {
        this.errorMessage = '添加想看失败'
        return false
      }
      await this.loadPage(this.userId)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '添加想看失败'
      return false
    }
  }

  buildDetailJumpParams(item: WantPerformanceItemVO): WantDetailJumpParams {
    return {
      projectId: item.projectId,
      sessionId: item.sessionId
    }
  }

  clearError(): void {
    this.errorMessage = ''
  }
}
