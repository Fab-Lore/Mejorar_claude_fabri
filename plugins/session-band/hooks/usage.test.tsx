import { expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

const NOW = Date.parse('2026-10-18T12:00:00Z')
const FILE = '/home/test/.claude/session-band-usage.json'
const BAND = { component: 'AbovePrompt', props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 140 } as never } as const

// A session with one turn, where statusline/usage.sh left `limits` in the file
// (or no file at all when `limits` is null); the band is drawn after its first read.
async function band($: Engine, on: On, limits: unknown): Promise<string[]> {
  const clock = mock.clock(on, { now: NOW })
  mock.env(on, { HOME: '/home/test' })
  on('fs.read', async (_$, e) =>
    (e.path === FILE && limits !== null ? { value: JSON.stringify(limits) } : { deny: 'ENOENT' }) as never,
  )
  on('command.register', async () => ({ value: undefined }) as never)
  on('session.usage', async () => ({ value: { cost: { usd: 0.1 }, context: { percent: 12 } } }) as never)
  on('session.start', async () => ({ cwd: '/repo' }) as never)
  on('turn.start', async () => ({ turnId: 't1' }) as never)
  on('ui.render', async () => null as never)

  await $.session.start({ source: 'startup', cwd: '/repo', surface: 'terminal', isInteractive: true } as never)
  await $.turn.start({ turnId: 't1', prompt: 'hi' } as never)
  await clock.advance(1000)

  const ui = await $.ui.mount({ plugin: 'session-band', surface: 'terminal', ...BAND })
  const texts = await ui.findAll({ type: 'Text' })
  await ui.unmount()
  return texts.map(t => String((t as { text?: unknown }).text ?? ''))
}

test('the band shows the 5-hour session usage and when it resets', async ($, on) => {
  const texts = await band($, on, { five: { pct: 68.4, resetsAt: NOW / 1000 + 2 * 3600 + 43 * 60 + 30 }, week: { pct: 12, resetsAt: NOW / 1000 + 86400 } })
  expect(texts).toContain('68%')
  expect(texts).toContain('↻ 2h 43m')
})

test('without the file (an API key, or no status line yet) there is no usage segment', async ($, on) => {
  const texts = await band($, on, null)
  expect(texts.some(t => t.startsWith('↻'))).toBe(false)
  expect(texts).not.toContain('68%')
})

test('a session window that already reset is not shown; the week still is', async ($, on) => {
  const texts = await band($, on, { five: { pct: 99, resetsAt: NOW / 1000 - 60 }, week: { pct: 41, resetsAt: NOW / 1000 + 86400 } })
  expect(texts).not.toContain('99%')
  expect(texts).toContain('41%')
  expect(texts).toContain('wk')
})
