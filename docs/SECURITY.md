## Current Enforcement

Jane requests pass through the planner and permission predicates before tools execute. Path policies reject traversal, dot segments, duplicate separators, and protected system writes. Requests, plans, permission decisions, and tool completion are recorded as append-only tab-separated events under `/jane/audit/events.log`.

Permission decisions are classified as `allow`, `confirm`, or `deny`. Hostname changes currently require a separate `confirm` response before execution. Memory entries are private by default, reject tab-delimited keys, sanitize values, and have a bounded entry size.

The first-boot identity flow records Jane's purpose, creator, and user context separately from the immutable daemon code. It is intentionally honest that Jane is software and not conscious. The current initramfs remains ephemeral; durable encrypted memory and user authentication are required before treating this as a production security boundary.

## Known Boundary

The current image still runs as root in a minimal initramfs. Jane now has bounded daemon restarts and only enters a shell when `JANE_RECOVERY=1` is explicitly set. Without that flag, repeated daemon failure leaves the system in a recovery wait state. It is suitable for the QEMU development milestone, not a security-certified desktop installation. Sandboxing, privilege separation, and confirmation UI are subsequent milestones.
# Security model

Jane does not receive an unrestricted shell tool. Every dispatchable action reaches `permission_check` first. v0.1 allows selected diagnostic reads, writes below `/tmp`, `/root`, and `/jane/memory`, a small program allowlist, process listing, and hostname changes. Network and unknown actions are denied.
