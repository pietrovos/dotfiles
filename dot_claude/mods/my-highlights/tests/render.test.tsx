import { expect, test } from 'claude-code/testing'

const row = (kind: string) => ({
  plugin: 'my-highlights',
  component: 'UserMessage',
  props: { text: 'check `ls -la` in ~/.config/hypr and @README.md', origin: { kind }, isExpanded: false },
} as const)

test('own message is boxed with highlighted parts', async ($, on) => {
  on('ui.render', ($, e) => { const { Text } = $.ui.resolve(e); return <Text>engine</Text> })
  const ui = await $.ui.mount({ ...row('composer'), surface: 'terminal' } as any)
  expect((await ui.find({ type: 'Box' }))?.props?.borderStyle).toBe('single')
  expect((await ui.find({ type: 'Text', text: /^`ls -la`$/ }))?.props?.color).toBe('warning')
  expect((await ui.find({ type: 'Text', text: /^~\/\.config\/hypr$/ }))?.props?.color).toBe('suggestion')
  expect((await ui.find({ type: 'Text', text: /^@README\.md$/ }))?.props?.color).toBe('claude')
  await ui.unmount()
})

test('notifications keep the engine drawing', async ($, on) => {
  on('ui.render', ($, e) => { const { Text } = $.ui.resolve(e); return <Text>engine</Text> })
  const ui = await $.ui.mount({ ...row('task-notification'), surface: 'terminal' } as any)
  expect((await ui.find({ type: 'Text' }))?.text).toBe('engine')
  await ui.unmount()
})

test('bare paths, URLs and mentions in replies become inline code', async ($, on) => {
  let drawn = ''
  on('ui.render', ($, e) => { drawn = (e.props as any).text; const { Text } = $.ui.resolve(e); return <Text>engine</Text> })
  const text = 'Edit ~/.config/hypr/bindings.lua. See https://example.com/a, ask @alice, mail me@x.com, 1/2 and/or `~/kept`.\n```\n~/in/fence\n```\n[link](https://x.org/y)'
  const ui = await $.ui.mount({ plugin: 'my-highlights', component: 'AssistantMessage', props: { text, isFirstOfReply: true }, surface: 'terminal' } as any)
  expect(drawn).toBe('Edit `~/.config/hypr/bindings.lua`. See `https://example.com/a`, ask `@alice`, mail me@x.com, 1/2 and/or `~/kept`.\n```\n~/in/fence\n```\n[link](https://x.org/y)')
  await ui.unmount()
})
