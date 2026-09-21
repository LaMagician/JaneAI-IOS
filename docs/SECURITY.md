# Security model

Jane does not receive an unrestricted shell tool. Every dispatchable action reaches `permission_check` first. v0.1 allows selected diagnostic reads, writes below `/tmp`, `/root`, and `/jane/memory`, a small program allowlist, process listing, and hostname changes. Network and unknown actions are denied.
