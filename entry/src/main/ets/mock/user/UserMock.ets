import { User } from '../../model/entity/User'
import { UserStatus } from '../../model/enums/UserStatus'

export const userMockList: User[] = [
  {
    userId: 'user_001',
    phone: '18888888888',
    nickname: '测试用户01',
    avatarUrl: '/common/images/avatar/default_female.png',
    userStatus: UserStatus.NORMAL
  },
  {
    userId: 'user_002',
    phone: '13600008888',
    nickname: '测试用户02',
    avatarUrl: '/common/images/avatar/default_male.png',
    userStatus: UserStatus.NORMAL
  }
]

export const currentUserIdMock: string = 'user_001'
