# Architecture

`/init` is PID 1. It mounts proc, sysfs, devtmpfs, and tmpfs, then execs `/jane/jane`. Jane turns a terminal request into a structured plan, checks policy, invokes a narrow tool, and records the last request. Daemon failure falls back to BusyBox sh.

The modules deliberately separate planning, permissions, tools, and memory so a future model backend can replace request understanding without bypassing policy.
