/**
 * V1.2 金额模型。
 * amountMinor 统一使用最小货币单位；CNY 时单位为“分”。
 */
export interface MoneyVO {
  amountMinor: number
  currency: string
}

export class MoneyUtil {
  static zero(currency: string = 'CNY'): MoneyVO {
    return { amountMinor: 0, currency: MoneyUtil.normalizeCurrency(currency) }
  }

  /** 兼容麦麦业务接口当前返回的 decimal 元金额，在 Repository 边界统一转为分。 */
  static fromMajor(value: number | string | undefined | null, currency: string = 'CNY'): MoneyVO {
    if (value === undefined || value === null) {
      return MoneyUtil.zero(currency)
    }
    const major: number = Number(value)
    if (major !== major) {
      return MoneyUtil.zero(currency)
    }
    return {
      amountMinor: Math.round(major * 100),
      currency: MoneyUtil.normalizeCurrency(currency)
    }
  }

  static fromMinor(value: number | string | undefined | null, currency: string = 'CNY'): MoneyVO {
    if (value === undefined || value === null) {
      return MoneyUtil.zero(currency)
    }
    const minor: number = Number(value)
    if (minor !== minor) {
      return MoneyUtil.zero(currency)
    }
    return {
      amountMinor: Math.round(minor),
      currency: MoneyUtil.normalizeCurrency(currency)
    }
  }

  static toMajor(money: MoneyVO): number {
    return money.amountMinor / 100
  }

  static format(money: MoneyVO): string {
    if (money.currency === 'CNY') {
      return '¥' + MoneyUtil.toMajor(money).toFixed(2)
    }
    return money.currency + ' ' + MoneyUtil.toMajor(money).toFixed(2)
  }

  private static normalizeCurrency(currency: string): string {
    const value: string = currency.trim().toUpperCase()
    return value.length === 0 ? 'CNY' : value
  }
}
