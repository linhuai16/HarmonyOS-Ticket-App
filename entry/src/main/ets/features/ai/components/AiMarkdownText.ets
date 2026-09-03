enum AiMarkdownBlockType {
  PARAGRAPH = 'PARAGRAPH',
  HEADING = 'HEADING',
  UNORDERED_LIST = 'UNORDERED_LIST',
  ORDERED_LIST = 'ORDERED_LIST',
  QUOTE = 'QUOTE',
  CODE_BLOCK = 'CODE_BLOCK'
}

class AiMarkdownInline {
  text: string = ''
  bold: boolean = false
  italic: boolean = false
  code: boolean = false

  constructor(text: string, bold: boolean = false, italic: boolean = false, code: boolean = false) {
    this.text = text
    this.bold = bold
    this.italic = italic
    this.code = code
  }
}

class AiMarkdownBlock {
  id: string = ''
  type: AiMarkdownBlockType = AiMarkdownBlockType.PARAGRAPH
  text: string = ''
  level: number = 0
  marker: string = ''
  inlines: AiMarkdownInline[] = []

  constructor(id: string, type: AiMarkdownBlockType, text: string, level: number = 0, marker: string = '') {
    this.id = id
    this.type = type
    this.text = text
    this.level = level
    this.marker = marker
    this.inlines = type === AiMarkdownBlockType.CODE_BLOCK ? [] : AiMarkdownParser.parseInline(text)
  }
}

class AiMarkdownParser {
  static parse(source: string): AiMarkdownBlock[] {
    if (source.length === 0) return []
    try {
      return AiMarkdownParser.parseBlocks(source)
    } catch (_error) {
      return [new AiMarkdownBlock('fallback', AiMarkdownBlockType.PARAGRAPH, source)]
    }
  }

  static parseInline(source: string): AiMarkdownInline[] {
    if (source.length === 0) return []
    const values: AiMarkdownInline[] = []
    let cursor: number = 0
    let plainStart: number = 0
    while (cursor < source.length) {
      let marker: string = ''
      if (source.startsWith('**', cursor)) marker = '**'
      else if (source.startsWith('`', cursor)) marker = '`'
      else if (source.startsWith('*', cursor)) marker = '*'
      if (marker.length === 0) {
        cursor++
        continue
      }
      const close: number = source.indexOf(marker, cursor + marker.length)
      if (close < cursor + marker.length) {
        cursor += marker.length
        continue
      }
      if (cursor > plainStart) values.push(new AiMarkdownInline(source.substring(plainStart, cursor)))
      const content: string = source.substring(cursor + marker.length, close)
      values.push(new AiMarkdownInline(content, marker === '**', marker === '*', marker === '`'))
      cursor = close + marker.length
      plainStart = cursor
    }
    if (plainStart < source.length) values.push(new AiMarkdownInline(source.substring(plainStart)))
    if (values.length === 0) values.push(new AiMarkdownInline(source))
    return values
  }

  private static parseBlocks(source: string): AiMarkdownBlock[] {
    const lines: string[] = source.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n')
    const blocks: AiMarkdownBlock[] = []
    const paragraph: string[] = []
    const code: string[] = []
    let inCode: boolean = false
    let blockIndex: number = 0
    const flushParagraph = (): void => {
      if (paragraph.length === 0) return
      const text: string = paragraph.join('\n')
      blocks.push(new AiMarkdownBlock('paragraph_' + String(blockIndex++), AiMarkdownBlockType.PARAGRAPH, text))
      paragraph.length = 0
    }
    const flushCode = (): void => {
      blocks.push(new AiMarkdownBlock('code_' + String(blockIndex++), AiMarkdownBlockType.CODE_BLOCK, code.join('\n')))
      code.length = 0
    }
    for (const line of lines) {
      if (line.trim().startsWith('```')) {
        if (inCode) {
          flushCode()
          inCode = false
        } else {
          flushParagraph()
          inCode = true
        }
        continue
      }
      if (inCode) {
        code.push(line)
        continue
      }
      if (line.trim().length === 0) {
        flushParagraph()
        continue
      }
      const heading = /^(#{1,3})\s+(.+)$/.exec(line)
      if (heading !== null) {
        flushParagraph()
        blocks.push(new AiMarkdownBlock('heading_' + String(blockIndex++), AiMarkdownBlockType.HEADING,
          heading[2], heading[1].length))
        continue
      }
      const unordered = /^\s*[-*]\s+(.+)$/.exec(line)
      if (unordered !== null) {
        flushParagraph()
        blocks.push(new AiMarkdownBlock('unordered_' + String(blockIndex++), AiMarkdownBlockType.UNORDERED_LIST,
          unordered[1], 0, '•'))
        continue
      }
      const ordered = /^\s*(\d+)\.\s+(.+)$/.exec(line)
      if (ordered !== null) {
        flushParagraph()
        blocks.push(new AiMarkdownBlock('ordered_' + String(blockIndex++), AiMarkdownBlockType.ORDERED_LIST,
          ordered[2], 0, ordered[1] + '.'))
        continue
      }
      const quote = /^\s*>\s?(.*)$/.exec(line)
      if (quote !== null) {
        flushParagraph()
        blocks.push(new AiMarkdownBlock('quote_' + String(blockIndex++), AiMarkdownBlockType.QUOTE, quote[1]))
        continue
      }
      paragraph.push(line)
    }
    flushParagraph()
    if (inCode || code.length > 0) flushCode()
    return blocks
  }
}

@Component
export struct AiMarkdownText {
  @Prop content: string = ''
  @Prop tablet: boolean = false

