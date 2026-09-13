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

export const CompletionNotification: Plugin = async ({ client }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle") return

    try {
      const result = await client.session.get({ path: { id: event.properties.sessionID } })
      if (!result.data || result.data.parentID) return

      const window = await windowForProcess()
      const workspace = window?.workspace.name || String(window?.workspace.id || "unknown")
      const tab = window && window.grouped.length > 1
        ? ` | Group tab ${window.grouped.indexOf(window.address) + 1}/${window.grouped.length}`
        : ""

      await output([
        "notify-send",
        "--app-name=OpenCode",
        "--expire-time=10000",
        "OpenCode finished",
        `Workspace ${workspace}${tab}`,
      ])
    } catch {
      // Notifications must never interrupt an OpenCode session.
    }
  },
})
