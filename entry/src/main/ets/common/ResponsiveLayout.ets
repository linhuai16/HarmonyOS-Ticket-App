export class ResponsiveLayout {
  static readonly SM_MAX: number = 599
  static readonly MD_MIN: number = 600
  static readonly LG_MIN: number = 840
  static readonly XL_MIN: number = 1440
  static readonly CONTENT_MAX_WIDTH: number = 1440
  static readonly COLLECTION_MAX_WIDTH: number = 1320
  static readonly WORKFLOW_MAX_WIDTH: number = 1200
  static readonly DETAIL_MAX_WIDTH: number = 1180
  static readonly READABLE_MAX_WIDTH: number = 880
  static readonly FORM_MAX_WIDTH: number = 640
  static readonly DIALOG_MAX_WIDTH: number = 640
  static readonly BANNER_MAX_WIDTH: number = 1180
  static readonly CARD_MIN_WIDTH: number = 152
  static readonly CARD_MAX_WIDTH: number = 280
  static readonly AI_RESULT_CARD_MIN_WIDTH: number = 340
  static readonly AI_RESULT_CARD_GAP: number = 16

  static getSizeClass(width: number): string {
    if (width >= ResponsiveLayout.XL_MIN) {
      return 'xl'
    }
    if (width >= ResponsiveLayout.LG_MIN) {
      return 'lg'
    }
    if (width >= ResponsiveLayout.MD_MIN) {
      return 'md'
    }
    return 'sm'
  }

  static isTabletBreakpoint(breakPoint: string): boolean {
    return breakPoint === 'md' || breakPoint === 'lg' || breakPoint === 'xl'
  }

  static isWideBreakpoint(breakPoint: string): boolean {
    return breakPoint === 'lg' || breakPoint === 'xl'
  }

  static isMediumWidth(width: number): boolean {
    return width >= ResponsiveLayout.MD_MIN
  }

  static isWideWidth(width: number): boolean {
    return width >= ResponsiveLayout.LG_MIN
  }

  static useSideNavigation(windowWidth: number): boolean {
    return ResponsiveLayout.isWideWidth(windowWidth)
  }

  static isLargeTabletWidth(contentWidth: number): boolean {
    return contentWidth >= 1040
  }

  static getPageHorizontalPadding(width: number): number {
    const sizeClass: string = ResponsiveLayout.getSizeClass(width)
    if (sizeClass === 'xl') {
      return 40
    }
    if (sizeClass === 'lg') {
      return 28
    }
    if (sizeClass === 'md') {
      return 20
    }
    return 12
  }

  static getNavigationWidth(windowWidth: number): number {
    return windowWidth >= ResponsiveLayout.XL_MIN ? 120 : 96
  }

  static getResponsiveGridColumnCount(contentWidth: number, minimumCardWidth: number,
                                      maximumColumns: number = 4, gap: number = 16): number {
    if (contentWidth <= 0) {
      return 1
    }
    const columnCount: number = Math.max(1, Math.floor((contentWidth + gap) / (minimumCardWidth + gap)))
    return Math.min(maximumColumns, columnCount)
  }

  static getTabletGridColumnCount(contentWidth: number): number {
    return ResponsiveLayout.getResponsiveGridColumnCount(contentWidth, 232, 4, 18)
  }

  static getTabletTopSearchWidth(contentWidth: number, breakPoint: string): number {
    const wide: boolean = ResponsiveLayout.isWideBreakpoint(breakPoint)
    const minimumWidth: number = wide ? 420 : 320
    const maximumWidth: number = wide ? 600 : 480
    return Math.min(maximumWidth, Math.max(minimumWidth, contentWidth * 0.44))
  }

  static getTabletSidePaneWidth(contentWidth: number): number {
    return Math.min(320, Math.max(232, contentWidth * 0.22))
  }

  static getBannerHeight(contentWidth: number): number {
    const availableWidth: number = Math.max(0,
      contentWidth - ResponsiveLayout.getPageHorizontalPadding(contentWidth) * 2)
    const bannerWidth: number = Math.min(ResponsiveLayout.BANNER_MAX_WIDTH, availableWidth)
    return Math.min(320, Math.max(132, bannerWidth / 2.8))
  }

  static getGridTemplate(columnCount: number): string {
    if (columnCount >= 6) {
      return '1fr 1fr 1fr 1fr 1fr 1fr'
    }
    if (columnCount === 5) {
      return '1fr 1fr 1fr 1fr 1fr'
    }
    if (columnCount === 4) {
      return '1fr 1fr 1fr 1fr'
    }
    if (columnCount === 3) {
      return '1fr 1fr 1fr'
    }
    if (columnCount === 2) {
      return '1fr 1fr'
    }
    return '1fr'
  }
}
