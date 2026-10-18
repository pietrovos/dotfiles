import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/context"
import type { SessionMessageInfo } from "@opencode/client"
import type { KeyEvent, PasteEvent, ScrollBoxRenderable, TextareaRenderable } from "@opentui/core"
import { For, Show, createEffect, createMemo, createSignal } from "solid-js"
import { matches, resolveSource, rows, turn, type Node, type Paste, type State } from "./tree"

export default Plugin.define({
  id: "pietrovos.prompt-tree",
  setup(context) {
    const [state, write] = context.storage.store<State>("tree-v1", { initial: { nodes: {}, collapsed: [] } })
    const [submitting, setSubmitting] = createSignal(false)
    const [mode, setMode] = createSignal("normal")
    const [dialog, setDialog] = createSignal(false)
    const pastes = new Map<string, Paste[]>()
    const watching = new Set<string>()
    const controller = new AbortController()
    const cleanups: (() => void)[] = []
    const nodes = () => Object.values(state.nodes)
    const current = () => {
      const route = context.ui.router.current()
      return route.type === "session" ? nodes().find(n => n.sessionID === route.sessionID) : undefined
    }
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
      })
      return result
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

    async function record(sessionID: string, question: string, parent?: Node) {
      const ref = `r${crypto.randomUUID().replaceAll("-", "").slice(0, 6)}`
      if (state.nodes[ref]) throw new Error("Response ID collision; please try again.")
      const node: Node = { ref, sessionID, root: parent?.root ?? ref, parent: parent?.ref, question,
        responseIDs: [], response: "", pending: false, created: Date.now() }
      // The native session is the durable conversation; this is just its tree index.
      const session = await context.client.session.get({ sessionID })
      await context.client.session.update({ sessionID, title: label(node), metadata: {
        ...session.metadata, promptTree: { ref, root: node.root, parent: parent?.ref ?? null },
      } })
      await write(draft => {
        draft.nodes[ref] = node
        if (parent) draft.collapsed = draft.collapsed.filter(item => item !== parent.ref)
      })
      return node
    }

    async function open(node: Node) {
      // Another client could have appended to this native session. In that case,
      // materialize the stored checkpoint instead of displaying or inheriting its future.
      const checkpoint = node.messageID ? turn(await messages(node.sessionID), node.messageID, node.ref) : undefined
      if (checkpoint?.before) {
        const snapshot = await context.client.session.fork({ sessionID: node.sessionID, before: checkpoint.before })
        await context.client.session.update({ sessionID: snapshot.id, title: label(node) })
        const remapped = turn(await messages(snapshot.id), node.messageID!, node.ref)
        await write(draft => {
          draft.nodes[node.ref].sessionID = snapshot.id
          draft.nodes[node.ref].messageID = remapped.messageID
          draft.nodes[node.ref].responseIDs = [...new Set([...draft.nodes[node.ref].responseIDs, ...remapped.responseIDs])]
        })
        await context.data.session.sync(snapshot.id)
        context.ui.router.navigate({ type: "session", sessionID: snapshot.id })
        return
      }
      if (checkpoint && checkpoint.messageID !== node.messageID) {
        await write(draft => {
          draft.nodes[node.ref].messageID = checkpoint.messageID
          draft.nodes[node.ref].responseIDs = [...new Set([...draft.nodes[node.ref].responseIDs, ...checkpoint.responseIDs])]
        })
      }
      await context.data.session.sync(node.sessionID)
      context.ui.router.navigate({ type: "session", sessionID: node.sessionID })
    }

    async function admit(node: Node, question: string) {
      await write(draft => {
        draft.nodes[node.ref].question = question
        draft.nodes[node.ref].pending = true
        delete draft.nodes[node.ref].error
      })
      const admitted = await context.client.session.prompt({ sessionID: node.sessionID, text: question,
        metadata: { promptTree: { ref: node.ref, source: node.parent ?? null } } }).catch(async error => {
        await write(draft => {
          draft.nodes[node.ref].pending = false
          draft.nodes[node.ref].error = error instanceof Error ? error.message : String(error)
        })
        throw error
      })
      await write(draft => { draft.nodes[node.ref].messageID = admitted.id })
      await context.client.session.update({ sessionID: node.sessionID, title: label({ ...node, question }) })
      watch(node.ref)
      await context.data.session.sync(node.sessionID)
      context.ui.router.navigate({ type: "session", sessionID: node.sessionID })
    }

    async function newRoot(question = "") {
      if (submitting()) return
      setSubmitting(true)
      try {
        const selected = context.ui.model.current()
        const route = context.ui.router.current()
        const origin = route.type === "session" ? context.data.session.get(route.sessionID) : undefined
        const session = await context.client.session.create({
          location: origin?.location ?? context.location ?? context.data.location.default(),
          agent: origin?.agent,
          model: selected ? { providerID: selected.providerID, id: selected.modelID, variant: selected.variant } : origin?.model,
        })
        const node = await record(session.id, question)
        if (question) await admit(node, question)
        if (!question) await open(node)
      } catch (error) { fail(error) }
      finally { setSubmitting(false) }
    }

    async function submit(input: string, evidence: Paste[]) {
      const active = current()
      if (!active || submitting()) return false
      const editor = context.renderer.currentFocusedEditor
      setSubmitting(true)
      try {
        const resolved = resolveSource(nodes(), active, input, evidence)
        const selected = resolved.source ?? await (async () => {
          setDialog(true)
          try {
            return await context.ui.dialog.select({
              title: "Which response did you quote?", options: resolved.candidates.map(node => ({
                title: `[${node.ref}] ${label(node)}`, value: node,
              })),
            })
          } finally { setDialog(false) }
        })()
        if (!selected) return
        if (!selected.messageID && selected.error) {
          // An admission may succeed on the server even if its HTTP response was
          // lost. Reconcile by metadata before allowing a retry, never double-send.
          const existing = (await messages(selected.sessionID)).find(message => {
            const metadata = message.metadata?.promptTree
            return message.type === "user" && metadata && typeof metadata === "object" && !Array.isArray(metadata) && metadata.ref === selected.ref
          })
          if (existing) {
            await write(draft => { draft.nodes[selected.ref].messageID = existing.id; draft.nodes[selected.ref].pending = true })
            watch(selected.ref)
            await open(state.nodes[selected.ref])
            return
          }
        }
        if (selected.pending || context.data.session.status(selected.sessionID) === "running") {
          throw new Error(`@${selected.ref} is still responding. Your question is kept; submit it when the response finishes.`)
        }
        if (selected.messageID && !selected.responseIDs.length) {
          await refresh(selected.ref)
          if (!state.nodes[selected.ref].responseIDs.length) throw new Error(`@${selected.ref} has no response to branch from yet.`)
        }
        const node = !selected.messageID ? selected : await (async () => {
          const checkpoint = turn(await messages(selected.sessionID), selected.messageID!, selected.ref)
          const fork = await context.client.session.fork({ sessionID: selected.sessionID, before: checkpoint.before })
          return record(fork.id, resolved.question, selected)
        })()
        await admit(node, resolved.question)
        if (editor && !editor.isDestroyed && editor.plainText === input) editor.editBuffer.setText("")
        pastes.delete(active.sessionID)
      } catch (error) { fail(error) }
      finally { setSubmitting(false) }
    }

    const onPaste = (event: PasteEvent) => {
      const active = current(), editor = context.renderer.currentFocusedEditor
      if (!active || !editor || mode() !== "normal" || !promptEditor(context)) return
      const quote = new TextDecoder().decode(event.bytes)
      const found = matches(nodes().filter(n => n.root === active.root), quote)
      if (!found.length) return
      pastes.set(active.sessionID, [...(pastes.get(active.sessionID) ?? []), { quote, source: found.length === 1 ? found[0].ref : undefined }])
    }
    context.renderer.keyInput.on("paste", onPaste)
    cleanups.push(() => context.renderer.keyInput.off("paste", onPaste))

    const toggle = async (ref: string) => write(draft => {
      draft.collapsed = draft.collapsed.includes(ref) ? draft.collapsed.filter(item => item !== ref) : [...draft.collapsed, ref]
    })

    function Tree(props: { sessionID?: string; dialog?: boolean }) {
      const active = () => nodes().find(n => n.sessionID === props.sessionID) ?? current()
      const visible = createMemo(() => rows(nodes(), state.collapsed, props.dialog ? undefined : active()?.root))
      const [cursor, setCursor] = createSignal(active()?.ref ?? visible()[0]?.node.ref)
      let viewport: ScrollBoxRenderable | undefined
      createEffect(() => {
        const ref = cursor()
        if (props.dialog && ref) queueMicrotask(() => viewport?.scrollChildIntoView(`prompt-tree-dialog-${ref}`))
      })
      const move = (delta: number) => {
        const index = Math.max(0, visible().findIndex(row => row.node.ref === cursor()))
        setCursor(visible()[Math.max(0, Math.min(visible().length - 1, index + delta))]?.node.ref)
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
        const child = visible().find(row => row.node.parent === node.ref)
        if (child) setCursor(child.node.ref)
      }
      if (props.dialog) context.keymap.layer(() => ({
        mode: "global", priority: 200,
        commands: [
          { bind: "j", run: () => move(1) }, { bind: "down", run: () => move(1) },
          { bind: "k", run: () => move(-1) }, { bind: "up", run: () => move(-1) },
          { bind: "h", run: left }, { bind: "left", run: left },
          { bind: "l", run: right }, { bind: "right", run: right },
          { bind: "return", run: () => { const node = selected(); if (node) { context.ui.dialog.clear(); void open(node).catch(fail) } } },
          { bind: "n", run: () => { context.ui.dialog.clear(); void newRoot() } },
        ],
      }))
      return <box flexDirection="column" gap={0} padding={props.dialog ? 1 : 0}
        border={props.dialog === true} borderColor={context.theme.border.base}
        backgroundColor={props.dialog ? "#" + context.theme.background.raised.max.toInts().slice(0, 3).map(value => value.toString(16).padStart(2, "0")).join("") : undefined}>
        <Show when={!props.dialog}><text fg={context.theme.text.muted}>Prompts</text></Show>
        <scrollbox ref={viewport} height={props.dialog ? Math.min(visible().length, Math.max(3, context.renderer.height - 12)) : visible().length} scrollY>
        <For each={visible()}>{row => <box id={`prompt-tree-${props.dialog ? "dialog" : "sidebar"}-${row.node.ref}`} flexDirection="row"
          backgroundColor={(props.dialog ? cursor() : active()?.ref) === row.node.ref ? context.theme.background.raised.base : undefined}
          onMouseDown={() => { if (props.dialog) context.ui.dialog.clear(); void open(row.node).catch(fail) }}>
          <text width={row.depth * 2 + 2} fg={context.theme.text.muted} onMouseDown={event => { event.stopPropagation(); if (row.children) void toggle(row.node.ref) }}>
            {"  ".repeat(row.depth)}{row.children ? state.collapsed.includes(row.node.ref) ? "▸ " : "▾ " : "  "}
          </text>
          <text fg={row.node.ref === (props.dialog ? cursor() : active()?.ref) ? context.theme.text.action.primary.selected : context.theme.text.base} wrapMode="none">
            {row.node.ref} {row.node.pending ? "… " : row.node.error ? "! " : ""}{label(row.node)}
          </text>
        </box>}</For>
        </scrollbox>
        <Show when={props.dialog}><text fg={context.theme.text.muted}>{"\n"}j/k move · h/l fold · enter jump · n root · esc close</text></Show>
      </box>
    }

    // Decide before native key dispatch, using the live editor rather than a
    // cached keymap predicate. Opt-out must not preventDefault: slash commands,
    // dialogs, shell mode, and Shift+Enter belong to the host.
    const onKey = (event: KeyEvent) => {
      if (dialog() || event.name !== "return" || event.ctrl || event.meta || event.shift || event.option || event.eventType === "release") return
      const active = current(), focused = context.renderer.currentFocusedEditor
      if (!active || !focused || mode() !== "normal" || context.keymap.mode.current() !== "base" || !promptEditor(context)) return
      const editor = focused as TextareaRenderable
      const text = editor.plainText.trim()
      if (!text || text.startsWith("/") || editor.traits.capture?.includes("submit")) return
      event.preventDefault()
      event.stopPropagation()
      if (submitting()) return
      if (editor.extmarks.getAll().length) {
        fail(new Error("Tree prompts currently accept plain text only. Remove file/agent attachments before sending.")); return
      }
      void submit(editor.plainText, pastes.get(active.sessionID) ?? [])
    }
    context.renderer.keyInput.prependListener("keypress", onKey)
    cleanups.push(() => context.renderer.keyInput.off("keypress", onKey))
    context.keymap.layer(() => ({
      mode: "global",
      commands: [{
        id: "pietrovos.tree", title: "Prompt tree", group: "Session", palette: true,
        slash: { name: "tree", arguments: true },
        run: async input => {
          const argument = input?.trim() ?? ""
          if (argument === "new" || (!nodes().length && !argument)) { await newRoot(); return }
          const reference = argument.match(/^(?:@|\[)?(r[a-f0-9]{6})\]?$/)
          if (reference) {
            const node = nodes().find(n => n.ref === reference[1])
            if (!node) { fail(new Error(`Unknown response ID: ${argument}`)); return }
            await open(node).catch(fail); return
          }
          if (argument) { await newRoot(argument); return }
          context.ui.dialog.set({ size: "large" })
          setDialog(true)
          context.ui.dialog.show(() => <Tree dialog />, () => setDialog(false))
        },
      }],
    }))

    cleanups.push(context.ui.slot({ append: "sidebar.content", render: input =>
      <Show when={nodes().some(n => n.sessionID === input.sessionID)}><Tree sessionID={input.sessionID}/></Show>,
    }))
    cleanups.push(context.ui.slot({ append: "prompt.footer.status", render: input => {
      createEffect(() => setMode(input.mode))
      return <Show when={current()}>{(node: () => Node) => <text fg={context.theme.text.muted}> [{node().ref}]</text>}</Show>
    } }))
    cleanups.push(context.data.on("session.execution.succeeded", event => {
      const node = nodes().find(n => n.sessionID === event.data.sessionID)
      if (node?.messageID) void refresh(node.ref).catch(fail)
    }))
    cleanups.push(context.data.on("session.execution.failed", event => {
      const node = nodes().find(n => n.sessionID === event.data.sessionID)
      if (node?.messageID) void refresh(node.ref).catch(fail)
    }))
    cleanups.push(context.data.on("session.execution.interrupted", event => {
      const node = nodes().find(n => n.sessionID === event.data.sessionID)
      if (node?.messageID) void refresh(node.ref).catch(fail)
    }))
    createEffect(() => { nodes().filter(n => n.pending && n.messageID).forEach(node => watch(node.ref)) })
    return () => { controller.abort(); cleanups.forEach(cleanup => cleanup()) }
  },
})

function label(node: Node) {
  const line = node.question.split("\n").filter(line => line.trim() && !line.startsWith(">"))[0]?.trim() || "New prompt"
  return line.length > 65 ? line.slice(0, 64) + "…" : line
}

function promptEditor(context: Context) {
  const traits = context.renderer.currentFocusedEditor?.traits
  return traits && "owner" in traits && traits.owner === "opencode" && "role" in traits && traits.role === "prompt"
}
