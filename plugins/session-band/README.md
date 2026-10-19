# session-band

A Claude Code mod: one band above the prompt with the session at a glance.

- **Band**: turn number, output speed of the last response (tok/s), cost of the last turn and of the session, a countdown of the 1-hour prompt cache since the last answer, and context fill. The band gets an amber frame 20 minutes before the cache expires and a red one at 10. The row drops details as the window narrows instead of wrapping; `×` hides it for the rest of the session.
- **Plan usage** (new in mod-claude): on a Claude.ai subscription, a gauge with how much of the 5-hour session limit you have used (`68%`) and how long until it resets (`↻ 2h 43m`), like the usage page in the app. It turns amber at 75% and red at 90%. When only the weekly limit is reported it shows that one with `wk`. It needs the status line below.
- **Cache warning**: at 10 and 5 minutes left, a system notification with Claude's icon, titled `<project> — <session title>`, saying how many minutes the cache has left. In the desktop app, clicking it opens the session. Nothing fires while a turn runs.

## The notifier (macOS)

The warning is posted by a small helper app, built once on your Mac (needs Xcode's command line tools; the icon is taken from your installed Claude.app):

```bash
plugins/session-band/notifier/build.sh
```

It builds `notifier/Session Band.app` next to the script; on its first notification macOS asks whether to allow notifications from "Session Band". Build it in the folder the mod is loaded from, or copy the built app there. Without the helper (or on another OS) the mod falls back to Claude Code's own notification, which also reaches your phone over Remote Control but has no title or click-through; when you are already at the session that one is skipped and a toast says it instead.

## Plan usage: the status line (needed for the meter)

Claude Code only hands the plan limits to the status line command, so the mod ships one: `statusline/usage.sh`. It prints

```
Sesión ██████▌░░░ 68% · se restablece en 2 h 43 min · Semana 12%
```

under the prompt and saves the numbers to `~/.claude/session-band-usage.json`, where the band reads them every 5 seconds. Point your status line at it in `~/.claude/settings.json` (use the path of your clone):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/mod-claude/plugins/session-band/statusline/usage.sh"
  }
}
```

It uses `jq` when installed and a plain fallback otherwise. With an API key (no subscription) there are no limits to show, so both stay empty.

## Commands

- `/session_data`: show or hide the band.
- `/session_data demo <minutes>`: pretend the cache has that many minutes left, to preview the colors and the warning; the next answer resets it.

Install instructions are in the [repository README](../../README.md).
