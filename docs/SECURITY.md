# Security model

Jane does not receive an unrestricted shell tool. Every dispatchable action reaches the permission layer first, which returns `allow`, `confirm`, or `deny`. v0.1 allows selected diagnostic reads and writes below `/tmp`, `/jane/memory`, and persistent `/jane/state` state paths; writes below `/root`, allowed program launches, and hostname changes require explicit confirmation. Unknown actions are denied.

Network requests are denied by default; localhost URLs require explicit confirmation. Each request is appended to `<state>/memory/audit.log` with the planned action, target, and final decision (`allow`, `confirm_allow`, `confirm_deny`, or `deny`) for post-boot inspection.
