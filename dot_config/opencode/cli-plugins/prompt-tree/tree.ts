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

/** One prompt in a native session and the responses it produced. */
export type Turn = {
  index: number
  messageID: string
  question: string
  ref?: string
  responseIDs: string[]
  response: string
  /** The next prompt. A native fork before it holds this turn's history and nothing later. */
  before?: string
}

export function plain(text: string) {
  return text.normalize("NFC")
    .replace(/\x1b\[[0-9;]*m/g, "")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/(?:\*\*|__|`{1,3})/g, "")
    .replace(/^\s*(?:#{1,6}\s+|>\s?|[-*+•]\s+|\d+\.\s+)/gm, "")
    .replace(/\s+/g, " ")
    .trim()
}

export function treeRef(message: SessionMessageInfo) {
  const metadata = message.type === "user" ? message.metadata?.promptTree : undefined
  return metadata && typeof metadata === "object" && !Array.isArray(metadata) && typeof metadata.ref === "string" ? metadata.ref : undefined
}

export function turns(messages: SessionMessageInfo[]): Turn[] {
  const starts = messages.flatMap((m, index) => m.type === "user" ? [index] : [])
  return starts.map((start, i) => {
    const user = messages[start] as Extract<SessionMessageInfo, { type: "user" }>
    const responses = messages.slice(start + 1, starts[i + 1]).flatMap(m => m.type === "assistant" ? [m] : [])
    return {
      index: start, messageID: user.id, question: user.text, ref: treeRef(user),
      responseIDs: responses.map(m => m.id),
      response: responses.flatMap(m => m.content.flatMap(c => c.type === "text" ? [c.text] : [])).join("\n\n"),
      before: starts[i + 1] === undefined ? undefined : messages[starts[i + 1]].id,
    }
  })
}

export function turn(messages: SessionMessageInfo[], messageID: string, ref?: string) {
  const all = turns(messages)
  // Native forks remap message IDs, but preserve admission metadata. Only the
  // stable node reference may reconcile that remap; never guess by prompt text.
  const exact = all.filter(t => t.messageID === messageID)
  const remapped = exact.length || !ref ? [] : all.filter(t => t.ref === ref)
  const found = exact.length ? exact : remapped.length === 1 ? remapped : []
  if (!found.length) throw new Error("The original prompt is missing from this session; refusing to use a different context.")
  return found[0]
}

/** Turns whose responses contain every quote. Several quotes from different responses are refused. */
export function sources(messages: SessionMessageInfo[], quotes: string[]) {
  const needles = quotes.map(plain).filter(q => q.length >= 3)
  if (!needles.length) return []
  const all = turns(messages).filter(t => t.response)
  // Ignore passages that aren't from a response, such as text from elsewhere.
  const found = needles.map(needle => all.filter(t => plain(t.response).includes(needle))).filter(list => list.length)
  if (!found.length) return []
  const shared = found[0].filter(t => found.every(list => list.includes(t)))
  if (!shared.length) throw new Error("The quoted passages come from different responses. Ask about one at a time.")
  return shared
}

/** Typed `> ` lines in a draft, used like a paste. */
export function quoted(input: string) {
  return input.split("\n").filter(line => /^\s*>/.test(line)).map(line => line.replace(/^\s*>\s?/, "")).join("\n").trim()
}

/** A leading [rXXXXXX], @rXXXXXX, or [msg_…] names the source explicitly. */
export function explicit(input: string) {
  const match = input.trimStart().match(/^(?:@|\[)(r[a-f0-9]{6}|msg_[A-Za-z0-9_]+)(?:\]|\b)\s*/)
  if (!match) return
  const question = input.trimStart().slice(match[0].length).trim()
  if (!question) throw new Error("Add a question after the response ID.")
  return { id: match[1], question }
}

/** The tree node a turn in this session already belongs to, if any. */
export function owner(nodes: Node[], sessionID: string, t: Turn) {
  return (t.ref ? nodes.find(n => n.ref === t.ref) : undefined) ?? nodes.find(n => n.sessionID === sessionID && n.messageID === t.messageID)
}

/** The deepest node at or before a turn: what that point of the conversation descends from. */
export function nodeAt(nodes: Node[], sessionID: string, all: Turn[], index = Infinity) {
  for (const t of [...all].reverse()) if (t.index <= index) {
    const node = owner(nodes, sessionID, t)
    if (node) return node
  }
}

/**
 * Makes a native turn a node so a branch can hang under it. Its parent is the
 * nearest earlier node in the same conversation; later nodes of this session
 * that hung from that parent now hang from it, since their history includes it.
 */
export function adopt(nodes: Node[], sessionID: string, messages: SessionMessageInfo[], t: Turn, ref: string, created: number) {
  const existing = owner(nodes, sessionID, t)
  if (existing) return { node: existing, moved: [] as Node[] }
  const all = turns(messages)
  const parent = nodeAt(nodes, sessionID, all, t.index - 1)
  const node: Node = { ref, sessionID, root: parent?.root ?? ref, parent: parent?.ref, question: t.question,
    messageID: t.messageID, responseIDs: t.responseIDs, response: t.response, pending: false, created }
  const later = new Set(all.filter(x => x.index > t.index).flatMap(x => owner(nodes, sessionID, x)?.ref ?? []))
  const lifted = nodes.filter(n => later.has(n.ref) && n.parent === parent?.ref)
  const moved: Node[] = lifted.map(n => ({ ...n, parent: ref }))
  // Former roots now sit under this node, so their trees join its tree.
  const rerooted = new Set(lifted.filter(n => !n.parent).map(n => n.ref))
  for (const n of nodes) if (rerooted.has(n.root)) {
    const entry = moved.find(m => m.ref === n.ref)
    if (entry) entry.root = node.root
    else moved.push({ ...n, root: node.root })
  }
  return { node, moved }
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

export function label(node: Pick<Node, "question">) {
  const line = node.question.split("\n").filter(line => line.trim() && !line.trimStart().startsWith(">"))[0]?.trim() || "New prompt"
  return line.length > 65 ? line.slice(0, 64) + "…" : line
}
