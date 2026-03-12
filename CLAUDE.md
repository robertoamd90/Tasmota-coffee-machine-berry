# CLAUDE.md — Project Rules & Context

> This file is read automatically by Claude Code at session start.
> **Keep it updated**: whenever a new rule, decision, or convention emerges during a session, add it here before closing.

---

## Project Overview

Berry scripting for a Tasmota-flashed coffee machine. Integration with Home Assistant via MQTT discovery. Physical buttons handled entirely by Berry scripts.

- **Power1** (GPIO 27) — heating element relay
- **Power2** (GPIO 14) — pump relay
- **Energy sensor**: BL09XX, accessed via `energy.active_power` (returns total W)
- **Tasmota IP and MAC**: read from `LOCAL.md` (gitignored). If missing, ask the user and write them there before proceeding.

---

## Upload Workflow

```bash
zsh upload-to-tasmota.sh <ip>              # upload all src/*.be
zsh upload-to-tasmota.sh <ip> src/Foo.be  # upload single file
```

Always invoke with `zsh`, never `bash`. Script verifies each file after upload and restarts Tasmota only if all verifications pass.

---

## Debugging / Syslog

```bash
./listen-syslog.sh          # interactive, Ctrl+C to stop
./listen-syslog.sh -d       # detached background
./listen-syslog.sh --stop   # stop background listener
```

Logs saved in `log/tasmota-YYYYMMDD_HHMMSS.log` (gitignored).

**When analyzing logs**: filter for `[PowerMgmt]`, `[InputMgmt]`, `[WebUiMgmt]`, `status=`, `mode=`, `P1`, `P2`, `ENERGY`.

---

## Berry Coding Conventions

### Logging
```berry
tprint(format("[ClassName] method | key=%s val=%s → decision", k, v))
```

### MQTT State Publishing
State values **must** be published as JSON via `json.dump()`:
```berry
mqtt.publish(self.stateTopic, json.dump(value), true)
```
Discovery config **must** include `configBody['value_template'] = '{{ value_json }}'`.
Reason: Tasmota JSON-parses all retained `homeassistant/#` messages — raw strings cause `BRY: ERROR, bad json`.

### General Style
- **Indentation**: 2 spaces
- **Singletons**: static class variable (e.g., `PowerMgmt.powerMgmt = self`)
- **Persistence**: `persist.<key>` for values that survive reboots
- **Timers**: `tasmota.set_timer(ms, /-> fn(), "TimerName")` — always named; cancel with `tasmota.remove_timer("TimerName")` before resetting
- **No bare `energy.active_power` on startup** — can be nil before first read

---

## Git Workflow

1. **Create GitHub issue** before starting work
2. **Branch naming**: `type/issue-number-description` (e.g., `feature/10-auto-learning-brewing-times`)
3. **Conventional commits**: `feat:` / `fix:` / `refactor:` / `style:` / `docs:`
4. **Atomic commits** — one logical change per commit
5. **Commit only after user review and testing** — upload first (`zsh upload-to-tasmota.sh <ip>`), wait for test, then commit
6. **PR toward `main`**
7. **Tag + GitHub release** on every merged PR: minor bump for features, patch bump for fixes
8. **Close the GitHub issue**: `gh issue close <N> --comment "Closed by PR #X, released in vY.Z."`
