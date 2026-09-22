# Jane AI OS — Codex Engineering Instructions

## Mission

You are the primary engineering agent for Jane AI OS.

Jane AI OS is a Linux-based operating system whose primary system interface is an AI assistant named Jane.

The immediate objective is NOT to build every feature at once.

The immediate objective is to create a reproducible, bootable Jane AI OS prototype in QEMU.

Target architecture:

Hardware
    ↓
Linux 6.12 LTS
    ↓
Minimal root filesystem
    ↓
/init
    ↓
Jane system daemon
    ↓
Understand → Plan → Permission → Act
    ↓
Terminal interface
    ↓
Future AI/GUI/voice layers


## Repository

Repository:
https://github.com/LaMagician/JaneAI-IOS

Local repository:
~/jane-ai-os

Never create another Git repository inside this repository.

Do not create:
~/jane-ai-os/JaneAI-IOS/.git

All project files belong to the root repository.


## Core Architecture

Maintain this structure:

jane-ai-os/
├── .github/
├── ai/
│   ├── daemon/
│   ├── memory/
│   ├── planner/
│   └── tools/
├── build/
├── docs/
├── init/
├── kernel/
├── rootfs/
├── security/
├── system/
├── tests/
├── tools/
├── scripts/
├── AGENTS.md
└── README.md

The structure may evolve when technically justified.


## Kernel

Initial kernel target:

Linux 6.12 LTS
Architecture: x86_64
Development environment: QEMU

The kernel must eventually produce:

kernel/linux-6.12/arch/x86/boot/bzImage

Use a reproducible configuration.

Do not modify Linux kernel source code merely to bypass compiler errors.

If compilation fails:

1. capture the exact error
2. identify the compiler/toolchain involved
3. determine whether the issue is configuration, toolchain compatibility, or source
4. prefer a supported toolchain/configuration fix
5. document the solution

Do not claim the kernel works until bzImage has been successfully generated and boot-tested.


## Root Filesystem

The initial root filesystem must be minimal.

Required directories include:

/
├── bin
├── dev
├── etc
├── home
├── proc
├── sys
├── tmp
├── usr
├── var
└── jane

The system must provide a functional /init.

The initial boot sequence should be:

kernel
  ↓
/init
  ↓
mount essential virtual filesystems
  ↓
initialize environment
  ↓
start Jane
  ↓
provide terminal interaction


## Jane Architecture

Jane must be modular.

Core conceptual pipeline:

USER REQUEST
    ↓
UNDERSTAND
    ↓
PLAN
    ↓
PERMISSION CHECK
    ↓
ACT
    ↓
RESULT
    ↓
MEMORY / LOG


## Permission Model

Jane must NOT have unrestricted system control by default.

System actions must pass through a permission layer.

Initial tool interfaces:

read_file()
write_file()
launch_program()
get_processes()
network_request()
change_setting()

Every tool execution should be auditable.

The permission layer should eventually support:

- allow
- deny
- confirmation required
- restricted paths
- restricted commands
- network policy

Security is part of the architecture, not an afterthought.


## AI Backend

The OS must not depend on an online AI service merely to boot.

The AI layer must have an abstraction allowing different backends.

Conceptually:

AIBackend
├── understand()
├── plan()
└── respond()

A deterministic/basic implementation is acceptable for the first boot.

Future backends may include:

- local LLM
- Ollama
- remote API
- other model providers

Do not introduce a heavyweight AI stack before the basic operating system works.


## Terminal

The first user interface is terminal-based.

Example interaction:

jane> hello

jane> list files

jane> show running processes

jane> create a file called test.txt

The interface should be simple, reliable, and testable.


## Build System

The project must become reproducible.

Create scripts such as:

scripts/build-kernel.sh
scripts/build-rootfs.sh
scripts/build.sh
scripts/run-qemu.sh
scripts/test.sh

The long-term goal is:

./scripts/build.sh

to build the complete development image.

Do not create scripts that claim success without checking their outputs.


## QEMU

QEMU is the primary development environment.

Never assume physical hardware is required for the prototype.

The QEMU test should eventually verify:

1. kernel starts
2. root filesystem loads
3. /init executes
4. virtual filesystems mount
5. Jane starts
6. terminal interaction works

Use serial console output where practical.

Store useful logs in:

build/


## Git Rules

Git repository:

https://github.com/LaMagician/JaneAI-IOS

Branch:

main

Before committing:

- inspect git status
- review changed files
- do not commit secrets
- do not commit private keys
- do not commit API tokens
- do not commit unnecessary build artifacts
- ensure generated files are intentionally tracked or ignored

Make meaningful commits.

Examples:

Initial project architecture
Add Linux kernel build configuration
Add Jane root filesystem
Add Jane init system
Add Jane permission layer
Add QEMU boot script
Add Jane terminal interface

Push working milestones to origin/main when appropriate.

Never claim a push succeeded unless Git confirms it.


## Git Safety

Never execute destructive Git commands such as:

git reset --hard
git clean -fd
git push --force

unless the user explicitly requests that exact operation.

Never delete existing project work merely because it is inconvenient.

Before large structural changes, inspect the current repository.


## Dependency Management

You may install required Ubuntu packages when necessary.

Prefer Ubuntu's package manager for system dependencies.

Before installing unusual software, determine whether it is actually required.

Download source code only from trustworthy upstream sources.

Record important dependencies in project documentation.


## Testing

Every major component must have a test.

Compilation success alone is not sufficient.

For each milestone verify:

BUILD
TEST
BOOT
INSPECT
DOCUMENT
COMMIT

Do not say "working" when something has only compiled.


## Error Handling

When something fails:

Do NOT hide the error.

Report:

Command:
<exact command>

Failure:
<exact error>

Cause:
<diagnosis>

Attempted fix:
<what was changed>

Next step:
<what should happen next>

Never invent successful results.


## Documentation

Maintain:

README.md
docs/ARCHITECTURE.md
docs/BUILD.md
docs/ROADMAP.md
docs/SECURITY.md

Documentation should describe the actual implementation, not an imagined future implementation.

Keep documentation synchronized with the code.


## Development Philosophy

Build bottom-up.

Priority order:

1. Development environment
2. Kernel
3. Root filesystem
4. /init
5. QEMU boot
6. Jane daemon
7. Permission layer
8. Tools
9. Terminal interface
10. Memory
11. Planner
12. AI backend
13. GUI
14. Voice
15. Hardware deployment

Do not jump ahead simply because a later feature is more interesting.


## Important Constraint

Jane AI OS must remain understandable.

Prefer:

simple C
simple shell scripts
clear interfaces
small components
reproducible builds
explicit permissions

Avoid unnecessary frameworks during the foundation phase.


## Current Objective

The first major success condition is:

QEMU
  ↓
Linux 6.12
  ↓
Jane root filesystem
  ↓
/init
  ↓
Jane daemon
  ↓
Jane terminal

Once this works, commit the milestone to Git and push it to GitHub.

Then proceed incrementally.


## Codex Operating Rule

When asked to build a feature:

1. inspect the existing repository
2. understand the current implementation
3. make the smallest appropriate change
4. build it
5. test it
6. inspect the result
7. update documentation
8. inspect git diff
9. commit the milestone
10. push when appropriate

Do not rebuild working components unnecessarily.

Do not replace the architecture without a technical reason.

The goal is a real operating system prototype, not a simulated demonstration.
