import { ApiClient } from '../network/ApiClient'

/**
 * 将后台已经清洗过的富文本包装成可由 ArkWeb 展示的完整 HTML 文档。
 * 数据库只保存 /media/** 相对地址；展示前根据当前成功连接的后端地址补全。
 */
export class RichTextHtmlUtil {
  static buildDataUrl(content: string | undefined | null): string {
    const safeContent: string = content?.trim() ?? ''
    const normalizedContent: string = RichTextHtmlUtil.normalizeLegacyText(safeContent)
    const resolvedContent: string = RichTextHtmlUtil.resolveMediaUrls(normalizedContent)
    const documentHtml: string = RichTextHtmlUtil.buildDocument(resolvedContent)
    return 'data:text/html;charset=utf-8,' + encodeURIComponent(documentHtml)
  }

  static estimateHeight(content: string | undefined | null): number {
    const html: string = content?.trim() ?? ''
    if (html.length === 0) {
      return 160
    }

    const text: string = html
      .replace(/<img\b[^>]*>/gi, '')
      .replace(/<video\b[^>]*>[\s\S]*?<\/video>/gi, '')
      .replace(/<source\b[^>]*>/gi, '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;|&#160;/gi, ' ')
      .replace(/&amp;/gi, '&')
      .replace(/\s+/g, ' ')
      .trim()

    const imageCount: number = (html.match(/<img\b/gi) ?? []).length
    const videoCount: number = (html.match(/<video\b/gi) ?? []).length
    const textRows: number = Math.max(2, Math.ceil(text.length / 20))
    const estimated: number = 70 + textRows * 24 + imageCount * 230 + videoCount * 260
    return Math.max(180, Math.min(3000, estimated))
  }


  private static normalizeLegacyText(content: string): string {
    if (content.length === 0 || content.includes('<')) {
      return content
    }
    const escaped: string = content
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
      .replace(/\r\n|\r|\n/g, '<br>')
    return '<p>' + escaped + '</p>'
  }

  private static resolveMediaUrls(content: string): string {
    if (content.length === 0) {
      return '<p class="empty">暂无演出详情</p>'
    }

    return content.replace(
      /(src\s*=\s*["'])(\/media\/[^"']+)(["'])/gi,
      (match: string, prefix: string, path: string, suffix: string): string => {
        const absoluteUrl: string = ApiClient.resolveMediaUrl(path)
        return prefix + RichTextHtmlUtil.escapeAttribute(absoluteUrl) + suffix
      }
    )
  }

  private static buildDocument(content: string): string {
    return '<!doctype html>' +
      '<html><head><meta charset="utf-8">' +
      '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">' +
      '<style>' +
      '*{box-sizing:border-box}' +
      'html,body{margin:0;padding:0;background:#fff;color:#555;font-family:sans-serif;}' +
      'body{padding:2px 0 12px;font-size:14px;line-height:1.7;word-break:break-word;overflow-wrap:anywhere;}' +
      'h2{margin:18px 0 10px;font-size:22px;line-height:1.4;color:#222;}' +
      'h3{margin:16px 0 8px;font-size:19px;line-height:1.45;color:#222;}' +
      'h4{margin:14px 0 8px;font-size:16px;line-height:1.5;color:#222;}' +
      'p{margin:8px 0;}' +
      'ul,ol{margin:10px 0;padding-left:24px;}' +
      'blockquote{margin:12px 0;padding:10px 12px;border-left:4px solid #f3aebb;background:#fff8fa;color:#666;}' +
      'a{color:#c1154a;text-decoration:underline;pointer-events:none;}' +
      'figure{margin:14px 0;}' +
      'figcaption{margin-top:6px;color:#777;font-size:12px;text-align:center;}' +
      'img,video{display:block;width:auto;max-width:100%;height:auto;margin:10px auto;border-radius:10px;background:#f2f4f7;}' +
      'video{width:100%;max-height:480px;}' +
      '.empty{color:#999;}' +
      '</style></head><body>' + content + '</body></html>'
  }

  private static escapeAttribute(value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
  }
}
