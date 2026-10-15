import { accessSync, constants } from "node:fs"
import path from "node:path"
import { Plugin } from "@opencode/plugin/tui"

// Startup flags that choose a session or seed the prompt; the restart passes its own --session.
const valued = ["--session", "-s", "--prompt"]
const dropped = ["--continue", "-c"]

function relaunchArgs(sessionID: string | undefined) {
  const args: string[] = []
  const input = process.argv.slice(2)
  for (let index = 0; index < input.length; index++) {
    const arg = input[index]
    if (valued.includes(arg)) {
      index++
      continue
    }
    if (dropped.includes(arg) || valued.some((flag) => arg.startsWith(`${flag}=`))) continue
    args.push(arg)
  }
  return sessionID ? [...args, "--session", sessionID] : args
}

// Prefer `opencode` from PATH so a restart after `mise upgrade` runs the new version.
function executable() {
  for (const directory of (process.env.PATH ?? "").split(path.delimiter)) {
    if (!directory) continue
    const candidate = path.join(directory, "opencode")
    try {
      accessSync(candidate, constants.X_OK)
      return candidate
    } catch {}
  }
  return process.execPath
}

export default Plugin.define({
  id: "pietrovos.restart",
  setup(context) {
    let restarting = false

    const restart = () => {
      if (restarting) return
      restarting = true
      const route = context.ui.router.current()
      const command = executable()
      const args = relaunchArgs(route.type === "session" ? route.sessionID : undefined)
      const env = Object.fromEntries(
        Object.entries(process.env).filter((entry): entry is [string, string] => entry[1] !== undefined),
      )

      // Exec only after OpenCode's own shutdown has restored the terminal and run its finalizers.
      process.once("exit", () => {
        try {
          process.execve(command, [command, ...args], env)
        } catch (error) {
          process.stderr.write(`Failed to restart OpenCode: ${error instanceof Error ? error.message : error}\n`)
        }
      })
      context.keymap.dispatch("app.exit")
      if (!context.renderer.isDestroyed) context.renderer.destroy()
    }

    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "pietrovos.restart",
          title: "Restart OpenCode in this session",
          group: "System",
          bind: "ctrl+shift+r",
          palette: true,
          // Built-in /restart restarts the background service.
          slash: { name: "relaunch" },
          enabled: process.platform !== "win32",
          run: restart,
        },
      ],
      bindings: ["pietrovos.restart"],
    }))
  },
})
