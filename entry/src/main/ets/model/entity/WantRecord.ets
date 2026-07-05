/**
 * 想看记录
 * 注解：
 * 只记录用户与演出项目的想看关系，不保存演出标题、海报、场次、价格等展示快照。
 * 想看列表页需要的展示信息由 Repository 通过 projectId 重新组装到 VO。
 */
export interface WantRecord {
  /** 记录ID */
  wantId: string

  /** 用户ID */
  userId: string

  /** 演出项目ID */
  projectId: string

  /** 创建时间，用于想看列表排序 */
  createTime: string
}
