export class DateTimeUtil {
  static now(): string {
    return DateTimeUtil.formatTime(new Date())
  }

  static addMinutes(time: string, minutes: number): string {
    const date: Date = new Date(DateTimeUtil.toTimeMillis(time) + minutes * 60 * 1000)
    return DateTimeUtil.formatTime(date)
  }

  static formatTime(date: Date): string {
    const year: number = date.getFullYear()
    const month: string = DateTimeUtil.pad(date.getMonth() + 1)
    const day: string = DateTimeUtil.pad(date.getDate())
    const hour: string = DateTimeUtil.pad(date.getHours())
    const minute: string = DateTimeUtil.pad(date.getMinutes())
    const second: string = DateTimeUtil.pad(date.getSeconds())
    return `${year}-${month}-${day} ${hour}:${minute}:${second}`
  }

  static toTimeMillis(time: string | undefined): number {
    if (time === undefined || time.length === 0) {
      return 0
    }
    return new Date(time.replace(' ', 'T')).getTime()
  }

  private static pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`
  }
}
