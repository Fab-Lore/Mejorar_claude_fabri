# mod-claude

Mi versión modificada de [claude-kit](https://github.com/johnnyvizz/claude-kit) de johnnyvizz: skills y mods para [Claude Code](https://claude.com/claude-code). Cada carpeta en `plugins/` es un plugin independiente.

## Qué cambia respecto a claude-kit

- **Medidor de uso del plan** (session-band 0.3.0): la banda sobre el prompt muestra cuánto llevas gastado de la sesión de 5 horas (`68%`) y cuánto falta para que se restablezca (`↻ 2h 43m`), igual que la página de uso de la app. Se pone ámbar al 75% y roja al 90%. Además trae una línea de estado (`statusline/usage.sh`) que lo muestra bajo el prompt: `Sesión ██████░░░░ 68% · se restablece en 2 h 43 min · Semana 12%`.
- **Agentes con herramientas de su oficio** (savvy-progress 1.3.0): en el panel de agentes, el que diseña (Fable) es un pintor con boina y **pincel**, y el que programa (Medium) lleva audífonos y escribe en una **laptop** con el cursor parpadeando.

| Plugin | Tipo | Qué hace |
| --- | --- | --- |
| [savvy-flow](plugins/savvy-flow) | skill + agentes | `/savvy-flow <tarea>`: el modelo de la sesión planea, delega a subagentes por niveles y revisa su trabajo. |
| [savvy-progress](plugins/savvy-progress) | mod | Barra de progreso sobre el prompt y panel de agentes en vivo. |
| [session-band](plugins/session-band) | mod | Banda sobre el prompt: turno, velocidad, costo, caché, contexto y **uso del plan**. |

## Instalar

En Claude Code:

```
/plugin marketplace add TU_USUARIO/mod-claude
/plugin install session-band@mod-claude
/plugin install savvy-progress@mod-claude
/plugin install savvy-flow@mod-claude
```

Reinicia la sesión después.

### El medidor de uso necesita la línea de estado

Claude Code solo le pasa los límites del plan al comando de la línea de estado. Clona el repo y agrega esto a `~/.claude/settings.json`:

```bash
git clone https://github.com/TU_USUARIO/mod-claude.git ~/mod-claude
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/mod-claude/plugins/session-band/statusline/usage.sh"
  }
}
```

Solo aparece con una suscripción de Claude.ai (Pro, Max, Team…) y después de la primera respuesta; con una API key no hay límites que mostrar.

### A mano

```bash
claude --plugin-dir ~/mod-claude/plugins/session-band
```

o para todas las sesiones, en `~/.claude/settings.json` (varias carpetas separadas con `:`):

```json
{
  "env": {
    "CLAUDE_CODE_PLUGIN_DIRS": "~/mod-claude/plugins/session-band:~/mod-claude/plugins/savvy-progress"
  }
}
```

Los mods usan los function hooks (`hooks/register.tsx`), una API en acceso anticipado de Claude Code: probados con Claude Code 2.1.303 y puede cambiar entre versiones.

## Revisar antes de publicar

```bash
claude plugin validate plugins/session-band
claude plugin test plugins/session-band
claude plugin test plugins/savvy-progress
```

## Créditos y licencia

Basado en [johnnyvizz/claude-kit](https://github.com/johnnyvizz/claude-kit). MIT: ver [LICENSE](LICENSE), que conserva el aviso de copyright original.
