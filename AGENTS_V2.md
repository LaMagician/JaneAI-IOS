# JANE AI OS — AUTONOMOUS FULL-PROJECT BUILD DIRECTIVE

## MISSION

You are the principal engineering agent responsible for building Jane AI OS.

Your objective is NOT to create a demonstration, mockup, scaffold, documentation-only project,
or collection of placeholder files.

Your objective is to transform this repository into a coherent, reproducible, bootable,
testable operating system with an integrated AI assistant named Jane.

Continue working through the project autonomously.

Do not stop merely because the project is large.

Do not stop after creating scaffolding.

Do not stop after writing documentation.

Do not stop after implementing one subsystem.

Do not claim completion while major components are missing, fake, untested, or disconnected.

When something fails:

1. identify the first real failure;
2. inspect the relevant code/configuration;
3. determine the cause;
4. implement the smallest correct fix;
5. rebuild;
6. test;
7. continue.

Do not hide errors by disabling warnings or deleting tests.

Do not replace implementation with TODO comments.

Do not create fake implementations merely to make tests pass.

The final objective is a working Jane AI OS development release.
JANE AI OS

                ┌──────────────────────┐
                │       USER           │
                └──────────┬───────────┘
                           │
                  keyboard / voice
                           │
                ┌──────────▼───────────┐
                │     JANE GUI         │
                │ avatar / desktop     │
                │ chat / applications  │
                └──────────┬───────────┘
                           │ IPC
                ┌──────────▼───────────┐
                │     JANE DAEMON      │
                │ understand           │
                │ plan                 │
                │ permission           │
                │ execute              │
                │ remember             │
                └───────┬───────┬──────┘
                        │       │
             ┌──────────▼─┐   ┌─▼───────────┐
             │   MEMORY   │   │   PLANNER   │
             └────────────┘   └─────────────┘
                        │
                ┌───────▼────────┐
                │ TOOL SYSTEM     │
                │ files           │
                │ processes       │
                │ applications    │
                │ network         │
                │ settings        │
                └───────┬────────┘
                        │
                ┌───────▼────────┐
                │ SECURITY       │
                │ permissions    │
                │ validation     │
                │ audit logging  │
                └───────┬────────┘
                        │
                ┌───────▼────────┐
                │ LINUX USERSPACE│
                │ /init          │
                │ services       │
                │ rootfs         │
                └───────┬────────┘
                        │
                ┌───────▼────────┐
                │ LINUX 6.12     │
                │ x86_64 kernel  │
                └───────┬────────┘
                        │
                ┌───────▼────────┐
                │ HARDWARE/QEMU  │
                └────────────────┘

1. Linux 6.12 kernel
2. reproducible kernel configuration
3. minimal root filesystem
4. real /init
5. service management
6. networking
7. storage
8. process management
9. security boundary
10. permission system
11. audit logging
12. Jane AI daemon
13. model abstraction
14. local model support where practical
15. memory
16. planner
17. tool registry
18. filesystem tools
19. application launcher
20. process tools
21. system information
22. settings
23. GUI
24. desktop shell
25. animated Jane avatar
26. keyboard interaction
27. voice input
28. speech-to-text
29. text-to-speech
30. voice/avatar state synchronization
31. notifications
32. file manager
33. system monitor
34. terminal
35. QEMU
36. automated boot tests
37. unit tests
38. integration tests
39. security tests
40. clean reproducible build
41. ISO/image generation
42. GitHub Actions
43. documentation
44. release artifacts
45. checksums
46. troubleshooting tools
47. safe mode
48. developer mode
49. diagnostic mode
## NO FAKE COMPLETION

A directory containing empty files is NOT an implementation.

A class containing `pass` is NOT an implementation.

A function returning a hardcoded value is NOT an implementation unless that
hardcoded value is explicitly part of the specification.

A GUI screenshot is NOT a GUI.

A mock AI response is NOT an AI integration.

A shell command printed to the screen is NOT tool execution.

A fake boot message is NOT a booting operating system.

A successful compilation of one component is NOT project completion.

Documentation describing a feature that does not exist is NOT completion.

Every major feature must be:

IMPLEMENTED
→ BUILT
→ INTEGRATED
→ TESTED
→ VERIFIED
→ DOCUMENTED
→ COMMITTED
## CONTINUOUS AUTONOMOUS WORK

Continue through all achievable milestones without waiting for the user
after every individual task.

When one milestone succeeds, immediately inspect the next milestone and
continue.

