export type Ram = string

declare module 'claude-code' {
  interface PluginState {
    'my-highlights': { ram: Ram }
  }
}
