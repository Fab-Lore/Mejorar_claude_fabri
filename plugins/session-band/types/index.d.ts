export type Stats = {
  turn: number
  speed: number | null
  turnCost: number | null
  total: number
  context: number
  costAtStart: number
}

export type Cache = {
  expiresAt: number | null
  secondsLeft: number | null
}

/** One plan window: percent used (0-100) and when it resets (Unix seconds). */
export type PlanWindow = { pct: number; resetsAt: number }

export type Limits = {
  five: PlanWindow | null
  week: PlanWindow | null
}

declare module 'claude-code' {
  interface PluginState {
    'session-band': { stats: Stats; cache: Cache; isHidden: boolean; isBusy: boolean; warned: number; limits: Limits }
  }
}
