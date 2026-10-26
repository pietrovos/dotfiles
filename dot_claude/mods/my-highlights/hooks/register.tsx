import type { Color, PromptDecoration, Register } from 'claude-code'

type Style = { color: Color; bold?: boolean; underline?: boolean }

// Earlier patterns win where matches overlap.
const PATTERNS: { re: RegExp; style: Style }[] = [
  { re: /`[^`\n]+`/g, style: { color: 'warning' } },
  { re: /https?:\/\/[^\s)>\]]+/g, style: { color: 'ide', underline: true } },
  { re: /(?<![\w/])@[\w./~-]+/g, style: { color: 'claude', bold: true } },
  { re: /(?<![\w:/])(?:~|\.{1,2})?\/[\w.@~-]+(?:\/[\w.@~-]*)*(?::\d+)?/g, style: { color: 'suggestion' } },
]

type Span = { start: number; end: number; style: Style }

function spans(text: string): Span[] {
  const found: Span[] = []
  for (const { re, style } of PATTERNS) {
    for (const m of text.matchAll(re)) {
      const start = m.index ?? 0
      // Sentence punctuation after a path or URL is not part of it.
      const word = m[0].startsWith('`') ? m[0] : m[0].replace(/[.,;:!?]+$/, '')
      const end = start + word.length
      if (end <= start) continue
      if (found.some(s => start < s.end && end > s.start)) continue
      found.push({ start, end, style })
    }
  }
  return found.sort((a, b) => a.start - b.start)
}

// Fenced blocks, inline code, Markdown links and autolinks are left as written.
const MARKDOWN_KEEP = /```[\s\S]*?(?:```|$)|`[^`\n]*`|\[[^\]\n]*\]\([^)\n]*\)|<https?:[^>\n]*>/g

// Wraps bare paths, URLs and @mentions in backticks so the transcript draws
// them as inline code.
function codeBare(markdown: string): string {
  let out = ''
  let at = 0
  const wrap = (plain: string) => {
    let res = ''
    let i = 0
    for (const s of spans(plain)) {
      res += plain.slice(i, s.start) + '`' + plain.slice(s.start, s.end) + '`'
      i = s.end
    }
    return res + plain.slice(i)
  }
  for (const m of markdown.matchAll(MARKDOWN_KEEP)) {
    const start = m.index ?? 0
    out += wrap(markdown.slice(at, start)) + m[0]
    at = start + m[0].length
  }
  return out + wrap(markdown.slice(at))
}

export const register: Register = on => {
  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    const text = codeBare(e.props.text)
    return text === e.props.text ? next(e) : next({ ...e, props: { ...e.props, text } })
  })

  on('prompt.edit', async ($, e, next) => {
    const r = await next(e)
    // Typed text is red like sent prompts; highlights come later so they win.
    const base: PromptDecoration = { start: 0, end: r.text.length, color: '#ff5c5c' }
    const mine: PromptDecoration[] = [base, ...spans(r.text).map(s => ({ start: s.start, end: s.end, ...s.style }))]
    return { ...r, decorations: [...(r.decorations ?? []), ...mine] }
  })

  on('ui.render', { component: 'UserMessage' }, ($, e, next) => {
    const kind = e.props.origin.kind
    if (kind !== 'composer' && kind !== 'bridge') return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const text = e.props.text
    const parts: (string | ReturnType<typeof Text>)[] = []
    let at = 0
    for (const s of spans(text)) {
      if (s.start > at) parts.push(text.slice(at, s.start))
      parts.push(
        <Text color={s.style.color} bold={s.style.bold} underline={s.style.underline}>
          {text.slice(s.start, s.end)}
        </Text>,
      )
      at = s.end
    }
    if (at < text.length) parts.push(text.slice(at))

    return (
      // flex-start shrinks the box to the text instead of the full row.
      <Box key="message" hover={{ backgroundColor: "#3a1a1a" }} borderStyle="single" borderColor="#ff5c5c" backgroundColor="#2a1414" paddingX={1} marginTop={1} alignSelf="flex-start">
        <Text color="#ff5c5c"><Text color="#d47a7a">❯ </Text><Text color="#ffffff">pietrovos:</Text> {parts}</Text>
      </Box>
    )
  })
}
