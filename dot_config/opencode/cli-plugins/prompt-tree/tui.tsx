import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/context"
import type { SessionMessageInfo } from "@opencode/client"
import type { KeyEvent, PasteEvent, ScrollBoxRenderable, Selection, TextareaRenderable } from "@opentui/core"
import { For, Show, createEffect, createMemo, createSignal, onCleanup } from "solid-js"
import { adopt, explicit, label, nodeAt, owner, plain, quoted, rows, sources, turn, turns, type Node, type State, type Turn } from "./tree"

type Armed = { quote: string; turns: Turn[] }
type Plan = { sessionID: string; input: string; question: string; candidates?: Turn[]; node?: Node }

export default Plugin.define({
  id: "pietrovos.prompt-tree",
  setup(context) {
    const [state, write] = context.storage.store<State>("tree-v1", { initial: { nodes: {}, collapsed: [] } })
    const [submitting, setSubmitting] = createSignal(false)
    const [mode, setMode] = createSignal("normal")
    const [dialog, setDialog] = createSignal(false)
    // Per session: a selected response passage, and a node jumped to before the session's end.
    const [armed, setArmed] = createSignal<Record<string, Armed>>({})
    const [focus, setFocus] = createSignal<Record<string, string>>({})
    const pastes = new Map<string, string[]>()
    const watching = new Set<string>()
    const controller = new AbortController()
    const cleanups: (() => void)[] = []
    const nodes = () => Object.values(state.nodes)
    const routed = () => {
      const route = context.ui.router.current()
      return route.type === "session" ? route.sessionID : undefined
    }
    const visible = (sessionID: string) => turns(context.data.session.message.list(sessionID))
    const current = (sessionID = routed()) => {
      if (!sessionID) return
      const focused = state.nodes[focus()[sessionID] ?? ""]
      return focused?.sessionID === sessionID ? focused : nodeAt(nodes(), sessionID, visible(sessionID))
    }
    const disarm = (sessionID: string) => setArmed(({ [sessionID]: _, ...rest }) => rest)
    const fail = (error: unknown) => context.ui.toast.show({
      title: "Prompt tree", message: error instanceof Error ? error.message : String(error), variant: "error", duration: 7000,
    })

    async function messages(sessionID: string) {
      const result: SessionMessageInfo[] = []
      let cursor: string | undefined
      do {
        const page = await context.client.message.list({ sessionID, limit: 100, ...(cursor ? { cursor } : { order: "asc" }) })
        result.push(...page.data)
        cursor = page.cursor.next ?? undefined
      } while (cursor)
      return result
    }

    async function refresh(ref: string) {
      const node = state.nodes[ref]
      if (!node?.messageID) return
      const result = turn(await messages(node.sessionID), node.messageID, node.ref)
      await write(draft => {
        const entry = draft.nodes[ref]
        if (!entry || entry.sessionID !== node.sessionID) return
        entry.response = result.response
        entry.messageID = result.messageID
        entry.responseIDs = [...new Set([...entry.responseIDs, ...result.responseIDs])]
        entry.pending = false
        delete entry.error
      })
    }

    // An admission can succeed on the server even when its HTTP response is
    // lost. Find it by metadata rather than sending the question twice.
    async function reconcile(ref: string) {
      const node = state.nodes[ref]
      if (!node || node.messageID) return !!node
      const found = turns(await messages(node.sessionID)).find(t => t.ref === ref)
      if (!found) return false
      await write(draft => {
        draft.nodes[ref].messageID = found.messageID
        draft.nodes[ref].pending = true
        delete draft.nodes[ref].error
      })
      watch(ref)
      return true
    }

    function watch(ref: string) {
      if (watching.has(ref)) return
      const node = state.nodes[ref]
      if (!node?.messageID) return
      watching.add(ref)
      void context.client.session.wait({ sessionID: node.sessionID }, { signal: controller.signal })
        .then(() => refresh(ref))
        .catch(async error => {
          if (controller.signal.aborted) return
          await write(draft => {
            if (!draft.nodes[ref]) return
            draft.nodes[ref].pending = false
            draft.nodes[ref].error = error instanceof Error ? error.message : String(error)
          })
          fail(error)
        }).finally(() => watching.delete(ref))
    }

    const fresh = () => {
      const ref = `r${crypto.randomUUID().replaceAll("-", "").slice(0, 6)}`
      if (state.nodes[ref]) throw new Error("Response ID collision; please try again.")
      return ref
    }

    async function record(sessionID: string, question: string, parent: Node) {
      const ref = fresh()
      const node: Node = { ref, sessionID, root: parent.root, parent: parent.ref, question,
        responseIDs: [], response: "", pending: false, created: Date.now() }
      // The native session is the durable conversation; this is just its tree index.
      const session = await context.client.session.get({ sessionID })
      await context.client.session.update({ sessionID, title: label(node), metadata: {
        ...session.metadata, promptTree: { ref, root: node.root, parent: parent.ref },
      } })
      await write(draft => {
        draft.nodes[ref] = node
        draft.collapsed = draft.collapsed.filter(item => item !== parent.ref)
      })
      return node
    }

    async function open(node: Node) {
      // Jumping never creates a session. If this node isn't the end of its
      // session, remember it, so the next question branches from it instead.
      const listed = await messages(node.sessionID), all = turns(listed)
      const at = node.messageID ? turn(listed, node.messageID, node.ref) : undefined
      if (at && at.messageID !== node.messageID) await write(draft => { draft.nodes[node.ref].messageID = at.messageID })
      const last = !at || at.index === all.at(-1)?.index
      setFocus(({ [node.sessionID]: _, ...rest }) => last ? rest : { ...rest, [node.sessionID]: node.ref })
      await context.data.session.sync(node.sessionID)
      context.ui.router.navigate({ type: "session", sessionID: node.sessionID })
    }

    async function admit(node: Node, question: string) {
      await write(draft => {
        draft.nodes[node.ref].pending = true
        delete draft.nodes[node.ref].error
      })
      const admitted = await context.client.session.prompt({ sessionID: node.sessionID, text: question,
        metadata: { promptTree: { ref: node.ref, source: node.parent ?? null } } }).catch(async error => {
        if (await reconcile(node.ref).catch(() => false) && state.nodes[node.ref].messageID) return undefined
        await write(draft => {
          draft.nodes[node.ref].pending = false
          draft.nodes[node.ref].error = error instanceof Error ? error.message : String(error)
        })
        throw error
      })
      if (admitted) await write(draft => { draft.nodes[node.ref].messageID = admitted.id })
      watch(node.ref)
      await context.data.session.sync(node.sessionID)
      context.ui.router.navigate({ type: "session", sessionID: node.sessionID })
    }

    // Forks the source turn's session at its response boundary: the new
    // session holds that turn's history and nothing after it.
    async function branch(plan: Plan) {
      if (submitting()) return
      const editor = context.renderer.currentFocusedEditor
      setSubmitting(true)
      try {
        let sessionID = plan.sessionID, parent = plan.node, source: Turn | undefined
        if (parent) {
          if (!parent.messageID && !await reconcile(parent.ref)) throw new Error(`[${parent.ref}] has no prompt to branch from.`)
          sessionID = parent.sessionID
          source = turn(await messages(sessionID), state.nodes[parent.ref].messageID!, parent.ref)
        } else {
          const candidates = plan.candidates ?? []
          const picked = candidates.length === 1 ? candidates[0] : await (async () => {
            setDialog(true)
            try {
              return await context.ui.dialog.select({
                title: "Which response are you asking about?", options: candidates.map(t => {
                  const known = owner(nodes(), sessionID, t)
                  return { title: `${known ? `[${known.ref}] ` : ""}${label(t)}`, value: t }
                }),
              })
            } finally { setDialog(false) }
          })()
          if (!picked) return
          const all = await messages(sessionID)
          source = turns(all).find(t => t.messageID === picked.messageID)
          if (!source) throw new Error("That response is no longer in this session.")
          const adopted = adopt(nodes(), sessionID, all, source, fresh(), Date.now())
          if (!state.nodes[adopted.node.ref]) await write(draft => {
            draft.nodes[adopted.node.ref] = adopted.node
            for (const moved of adopted.moved) draft.nodes[moved.ref] = moved
          })
          parent = state.nodes[adopted.node.ref]
        }
        if (!source.before && (parent.pending || context.data.session.status(sessionID) === "running")) {
          throw new Error(`[${parent.ref}] is still responding. Your question is kept; send it when the response finishes.`)
        }
        if (!source.responseIDs.length) throw new Error(`[${parent.ref}] has no response to branch from yet.`)
        const fork = await context.client.session.fork({ sessionID, before: source.before })
        const node = await record(fork.id, plan.question, parent)
        await admit(node, plan.question)
        if (editor && !editor.isDestroyed && editor.plainText === plan.input) editor.editBuffer.setText("")
        disarm(plan.sessionID)
        pastes.delete(plan.sessionID)
      } catch (error) { fail(error) }
      finally { setSubmitting(false) }
    }

    // A finished mouse selection inside a response arms a branch from it.
    const onSelection = (selection: Selection | null) => {
      const sessionID = routed(), text = selection?.getSelectedText() ?? ""
      if (!sessionID || dialog() || plain(text).length < 3) return
      try {
        const found = sources(context.data.session.message.list(sessionID), [text])
        if (found.length) setArmed(all => ({ ...all, [sessionID]: { quote: text, turns: found } }))
      } catch { /* A selection spanning several responses is not a question about one. */ }
    }
    context.renderer.on("selection", onSelection)
    cleanups.push(() => context.renderer.off("selection", onSelection))

    const onPaste = (event: PasteEvent) => {
      const sessionID = routed()
      if (!sessionID || mode() !== "normal" || !promptEditor(context)) return
      const quote = new TextDecoder().decode(event.bytes)
      if (sources(context.data.session.message.list(sessionID), [quote]).length) pastes.set(sessionID, [...(pastes.get(sessionID) ?? []), quote])
    }
    context.renderer.keyInput.on("paste", onPaste)
    cleanups.push(() => context.renderer.keyInput.off("paste", onPaste))

    // Decides, before native key dispatch, whether this Enter is a branch.
    // Anything else must not preventDefault: ordinary follow-ups, slash
    // commands, dialogs, shell mode, and Shift+Enter belong to the host.
    function plan(sessionID: string, input: string): Plan | undefined {
      const named = explicit(input)
      if (named) {
        const node = nodes().find(n => n.ref === named.id || n.responseIDs.includes(named.id) || n.messageID === named.id)
        if (!node) throw new Error(`Unknown response ID: ${named.id}`)
        return { sessionID, input, question: named.question, node }
      }
      const selected = armed()[sessionID]
      if (selected) {
        const included = plain(input).includes(plain(selected.quote))
        const question = included ? input : `${selected.quote.trim().split("\n").map(line => `> ${line}`).join("\n")}\n\n${input}`
        return { sessionID, input, question, candidates: selected.turns }
      }
      const evidence = [...(pastes.get(sessionID) ?? []).filter(q => plain(input).includes(plain(q))), quoted(input)].filter(Boolean)
      const found = evidence.length ? sources(context.data.session.message.list(sessionID), evidence) : []
      if (found.length) return { sessionID, input, question: input, candidates: found }
      const focused = state.nodes[focus()[sessionID] ?? ""]
      if (focused?.sessionID === sessionID) return { sessionID, input, question: input, node: focused }
    }

    const onKey = (event: KeyEvent) => {
      if (dialog() || event.eventType === "release") return
      const sessionID = routed()
      if (!sessionID) return
      if (event.name === "escape") { if (armed()[sessionID]) disarm(sessionID); return }
      if (event.name !== "return" || event.ctrl || event.meta || event.shift || event.option) return
      const focused = context.renderer.currentFocusedEditor
      if (!focused || mode() !== "normal" || context.keymap.mode.current() !== "base" || !promptEditor(context)) return
      const editor = focused as TextareaRenderable
      const text = editor.plainText.trim()
      if (!text || text.startsWith("/") || editor.traits.capture?.includes("submit")) return
      let next: Plan | undefined
      try { next = plan(sessionID, editor.plainText) } catch (error) {
        event.preventDefault(); event.stopPropagation(); fail(error); return
      }
      if (!next) return
      event.preventDefault()
      event.stopPropagation()
      if (editor.extmarks.getAll().length) {
        fail(new Error("Branch questions accept plain text only. Remove file/agent attachments before sending.")); return
      }
      void branch(next)
    }
    context.renderer.keyInput.prependListener("keypress", onKey)
    cleanups.push(() => context.renderer.keyInput.off("keypress", onKey))

    const toggle = async (ref: string) => write(draft => {
      draft.collapsed = draft.collapsed.includes(ref) ? draft.collapsed.filter(item => item !== ref) : [...draft.collapsed, ref]
    })

    function Tree(props: { sessionID?: string; dialog?: boolean }) {
      const active = () => current(props.sessionID ?? routed())
      const listed = createMemo(() => rows(nodes(), state.collapsed, props.dialog ? undefined : active()?.root))
      const [cursor, setCursor] = createSignal(active()?.ref ?? listed()[0]?.node.ref)
      const marked = () => props.dialog ? cursor() : active()?.ref
      let viewport: ScrollBoxRenderable | undefined
      if (props.dialog) onCleanup(() => setDialog(false))
      createEffect(() => {
        const ref = cursor()
        if (props.dialog && ref) queueMicrotask(() => viewport?.scrollChildIntoView(`prompt-tree-dialog-${ref}`))
      })
      const move = (delta: number) => {
        const index = Math.max(0, listed().findIndex(row => row.node.ref === cursor()))
        setCursor(listed()[Math.max(0, Math.min(listed().length - 1, index + delta))]?.node.ref)
      }
      const selected = () => state.nodes[cursor() ?? ""]
      const left = () => {
        const node = selected()
        if (!node) return
        if (nodes().some(n => n.parent === node.ref) && !state.collapsed.includes(node.ref)) { void toggle(node.ref); return }
        if (node.parent) setCursor(node.parent)
      }
      const right = () => {
        const node = selected()
        if (!node) return
        if (state.collapsed.includes(node.ref)) { void toggle(node.ref); return }
        const child = listed().find(row => row.node.parent === node.ref)
        if (child) setCursor(child.node.ref)
      }
      const jump = (node: Node) => { if (props.dialog) context.ui.dialog.clear(); void open(node).catch(fail) }
      if (props.dialog) context.keymap.layer(() => ({
        mode: "global", priority: 200, enabled: dialog(),
        commands: [
          { bind: "j", run: () => move(1) }, { bind: "down", run: () => move(1) },
          { bind: "k", run: () => move(-1) }, { bind: "up", run: () => move(-1) },
          { bind: "h", run: left }, { bind: "left", run: left },
          { bind: "l", run: right }, { bind: "right", run: right },
          { bind: "return", run: () => { const node = selected(); if (node) jump(node) } },
        ],
      }))
      return <box flexDirection="column" gap={0} padding={props.dialog ? 1 : 0}
        border={props.dialog === true} borderColor={context.theme.border.base}
        backgroundColor={props.dialog ? "#" + context.theme.background.raised.max.toInts().slice(0, 3).map(value => value.toString(16).padStart(2, "0")).join("") : undefined}>
        <Show when={!props.dialog}><text fg={context.theme.text.muted}>Prompts</text></Show>
        <scrollbox ref={viewport} height={props.dialog ? Math.min(listed().length, Math.max(3, context.renderer.height - 12)) : listed().length} scrollY>
        <For each={listed()}>{row => <box id={`prompt-tree-${props.dialog ? "dialog" : "sidebar"}-${row.node.ref}`} flexDirection="row"
          backgroundColor={props.dialog && marked() === row.node.ref ? context.theme.background.action.primary.focused : undefined}
          onMouseDown={() => jump(row.node)}>
          <text width={row.depth * 2 + 2} fg={context.theme.text.muted} onMouseDown={event => { event.stopPropagation(); if (row.children) void toggle(row.node.ref) }}>
            {"  ".repeat(row.depth)}{row.children ? state.collapsed.includes(row.node.ref) ? "▸ " : "▾ " : "  "}
          </text>
          <text fg={marked() === row.node.ref ? context.theme.text.action.primary.focused : context.theme.text.base} wrapMode="none">
            {row.node.ref} {row.node.pending ? "… " : row.node.error ? "! " : ""}{label(row.node)}
          </text>
        </box>}</For>
        </scrollbox>
        <Show when={props.dialog}><text fg={context.theme.text.muted}>{"\n"}j/k move · h/l fold · enter jump · esc close</text></Show>
      </box>
    }

    context.keymap.layer(() => ({
      mode: "global",
      commands: [{
        id: "pietrovos.tree", title: "Prompt tree", group: "Session", palette: true,
        slash: { name: "tree", arguments: true },
        run: async input => {
          const argument = input?.trim() ?? ""
          if (argument) {
            const reference = argument.match(/^(?:@|\[)?(r[a-f0-9]{6})\]?$/)
            const node = reference && nodes().find(n => n.ref === reference[1])
            if (!node) { fail(new Error(reference ? `Unknown response ID: ${argument}` : "Usage: /tree, or /tree r12ab34 to jump.")); return }
            await open(node).catch(fail); return
          }
          if (!nodes().length) { fail(new Error("No branches yet. Select part of a response, type your question, and press Enter.")); return }
          context.ui.dialog.set({ size: "large" })
          setDialog(true)
          context.ui.dialog.show(() => <Tree dialog />, () => setDialog(false))
        },
      }],
    }))

    cleanups.push(context.ui.slot({ append: "sidebar.content", render: input =>
      <Show when={current(input.sessionID)}><Tree sessionID={input.sessionID}/></Show>,
    }))
    cleanups.push(context.ui.slot({ append: "session.composer.top", render: input =>
      <Show when={armed()[input.sessionID]}>{(selected: () => Armed) =>
        <text fg={context.theme.text.muted} wrapMode="none" onMouseDown={() => disarm(input.sessionID)}>
          ↳ asking about “{plain(selected().quote).slice(0, 60)}{plain(selected().quote).length > 60 ? "…" : ""}” in a new branch · esc cancels
        </text>}
      </Show>,
    }))
    cleanups.push(context.ui.slot({ append: "prompt.footer.status", render: input => {
      createEffect(() => setMode(input.mode))
      return <Show when={current(input.sessionID)}>{(node: () => Node) =>
        <text fg={context.theme.text.muted}> [{node().ref}]{focus()[input.sessionID ?? ""] === node().ref ? " · next question branches here" : ""}</text>}
      </Show>
    } }))
    for (const name of ["session.execution.succeeded", "session.execution.failed", "session.execution.interrupted"] as const) {
      cleanups.push(context.data.on(name, event => {
        for (const node of nodes()) if (node.sessionID === event.data.sessionID && node.pending && node.messageID) void refresh(node.ref).catch(fail)
      }))
    }
    createEffect(() => { nodes().filter(n => n.pending && n.messageID).forEach(node => watch(node.ref)) })
    return () => { controller.abort(); cleanups.forEach(cleanup => cleanup()) }
  },
})

function promptEditor(context: Context) {
  const traits = context.renderer.currentFocusedEditor?.traits
  return traits && "owner" in traits && traits.owner === "opencode" && "role" in traits && traits.role === "prompt"
}
