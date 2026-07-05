import {
  WantListPageVO,
  WantPerformanceItemVO
} from '../model/vo/want/WantListPageVO'

import { WantRepository } from '../repository/WantRepository'

/**
     想看列表
    取消想看
    重新加载列表
    点击想看卡片进入演出详情页
 */
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

  loadPage(userId: string): void {
    this.isLoading = true
    this.errorMessage = ''

    this.userId = userId

    const pageVO: WantListPageVO = this.wantRepository.getWantList(userId)
    this.items = pageVO.items

    this.isLoading = false
  }

  refresh(): void {
    if (this.userId.length === 0) {
      return
    }

    this.loadPage(this.userId)
  }

  cancelWant(projectId: string): boolean {
    this.errorMessage = ''

    if (this.userId.length === 0) {
      this.errorMessage = '用户信息异常，无法取消想看'
      return false
    }

    const success: boolean = this.wantRepository.cancelWant(this.userId, projectId)

    if (!success) {
      this.errorMessage = '取消想看失败'
      return false
    }

    this.loadPage(this.userId)
    return true
  }

  addWant(projectId: string): boolean {
    const success: boolean = this.wantRepository.addWant(this.userId, projectId)

    if (!success) {
      this.errorMessage = '添加想看失败'
      return false
    }

    this.loadPage(this.userId)
    return true
  }

  hasItems(): boolean {
    return this.items.length > 0
  }

  buildDetailJumpParams(item: WantPerformanceItemVO): WantDetailJumpParams {
    const params: WantDetailJumpParams = {
      projectId: item.projectId,
      sessionId: item.sessionId
    }

    return params
  }

  clearError(): void {
    this.errorMessage = ''
  }
}