# Mac Better Fan Control Agent Rules

`AGENTS.md` is the canonical entry point for GPT/Codex and Claude. `CLAUDE.md` imports it; edit the shared rules rather than maintaining provider-specific copies.

## Project Scope

- Native macOS utility targeting Apple Silicon M1–M5, including Pro, Max, and Ultra variants where available. Target support is not verified compatibility.
- Swift 6, SwiftUI, selective AppKit, Swift Package Manager, and macOS 14+. Keep dependencies minimal and justified by a concrete need.
- Read `README.md` and `Package.swift` for the current implementation and available commands. Planned hardware access and helpers are not implemented merely because these rules describe them.

## Hard Gates

If your change violates a rule, fix it before continuing.

- Keep changes lean and minimal. Readability and clarity come first; do not hide complexity behind wrappers or speculative frameworks.
- Never present simulated, stale, missing, or invalid sensor data as live readings. Never claim a fan setting was applied without hardware verification.
- Keep hardware access out of views. Validate readings, fan identifiers, and hardware-reported limits at the hardware boundary.
- Fan writes require an explicit control design, a narrowly scoped privileged helper, recovery to automatic control, and verification on the target machine. Never disable system thermal protections.
- Never bypass Swift type or concurrency checks to silence errors. Keep necessary unsafe hardware interop contained and documented.
- Use Apple unified logging for lifecycle and hardware failures; keep sensitive machine details out of logs.
- Commit each coherent change after relevant verification. Stage and commit only explicit owned paths; never overwrite or discard concurrent work or bypass hooks.

## Task Routing

Before editing, read [Git](rules/GIT.md), any scoped `AGENTS.md`, and the matching rules below. For code, also read [Architecture](rules/ARCHITECTURE.md) and [Clean Code](rules/CLEAN-CODE.md).

- Views, menu bar, settings, state, or interaction design → [SwiftUI](rules/SWIFTUI.md).
- Sensors, fan control, IOKit, XPC, privileges, lifecycle, or hardware logging → [Hardware](rules/HARDWARE.md).
- Tests, builds, packaging, verification, or implementation review → [Testing](rules/TESTING.md).

## Working Behaviour

- Read files before editing. Locate the responsible behaviour and fix its owning rule rather than patching a single symptom.
- Search for an existing type, formatter, or operation before adding another. Keep one authoritative owner for readings, control state, and persisted settings.
- Preserve product behaviour unless the requested change includes it. Keep unrelated refactors out of the task.
- Use native macOS conventions and proper English. Label temperature and RPM units consistently.
- Verify uncertain Apple API or hardware behaviour against primary documentation or source; distinguish documented APIs from reverse-engineered protocols.
- Use `swift build` for compilation and `./scripts/run.sh` for a local app launch when relevant. Text-only rules and docs need content and diff checks, not app builds or specialist reviews.
- Run ordinary reviews in the current thread. Delegate only when the user or an explicitly invoked workflow requests it.
- Report what changed, what was actually verified, remaining limits, and the commit hash and subject. Compilation, app launch, hardware verification, and distribution are distinct outcomes.