Do not ask the user:

"Should I continue?"

when continuation is already authorized by this directive.

Do not stop simply because the user is absent.

Do not stop after a successful build if integration work remains.

Do not stop after a successful boot if the GUI, AI, voice, security,
testing, or other required systems remain unfinished.

The user intends to review the project after the autonomous implementation
period.

Therefore optimize for a complete, tested repository rather than frequent
conversation updates.
MILESTONE 01 — Repository audit
MILESTONE 02 — Build infrastructure
MILESTONE 03 — Dependency installation
MILESTONE 04 — Linux kernel
MILESTONE 05 — Kernel configuration
MILESTONE 06 — Root filesystem
MILESTONE 07 — /init
MILESTONE 08 — Service manager
MILESTONE 09 — QEMU boot
MILESTONE 10 — System logging
MILESTONE 11 — Security layer
MILESTONE 12 — Permission engine
MILESTONE 13 — Tool registry
MILESTONE 14 — Filesystem tools
MILESTONE 15 — Process tools
MILESTONE 16 — Network tools
MILESTONE 17 — Settings tools
MILESTONE 18 — Jane daemon
MILESTONE 19 — Model abstraction
MILESTONE 20 — Memory
MILESTONE 21 — Planner
MILESTONE 22 — AI/tool integration
MILESTONE 23 — CLI Jane
MILESTONE 24 — GUI foundation
MILESTONE 25 — Desktop shell
MILESTONE 26 — Jane avatar
MILESTONE 27 — Animation system
MILESTONE 28 — GUI/Jane IPC
MILESTONE 29 — File manager
MILESTONE 30 — Application launcher
MILESTONE 31 — System monitor
MILESTONE 32 — Settings GUI
MILESTONE 33 — Notifications
MILESTONE 34 — Voice input
MILESTONE 35 — Speech recognition
MILESTONE 36 — Text-to-speech
MILESTONE 37 — Avatar voice synchronization
MILESTONE 38 — Accessibility
MILESTONE 39 — Networking
MILESTONE 40 — Security testing
MILESTONE 41 — Integration testing
MILESTONE 42 — QEMU automated boot testing
MILESTONE 43 — Clean rebuild
MILESTONE 44 — ISO/image generation
MILESTONE 45 — CI
MILESTONE 46 — Documentation
MILESTONE 47 — Performance
MILESTONE 48 — Recovery/safe mode
MILESTONE 49 — Release packaging
MILESTONE 50 — FINAL SYSTEM VERIFICATION
Before marking a milestone complete:

- inspect implementation
- compile/build
- run tests
- test integration
- inspect logs
- fix failures
- run the test again
- inspect Git diff
- commit the working milestone

A milestone may only be marked COMPLETE when its acceptance criteria
actually pass.
## FINAL ACCEPTANCE TEST

Do not declare Jane AI OS complete until the following sequence works:

1. Start from a clean repository.
2. Install documented dependencies.
3. Run the documented build command.
4. Kernel builds.
5. Root filesystem builds.
6. /init is installed.
7. initramfs/image is generated.
8. QEMU starts.
9. Linux boots.
10. /init executes.
11. required filesystems mount.
12. services start.
13. Jane daemon starts.
14. GUI starts.
15. Jane interface appears.
16. keyboard input works.
17. Jane can receive a request.
18. Jane can produce a response.
19. tool calls pass through permissions.
20. safe filesystem operations work.
21. unsafe operations require permission.
22. process information works.
23. system information works.
24. memory works.
25. planner works.
26. GUI applications work.
27. file manager works.
28. system monitor works.
29. settings work.
30. voice input works when supported hardware/backend is available.
31. TTS works when supported backend is available.
32. avatar state changes during listening/thinking/speaking.
33. logs are produced.
34. security tests pass.
35. integration tests pass.
36. QEMU boot test passes.
37. clean rebuild passes.
38. release artifact is generated.
39. checksum is generated.
40. documentation matches the actual implementation.

If a requirement cannot be supported in the current VM, document the exact
environment limitation and implement a functional fallback where possible.
Never pretend unsupported hardware functionality works.
## GIT

Never force-push.

Never destroy existing work.

Never commit secrets.

Never commit API keys.

Never commit authentication tokens.

Never commit private keys.

Use meaningful commits.

After each major milestone:

git status
git diff
git add ...
git commit ...

Push to the configured GitHub remote when appropriate.

The repository must always remain recoverable.