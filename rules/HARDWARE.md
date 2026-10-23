# Hardware And Fan Control

## Compatibility And Reads

- Treat M1–M5 as a target range. Record support by actual Mac model, chip variant, and macOS version; one working device does not establish generation-wide support.
- Discover fan count, available sensors, data types, and limits at runtime. Keep verified model-specific mappings in the adapter, not in views or scattered chip-name checks.
- Treat AppleSMC keys and encodings as a hardware protocol to verify. Do not assume an Intel implementation or another M-series model has the same capabilities.
- Validate transport and hardware response status, payload size and encoding, finite values, units, and fan limits. Unknown or failed data is unavailable, not a fabricated reading.
- Distinguish a legitimate zero RPM reading from failed access. Do not label an arbitrary thermal zone as a CPU/GPU core without verified mapping.
- Attach freshness to samples. Bound polling, retries, and discovery work; release IOKit resources and cancel obsolete work. A cooling utility must avoid unnecessary CPU use and wakeups.

## Write Boundary

- Establish an explicit control design before implementing writes: supported modes, command validation, session lifetime, verification, and recovery on each failure path.
- Keep the UI unprivileged. The helper exposes only the necessary typed operations, such as setting a bounded target or restoring automatic control; never arbitrary shell commands or arbitrary SMC writes over XPC.
- Authenticate the connecting app using trusted code-signing identity. Do not trust a caller-supplied identity, process name, or PID alone. Validate every command again inside the helper.
- Read and validate hardware-reported limits before accepting a target. Missing, inconsistent, or stale limits disable manual control rather than trigger guessed defaults.
- Serialize control changes. Check both transport and hardware status, read back control mode/target where available, and observe RPM response before reporting verification. RPM may take time to settle; use bounded, documented tolerances.
- Default to automatic control. Manual control needs a bounded session or lease, with helper-owned recovery when the app disconnects or stops renewing it. Do not rely solely on a graceful app-quit callback.
- Design and verify recovery across app crashes, XPC interruption, helper restart, and sleep/wake. Revalidate capabilities after wake; do not replay stale targets blindly. Report failed restoration explicitly.
- Never disable Apple thermal protections, stop thermal services, or bypass OS security controls to make a write work. Keep control unavailable when the safe path is unverified.

## Logging

- Use `OSLog.Logger` with a stable subsystem and focused categories for lifecycle, monitoring, and control.
- Log connection failures, decoding failures, helper authorisation, control transitions, verification failures, and recovery outcomes at the owning boundary.
- Preserve useful error codes and safe operation context. Never log credentials, serial numbers, hardware UUIDs, or unrestricted hardware dumps; use privacy annotations for sensitive context.
- Rate-limit repeated polling errors and avoid logging every sample. Verify actual log delivery when changing logging behaviour.
