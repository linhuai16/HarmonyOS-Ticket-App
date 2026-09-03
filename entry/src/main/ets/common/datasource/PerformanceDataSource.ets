export class PerformanceDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = []
  private data: T[] = []

  totalCount(): number {
    return this.data.length
  }

  getData(index: number): T {
    return this.data[index]
  }

  setData(items: T[]): void {
    this.data = items.slice()
    this.notifyDataReload()
  }

  appendData(items: T[]): void {
    items.forEach((item: T) => {
      this.data.push(item)
      this.notifyDataAdd(this.data.length - 1)
    })
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index: number = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  private notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded()
    })
  }

  private notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index)
    })
  }
}
