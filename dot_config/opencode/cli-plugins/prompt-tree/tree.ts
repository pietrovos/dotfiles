import type { SessionMessageInfo } from "@opencode/client"

export type Node = {
  ref: string
  sessionID: string
  root: string
  parent?: string
  question: string
  messageID?: string
  responseIDs: string[]
  response: string
  pending: boolean
  error?: string
  created: number
}

export type State = {
  nodes: Record<string, Node>
  collapsed: string[]
}

export type Paste = { quote: string; source?: string }

export function plain(text: string) {
  return text.normalize("NFC")
    .replace(/\x1b\[[0-9;]*m/g, "")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/(?:\*\*|__|`{1,3})/g, "")
    .replace(/^\s*(?:#{1,6}\s+|>\s?)/gm, "")
    .replace(/\s+/g, " ")
    .trim()
}

export function matches(nodes: Node[], quote: string) {
  const needle = plain(quote)
  if (needle.length < 3) return []
  return nodes.filter(node => plain(node.response).includes(needle))
}

export function resolveSource(nodes: Node[], current: Node, input: string, pastes: Paste[] = []) {
  const reference = input.trimStart().match(/^(?:@|\[)(r[a-f0-9]{6}|msg_[A-Za-z0-9_]+)(?:\]|\b)\s*/)
  if (reference) {
    const source = nodes.find(n => n.ref === reference[1] || n.responseIDs.includes(reference[1]))
    if (!source) throw new Error(`Unknown response ID: ${reference[1]}`)
    const question = input.trimStart().slice(reference[0].length).trim()
    if (!question) throw new Error("Add a question after the response ID.")
    return { source, question, candidates: [] as Node[] }
  }
  // A pasted quote is evidence of its source, not evidence of the active node.
  // Ignore pastes the learner has since removed from the draft.
  const active = pastes.filter(p => plain(input).includes(plain(p.quote)))
  const quoted = input.split("\n").filter(line => /^\s*>/.test(line)).map(line => line.replace(/^\s*>\s?/, "")).join("\n")
  const evidence = active.length ? active : quoted.trim() ? [{ quote: quoted }] : []
  const candidates = evidence.map(paste => {
    const found = matches(nodes.filter(n => n.root === current.root), paste.quote)
    return paste.source ? found.filter(n => n.ref === paste.source) : found
  }).filter(found => found.length)
  if (!candidates.length) return { source: current, question: input, candidates: [] as Node[] }
  const shared = candidates[0].filter(node => candidates.every(found => found.some(n => n.ref === node.ref)))
  if (!shared.length) throw new Error("The pasted passages come from different responses. Ask about one source at a time, or specify @response-ID.")
  return { source: shared.length === 1 ? shared[0] : undefined, question: input, candidates: shared }
}

export function turn(messages: SessionMessageInfo[], messageID: string, ref?: string) {
  const exact = messages.findIndex(m => m.id === messageID && m.type === "user")
  // Native forks remap message IDs, but preserve admission metadata. Only the
  // stable node reference may reconcile that remap; never guess by prompt text.
  const remapped = exact < 0 && ref ? messages.flatMap((m, index) => {
    const metadata = m.metadata?.promptTree
    return m.type === "user" && metadata && typeof metadata === "object" && !Array.isArray(metadata) && metadata.ref === ref ? [index] : []
  }) : []
  const start = exact >= 0 ? exact : remapped.length === 1 ? remapped[0] : -1
  if (start < 0) throw new Error("The original prompt is missing from this session; refusing to use a different context.")
  const next = messages.findIndex((m, index) => index > start && m.type === "user")
  const own = messages.slice(start + 1, next < 0 ? undefined : next)
  const responses = own.filter(m => m.type === "assistant")
  return {
    messageID: messages[start].id,
    responseIDs: responses.map(m => m.id),
    response: responses.flatMap(m => m.content.flatMap(c => c.type === "text" ? [c.text] : [])).join("\n\n"),
    // A native fork includes messages before this boundary, never a later prompt.
    before: next < 0 ? undefined : messages[next].id,
  }
}

export function rows(nodes: Node[], collapsed: string[], root?: string) {
  const result: { node: Node; depth: number; children: boolean }[] = []
  const seen = new Set<string>()
  function visit(node: Node, depth: number) {
    if (seen.has(node.ref)) return
    seen.add(node.ref)
    const children = nodes.filter(n => n.parent === node.ref).sort((a, b) => a.created - b.created)
    result.push({ node, depth, children: children.length > 0 })
    if (!collapsed.includes(node.ref)) children.forEach(child => visit(child, depth + 1))
  }
  nodes.filter(n => root ? n.ref === root : !n.parent).sort((a, b) => a.created - b.created).forEach(n => visit(n, 0))
  return result
}
