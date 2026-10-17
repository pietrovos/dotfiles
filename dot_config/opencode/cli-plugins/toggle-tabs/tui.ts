import { readFile, writeFile } from "node:fs/promises"
import os from "node:os"
import path from "node:path"
import { Plugin } from "@opencode/plugin/tui"

export default Plugin.define({
  id: "pietrovos.toggle-tabs",
  setup(context) {
    let updating = false

    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "pietrovos.tabs.toggle",
          title: "Toggle session tabs",
          group: "Appearance",
          bind: "<leader>h",
          palette: true,
          slash: { name: "tabs" },
          async run() {
            if (updating) return
            updating = true
            try {
              const file = path.join(process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config"), "opencode", "cli.json")
              const config = JSON.parse(await readFile(file, "utf8"))
              const hidden = config.tabs?.mode === "off" || (config.tabs?.mode === undefined && config.tabs?.enabled === false)
              config.tabs = { ...config.tabs, mode: hidden ? "on" : "off" }
              await writeFile(file, JSON.stringify(config, null, 2) + "\n")
              context.ui.toast.show({ message: hidden ? "Session tabs shown" : "Session tabs hidden", variant: "success" })
            } catch (error) {
              context.ui.toast.show({ message: `Could not toggle tabs: ${error instanceof Error ? error.message : error}`, variant: "error" })
            } finally {
              updating = false
            }
          },
        },
      ],
      bindings: ["pietrovos.tabs.toggle"],
    }))
  },
})
