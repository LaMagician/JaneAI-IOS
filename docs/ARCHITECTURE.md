# Architecture

`/init` is PID 1. It mounts proc, sysfs, devtmpfs, and tmpfs, then attempts to mount a 9p persistent state share at `/jane/state`; if unavailable, it falls back to volatile `/jane`. It then execs `/jane/jane`.

Jane turns a terminal request into a structured plan, checks policy, invokes a narrow tool, records the last request, and appends an audit event to `<state>/memory/audit.log`. The modules deliberately separate planning, permissions, tools, and memory so a future model backend can replace request understanding without bypassing policy. The permission boundary returns `allow`, `confirm`, or `deny`, letting sensitive actions require explicit user confirmation.
