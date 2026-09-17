import type { Plugin } from "@opencode-ai/plugin"

type HyprClient = {
  address: string
  pid: number
  workspace: { id: number; name: string }
  grouped: string[]
}

async function output(command: string[]) {
  const process = Bun.spawn(command, { stdout: "pipe", stderr: "ignore" })
  const text = await new Response(process.stdout).text()
  await process.exited
  return text
}

async function windowForProcess() {
  let pid = process.pid

  for (let depth = 0; depth < 8; depth++) {
    const parent = Number.parseInt((await output(["ps", "-o", "ppid=", "-p", String(pid)])).trim(), 10)
    if (!Number.isInteger(parent) || parent <= 1) return

    pid = parent
    const clients = JSON.parse(await output(["hyprctl", "clients", "-j"])) as HyprClient[]
    const window = clients.find((client) => client.pid === pid)
    if (window) return window
  }
}

async function isFocused(window: HyprClient | undefined) {
  if (!window) return false
  const active = JSON.parse(await output(["hyprctl", "activewindow", "-j"])) as { address?: string }
  return active.address === window.address
}

async function notify(window: HyprClient | undefined, title: string, body?: string) {
  const command = [
    "notify-send",
    "--app-name=OpenCode",
    "--urgency=critical",
    "--expire-time=0",
    title,
  ]
  if (body) command.push(body)

  if (!window) {
    await output(command)
    return
  }

  // Omarchy invokes the default action when the notification card is clicked.
  const action = await output([...command.slice(0, -1), "--action=default=Focus", command.at(-1)!])
  if (action.trim() === "default") {
    await output(["hyprctl", "dispatch", `hl.dsp.focus({ window = \"address:${window.address}\" })`])

    const groupIndex = window.grouped.indexOf(window.address) + 1
    if (groupIndex > 0) {
      await output(["hyprctl", "dispatch", `hl.dsp.group.active({ index = ${groupIndex} })`])
    }

  }
}

export const CompletionNotification: Plugin = async ({ client }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle" && event.type !== "question.asked") return

    try {
      const result = await client.session.get({ path: { id: event.properties.sessionID } })
      if (!result.data || result.data.parentID) return

      const window = await windowForProcess()
      if (await isFocused(window)) return

      const workspace = window?.workspace.name || String(window?.workspace.id || "unknown")
      const tab = window && window.grouped.length > 1
        ? `, Group ${window.grouped.indexOf(window.address) + 1}/${window.grouped.length}`
        : ""

      if (event.type === "question.asked") {
        void notify(window, `Workspace ${workspace}${tab}`)
        return
      }

      void notify(window, "OpenCode finished", `Workspace ${workspace}${tab}`)
    } catch {
      // Notifications must never interrupt an OpenCode session.
    }
  },
})
