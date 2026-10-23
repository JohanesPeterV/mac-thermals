# Mac Better Fan Control

- Keep changes lean, readable, and native to macOS. Prefer SwiftUI and the Swift toolchain; avoid dependencies without a concrete need.
- Read `README.md` for the current implementation scope. Use `swift build` for compilation and `./scripts/run.sh` for a local app launch.
- Never present simulated values as live readings or imply a fan setting was applied without verifying the hardware result.
- Keep hardware access separate from views. Validate sensor values and hardware-reported fan limits at that boundary.
- Fan writes require an explicit control design, narrowly scoped privileges, lifecycle recovery, and verification on the target machine. Do not disable system thermal protections.
- Use Apple unified logging for lifecycle and hardware failures; keep sensitive machine details out of logs.
- Verify the changed behaviour, then commit only explicit owned paths with a conventional commit message. Preserve concurrent work.
