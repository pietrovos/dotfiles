import { atom, read, update } from 'claude-code'
import type { Color, EngineInterface, PromptDecoration, Register } from 'claude-code'

// RAM in use (total minus available), shown at the end of the hint line.
const ram = atom({ plugin: 'my-highlights', key: 'ram' } as const, '')

async function refreshRam($: EngineInterface) {
  const info = await $.fs.read('/proc/meminfo')
  const kb = (name: string) => Number(new RegExp(`^${name}:\\s+(\\d+)`, 'm').exec(info)?.[1] ?? 0)
  const total = kb('MemTotal')
  const used = total - kb('MemAvailable')
  if (!total) return
  const text = `RAM ${(used / 1048576).toFixed(1)}/${Math.round(total / 1048576)} GB`
  await update($, ram, () => text)
}

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

const BORDER = '#ff5c5c'
const FILL = '#2a1414'
const TEXT: Style = { color: '#ff5c5c' }
const NAME: Style = { color: '#ffffff' }
const CARET: Style = { color: '#d47a7a' }
// Blank cells between the border and the text on each side.
const PAD_X = 1
// Border cells and padding on each side, plus a spare column.
const BOX_CHROME = 2 + 2 * PAD_X + 1

type Cell = { ch: string; style: Style }

// The prefix and message as styled cells, wrapped at spaces into rows of at
// most `max` cells (a longer word is cut).
function boxRows(text: string, max: number): Cell[][] {
  const cells: Cell[] = [
    { ch: '❯', style: CARET },
    { ch: ' ', style: TEXT },
    ...[...'pietrovos:'].map(ch => ({ ch, style: NAME })),
    { ch: ' ', style: TEXT },
  ]
  const marks = spans(text)
  let i = 0
  for (const ch of text) {
    const mark = marks.find(m => i >= m.start && i < m.end)
    cells.push({ ch, style: mark ? mark.style : TEXT })
    i += ch.length
  }

  const limit = Math.max(10, max)
  const rows: Cell[][] = []
  let row: Cell[] = []
  for (const cell of cells) {
    if (cell.ch === '\n') {
      rows.push(row)
      row = []
      continue
    }
    row.push(cell)
    if (row.length > limit) {
      const space = row.map(c => c.ch).lastIndexOf(' ')
      const cut = space > 0 ? space : limit
      rows.push(row.slice(0, cut))
      row = row.slice(space > 0 ? cut + 1 : cut)
    }
  }
  rows.push(row)
  return rows
}

// Consecutive cells of one style as one run of text.
function groupRuns(cells: Cell[]): { text: string; style: Style }[] {
  const runs: { text: string; style: Style }[] = []
  for (const cell of cells) {
    const last = runs[runs.length - 1]
    if (last && last.style === cell.style) last.text += cell.ch
    else runs.push({ text: cell.ch, style: cell.style })
  }
  return runs
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await refreshRam($)
    $.clock.every(5000, () => void refreshRam($))
    return next(e)
  })

  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const text = await read($, ram)
    if (!text) return next(e)
    // The engine puts its own separator before the tail.
    return next({ ...e, props: { ...e.props, tail: ` ${text}` } })
  })
  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    const text = codeBare(e.props.text)
    return text === e.props.text ? next(e) : next({ ...e, props: { ...e.props, text } })
  })

  on('prompt.edit', async ($, e, next) => {
    const r = await next(e)
    const mine: PromptDecoration[] = spans(r.text).map(s => ({ start: s.start, end: s.end, ...s.style }))
    return { ...r, decorations: [...(r.decorations ?? []), ...mine] }
  })

  on('ui.render', { component: 'UserMessage' }, ($, e, next) => {
    const kind = e.props.origin.kind
    if (kind !== 'composer' && kind !== 'bridge') return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const rows = boxRows(e.props.text, (e.viewport?.columns ?? 80) - BOX_CHROME)
    const width = Math.max(...rows.map(row => row.length))
    const run = (cells: Cell[]) => groupRuns(cells).map(r => (
      <Text color={r.style.color} bold={r.style.bold} underline={r.style.underline}>{r.text}</Text>
    ))

    const blank = (
      <Text wrap="truncate-end">
        <Text color={BORDER}>▕</Text>
        <Text backgroundColor={FILL}>{' '.repeat(width + 2 * PAD_X)}</Text>
        <Text color={BORDER}>▏</Text>
      </Text>
    )

    // Drawn by hand: a Box border leaves its cells unfilled, so the background
    // stopped short of the line. Eighth-block edges sit flush with the fill.
    return (
      <Box flexDirection="column" marginTop={1} alignSelf="flex-start">
        <Text color={BORDER} wrap="truncate-end">{' ' + '▁'.repeat(width + 2 * PAD_X) + ' '}</Text>
        {blank}
        {rows.map(row => (
          <Text wrap="truncate-end">
            <Text color={BORDER}>▕</Text>
            <Text backgroundColor={FILL}>{' '.repeat(PAD_X)}{run(row)}{' '.repeat(width - row.length + PAD_X)}</Text>
            <Text color={BORDER}>▏</Text>
          </Text>
        ))}
        {blank}
        <Text color={BORDER} wrap="truncate-end">{' ' + '▔'.repeat(width + 2 * PAD_X) + ' '}</Text>
      </Box>
    )
  })
}
