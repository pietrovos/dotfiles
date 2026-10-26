import { type ChildProcess, execFile, spawn } from "node:child_process"
import { Plugin } from "@opencode/plugin/tui"

type HyprClient = {
  address: string
  pid: number
  workspace: { id: number; name: string }
  grouped: string[]
  visible: boolean
}

function output(command: string[]) {
  return new Promise<string>((resolve) => {
    execFile(command[0], command.slice(1), (error, stdout) => resolve(error ? "" : stdout))
  })
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

// True when the window is the shown tab of its group on the focused workspace.
async function isOnScreen(window: HyprClient | undefined) {
  if (!window?.visible) return false
  const active = JSON.parse(await output(["hyprctl", "activeworkspace", "-j"])) as { id?: number }
  return active.id === window.workspace.id
}

// Shows a completion that closes itself once its window is on screen, and resolves with
// the action taken (empty when it was closed without a click).
function dismissedOnView(command: string[], window: HyprClient) {
  return new Promise<string>((resolve) => {
    const notification = spawn(command[0], ["--print-id", ...command.slice(1)], {
      stdio: ["ignore", "pipe", "ignore"],
    })
    let stdout = ""
    let watcher: ChildProcess | undefined
    notification.stdout.on("data", (chunk) => {
      stdout += chunk
      const id = stdout.split("\n")[0]
      if (!watcher && stdout.includes("\n") && /^\d+$/.test(id)) {
        watcher = spawn(`${process.env.HOME}/.local/bin/notification-dismiss-on-view`, [id, window.address], { stdio: "ignore" })
        watcher.on("error", () => {})
      }
    })
    notification.on("error", () => resolve(""))
    notification.on("close", () => {
      watcher?.kill()
      resolve(stdout.split("\n").slice(1).join("\n"))
    })
  })
}

async function notify(window: HyprClient | undefined, title: string, body?: string, isQuestion = false) {
  const command = [
    "notify-send",
    `--app-name=${isQuestion ? "OpenCode Question" : "OpenCode"}`,
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
  const withAction = [...command.slice(0, -1), "--action=default=Focus", command.at(-1)!]
  const action = isQuestion ? await output(withAction) : await dismissedOnView(withAction, window)
  if (action.trim() === "default") {
    await output(["hyprctl", "dispatch", `hl.dsp.focus({ window = \"address:${window.address}\" })`])

    const groupIndex = window.grouped.indexOf(window.address) + 1
    if (groupIndex > 0) {
      await output(["hyprctl", "dispatch", `hl.dsp.group.active({ index = ${groupIndex} })`])
    }
  }
}

function describe(window: HyprClient | undefined) {
  const workspace = window?.workspace.name || String(window?.workspace.id || "unknown")
  const tab = window && window.grouped.length > 1
    ? `, Group ${window.grouped.indexOf(window.address) + 1}/${window.grouped.length}`
    : ""
  return `Workspace ${workspace}${tab}`
}

export default Plugin.define({
  id: "pietrovos.completion-notification",
  setup(context) {
    // Every TUI shares the background service's event stream, so only react to
    // sessions this window shows or was showing when they started running.
    const running = new Set<string>()
    const shown = (sessionID: string) => {
      const route = context.ui.router.current()
      if (route.type === "session" && route.sessionID === sessionID) return true
      return context.ui.tabs.list().some((tab) => tab.sessionID === sessionID)
    }
    const isRoot = (sessionID: string) => !context.data.session.get(sessionID)?.parentID

    const finished = async (sessionID: string) => {
      if (!running.delete(sessionID) && !shown(sessionID)) return
      if (!isRoot(sessionID)) return
      try {
        const window = await windowForProcess()
        if (await isOnScreen(window)) return
        void notify(window, "OpenCode finished", describe(window))
      } catch {
        // Notifications must never interrupt an OpenCode session.
      }
    }

    const dispose = [
      context.data.on("session.execution.started", (event) => {
        if (shown(event.data.sessionID)) running.add(event.data.sessionID)
      }),
      context.data.on("session.execution.succeeded", (event) => void finished(event.data.sessionID)),
      context.data.on("session.execution.failed", (event) => void finished(event.data.sessionID)),
      context.data.on("session.execution.interrupted", (event) => void finished(event.data.sessionID)),
      context.data.on("form.created", async (event) => {
        const sessionID = event.data.form.sessionID
        if (!running.has(sessionID) && !shown(sessionID)) return
        if (!isRoot(sessionID)) return
        try {
          const window = await windowForProcess()
          if (await isFocused(window)) return
          void notify(window, describe(window), undefined, true)
        } catch {
          // Notifications must never interrupt an OpenCode session.
        }
      }),
    ]

    return () => dispose.reverse().forEach((cleanup) => cleanup())
  },
})
