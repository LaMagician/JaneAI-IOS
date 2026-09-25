# Security model

Jane does not receive an unrestricted shell tool. Every dispatchable action reaches the permission layer first, which returns `allow`, `confirm`, or `deny`. v0.1 allows selected diagnostic reads and writes below `/tmp` and `/jane/memory`; writes below `/root`, allowed program launches, and hostname changes require explicit confirmation. Network and unknown actions are denied.

Each request is appended to `/jane/memory/audit.log` with the planned action, target, and final decision (`allow`, `confirm_allow`, `confirm_deny`, or `deny`) for post-boot inspection.
