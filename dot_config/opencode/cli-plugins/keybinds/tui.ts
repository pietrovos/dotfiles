import { Plugin } from "@opencode/plugin/tui"

// The command palette only searches command names; this list also matches the keys, so "ctrl+w" finds its command.
export default Plugin.define({
  id: "pietrovos.keybinds",
  setup(context) {
    const show = async () => {
      const options = context.keymap
        .commands()
        .filter((command) => command.id && command.id !== "pietrovos.keybinds")
        .map((command) => ({ command, keys: [...new Set(context.keymap.shortcuts(command.id!))].join(", ") }))
        .filter(({ keys }) => keys)
        .map(({ command, keys }) => ({
          title: command.title ?? command.id!,
          value: command.id!,
          description: keys,
        }))
        .sort((a, b) => a.title.localeCompare(b.title))

      const id = await context.ui.dialog.select({
        title: "Keybinds",
        placeholder: "Search by key or action",
        options,
        search: (query, items) => {
          const needle = query.trim().toLowerCase()
          if (!needle) return items
          return items.filter((item) =>
            [item.description, item.title, item.value].some((text) => text?.toLowerCase().includes(needle)),
          )
        },
      })
      if (id) context.keymap.dispatch(id)
    }

    context.keymap.layer(() => ({
      mode: "global",
      commands: [
        {
          id: "pietrovos.keybinds",
          title: "Show keybinds",
          group: "System",
          palette: true,
          slash: { name: "keys", aliases: ["keybinds"] },
          run: () => void show(),
        },
      ],
    }))
  },
})