  build() {
    Column() {
      ForEach(AiMarkdownParser.parse(this.content), (block: AiMarkdownBlock) => {
        if (block.type === AiMarkdownBlockType.HEADING) {
          this.InlineBlock(block, this.headingSize(block.level), this.headingLineHeight(block.level),
            FontWeight.Bold, 10, 5)
        } else if (block.type === AiMarkdownBlockType.UNORDERED_LIST ||
          block.type === AiMarkdownBlockType.ORDERED_LIST) {
          this.ListBlock(block)
        } else if (block.type === AiMarkdownBlockType.QUOTE) {
          this.QuoteBlock(block)
        } else if (block.type === AiMarkdownBlockType.CODE_BLOCK) {
          this.CodeBlock(block)
        } else {
          this.InlineBlock(block, this.tablet ? 16 : 15, this.tablet ? 25 : 23,
            FontWeight.Normal, 0, 9)
        }
      }, (block: AiMarkdownBlock) => block.id)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private InlineBlock(block: AiMarkdownBlock, size: number, height: number, weight: FontWeight,
                      top: number, bottom: number) {
    Text() {
      ForEach(block.inlines, (inline: AiMarkdownInline, index: number) => {
        Span(inline.text)
          .fontWeight(inline.bold ? FontWeight.Bold : weight)
          .fontStyle(inline.italic ? FontStyle.Italic : FontStyle.Normal)
          .fontFamily(inline.code ? 'monospace' : '')
          .fontColor(inline.code ? '#A13B36' : '#222222')
      }, (_inline: AiMarkdownInline, index: number) => String(index))
    }
    .fontSize(size)
    .fontColor('#222222')
    .lineHeight(height)
    .width('100%')
    .margin({ top: top, bottom: bottom })
  }

  @Builder
  private ListBlock(block: AiMarkdownBlock) {
    Row() {
      Text(block.marker)
        .fontSize(this.tablet ? 16 : 15)
        .fontColor('#555555')
        .width(block.marker.length > 1 ? 28 : 20)
        .lineHeight(this.tablet ? 25 : 23)
      Column() {
        this.InlineBlock(block, this.tablet ? 16 : 15, this.tablet ? 25 : 23,
          FontWeight.Normal, 0, 0)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: 6, right: 2 })
    .margin({ bottom: 6 })
  }

  @Builder
  private QuoteBlock(block: AiMarkdownBlock) {
    Row() {
      Column()
        .width(3)
        .height('100%')
        .constraintSize({ minHeight: 28 })
        .backgroundColor('#C7D7EA')
        .borderRadius(2)
      Column() {
        this.InlineBlock(block, this.tablet ? 16 : 15, this.tablet ? 25 : 23,
          FontWeight.Normal, 0, 0)
      }
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 7, right: 10, bottom: 7 })
    .margin({ bottom: 9 })
    .backgroundColor('#F7F9FC')
    .borderRadius(6)
  }

  @Builder
  private CodeBlock(block: AiMarkdownBlock) {
    Scroll() {
      Text(block.text)
        .fontSize(this.tablet ? 14 : 13)
        .fontFamily('monospace')
        .fontColor('#30343B')
        .lineHeight(this.tablet ? 22 : 20)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .backgroundColor('#F2F3F5')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  private headingSize(level: number): number {
    if (level === 1) return this.tablet ? 22 : 20
    if (level === 2) return this.tablet ? 20 : 18
    return this.tablet ? 18 : 17
  }

  private headingLineHeight(level: number): number {
    return this.headingSize(level) + 7
  }
}
