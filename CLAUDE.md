# CLAUDE.md — Project Rules & Context

> This file is read automatically by Claude Code at session start.
> **Keep it updated**: whenever a new rule, decision, or convention emerges during a session, add it here before closing.

---

## Project Overview

Berry scripting for a Tasmota-flashed coffee machine. The device controls:
- **Power1** (GPIO 27) — heating element
- **Power2** (GPIO 14) — pump

Integration with Home Assistant via MQTT discovery. The physical buttons on the machine are read as switches and handled entirely by Berry scripts.

---

## Hardware

- **Tasmota IP and MAC**: read from `LOCAL.md` (gitignored). If the file doesn't exist or values are missing, ask the user and write them there before proceeding.
- **Energy sensor**: BL09XX, accessed via `energy.active_power` (returns total W)
- **GPIO 27** = P1 (heating element relay), **GPIO 14** = P2 (pump relay)

---

## File Structure

```
src/                  # Berry source files (uploaded to Tasmota)
  autoexec.be         # Entry point, loads all modules
  Utils.be            # tprint() and ts() utilities
  HaMqttMgmt.be       # MQTT entity class hierarchy
  PowerMgmt.be        # Core machine logic (singleton PowerMgmt.powerMgmt)
  InputMgmt.be        # Physical button handling
  WebUiMgmt.be        # Tasmota web UI panel
upload-to-tasmota.sh  # Upload script (zsh, NOT bash)
listen-syslog.sh      # Syslog UDP listener for live debugging
log/                  # Gitignored — timestamped syslog captures
```

---

## Upload Workflow

```bash
zsh upload-to-tasmota.sh <ip>              # upload all src/*.be
zsh upload-to-tasmota.sh <ip> src/Foo.be  # upload single file
```

- Script is **zsh**, not bash — always invoke with `zsh`, never `bash`
- After upload it verifies each file (download + cmp) then restarts Tasmota
- Restart only happens if all files are verified successfully

---

## Debugging / Syslog

Tasmota is configured to send UDP syslog to the dev machine:
```
LogHost <mac-ip>
LogPort 64514
SysLog 4
```

Listener script:
```bash
./listen-syslog.sh          # interactive, Ctrl+C to stop
./listen-syslog.sh -d       # detached background
./listen-syslog.sh --stop   # stop background listener
```

Logs are saved in `log/tasmota-YYYYMMDD_HHMMSS.log` (gitignored).

**When analyzing logs**: always search by timestamp range, filter for `[PowerMgmt]`, `[InputMgmt]`, `[WebUiMgmt]`, `status=`, `mode=`, `P1`, `P2`, `ENERGY`.

---

## Berry Coding Conventions

### Logging
All log statements use `tprint()` (defined in Utils.be — adds timestamp prefix):
```berry
tprint(format("[ClassName] method | key=%s val=%s → decision", k, v))
```
Format: `[ClassName] method | key=val → decision`

### MQTT State Publishing
State values **must** be published as JSON via `json.dump()`:
```berry
mqtt.publish(self.stateTopic, json.dump(value), true)
```
And the discovery config **must** include:
```berry
configBody['value_template'] = '{{ value_json }}'
```
Reason: Tasmota internally subscribes to `homeassistant/#` and tries to JSON-parse all retained messages. Raw strings like `"Ready"` cause `BRY: ERROR, bad json` errors.

### General Style
- **Indentation**: 2 spaces
- **Singletons**: use static class variable (e.g., `PowerMgmt.powerMgmt = self`)
- **Persistence**: `persist.<key>` for values that survive reboots
- **Async**: `tasmota.set_timer(ms, /-> fn(), "TimerName")` — always name timers
- **Timers**: cancel with `tasmota.remove_timer("TimerName")` before setting new ones
- **No bare `energy.active_power` on startup** — can be nil before first read

---

## Git Workflow

1. **Create GitHub issue** before starting work
2. **Branch naming**: `type/issue-number-description`
   - e.g., `feature/10-auto-learning-brewing-times`, `fix/14-mqtt-json-and-syslog-listener`
3. **Conventional commits** (mandatory):
   - `feat:` new feature
   - `fix:` bug fix
   - `refactor:` restructuring without behavior change
   - `style:` formatting only
   - `docs:` documentation only
4. **Atomic commits** — one logical change per commit
5. **Commit only after user review and testing** — make all code changes first, upload to Tasmota (`zsh upload-to-tasmota.sh <ip>`), wait for user to test, then create all commits together
6. **PR toward `main`**
7. **Tag + GitHub release** on every merged PR:
   - New feature → bump **minor** (0.5 → 0.6)
   - Bug fix → bump **patch** (0.5 → 0.5.1)
8. **Close the GitHub issue** after merge + release: `gh issue close <N> --comment "Closed by PR #X, released in vY.Z."`

---

## MQTT Entity Hierarchy

```
HaMqttMgmt              (base: topics, config, createEntity)
├── HaMqttWithState     (adds state_topic, setValue via json.dump)
│   ├── HaMqttSensor    (read-only sensor)
│   └── HaMqttInputGen  (subscribes to commandTopic)
│       ├── HaMqttInput
│       │   ├── HaMqttText
│       │   └── HaMqttNumber   (castValue parses JSON number)
│       └── HaMqttSelect
└── HaMqttButton        (no state, just fires a function on command)
```

---

## Known Bugs / Open Items

- **mode=Manual during auto-start brew** (cosmetic): when P2 turns ON via auto-start, `autoStartResetTimer()` is called which sets `autoStartEnabled=false` before `updateMode()`, causing mode to show "Manual" instead of "Auto-start" during the brew. Functional behavior is correct.
