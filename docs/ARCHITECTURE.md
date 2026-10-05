# Architecture

`/init` is PID 1. It mounts proc, sysfs, devtmpfs, and tmpfs, then execs `/jane/jane`. Jane turns a terminal request into a structured plan, checks policy, invokes a narrow tool, and records the last request. Daemon failure falls back to BusyBox sh.

The modules deliberately separate planning, permissions, tools, and memory so a future model backend can replace request understanding without bypassing policy.

## Hardware Profiles

`ai/system/profile.sh` performs one inexpensive hardware probe at Jane startup. It selects `ULTRA_LOW`, `LOW`, `STANDARD`, or `PERFORMANCE` from RAM, while recording CPU count, graphics devices, storage, and network availability. The selected model profile, context limit, and voice mode are exported to the backend and tools. Four- and eight-gigabyte systems use CPU-oriented profiles with small contexts and push-to-talk voice; larger systems can opt into broader local models without changing the core daemon.

The backend accepts a llama.cpp-compatible command through `JANE_MODEL_RUNTIME` and a quantized model file through `JANE_MODEL_FILE`. It never loads a model unless both are configured and executable; otherwise the deterministic backend remains available. This keeps the base image small and lets a 4 GB installation add one small quantized model without requiring a database server, container runtime, or GPU.

Memory is disk-backed and bounded: exact facts remain in the state disk, `find TEXT` retrieves at most eight relevant records, `context` exposes only the eight most recent requests, and `compact memory` removes older duplicate keys. This avoids loading an unbounded conversation history into RAM.

Sequence plans are capped at eight steps. Each step produces an audit checkpoint, retries once by default on execution failure, and stops before later steps when the retry budget is exhausted or confirmation is pending. `JANE_SEQUENCE_RETRIES` can reduce or increase the retry budget up to the configured deployment policy.

File writes are verified after execution. If a later sequence step fails, Jane restores previous file contents or removes files created by that sequence. External programs and future network actions are deliberately not represented as reversible side effects and are stopped rather than falsely rolled back.

The runtime applies a one-shot memory-pressure policy before serving requests. When `/proc/meminfo` reports 256 MiB or less available memory, Jane reduces the active context to 512 tokens and forces push-to-talk voice. The resource acceptance test boots the QEMU image with 256 MiB guest RAM and records peak host RSS; it currently passes below the 512 MiB ceiling.

## Skills and System Context

The registry in `ai/skills/registry.tsv` describes versioned capabilities and their permissions. Jane can list or search those capabilities without granting arbitrary execution. System context is exposed through approved tools for kernel, memory, storage, hostname, processes, directory listing, and file search; each invocation still crosses the permission and audit layers.

## Human Interface

`tools/jane-interface.py` is a host-side Tk interface for the current serial-only QEMU target. It starts the built image, displays Jane's output, sends typed requests, and speaks response lines with the offline `espeak-ng` command. Microphone input records a WAV file with `arecord` or `parec` and uses the offline `pocketsphinx_continuous` recognizer by default. A different recognizer can be selected with `JANE_STT_COMMAND`; it receives the WAV path and must print the transcript. The guest remains unchanged and keeps the permission boundary in the daemon.
