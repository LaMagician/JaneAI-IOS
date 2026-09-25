# Architecture

`/init` is PID 1. It mounts proc, sysfs, devtmpfs, and tmpfs, then execs `/jane/jane`. Jane turns a terminal request into a structured plan, checks policy, invokes a narrow tool, records the last request, and appends an audit event to `/jane/memory/audit.log`. Daemon failure falls back to BusyBox sh.

The modules deliberately separate planning, permissions, tools, and memory so a future model backend can replace request understanding without bypassing policy. The permission boundary now returns `allow`, `confirm`, or `deny`, letting sensitive actions require explicit user confirmation.
