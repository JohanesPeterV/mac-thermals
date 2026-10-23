# Testing And Verification

## Choose Proof For The Change

- Text-only docs and agent rules: inspect content, references, and `git diff --check`. No app build, launch, or specialist review is needed.
- Swift code or package changes: run `swift build` and the focused tests for affected logic.
- Views and interaction: also run `./scripts/run.sh` and exercise the changed task in the native app. Check relevant pending, failure, retry, and unavailable states, keyboard access, resizing, and appearance.
- Packaging or launch scripts: exercise the built app bundle and changed launch path. A successful `swift build` alone does not verify bundle resources, signing, or helper registration.
- Hardware or control: add real-device checks for the affected path. Keep ordinary unit tests independent of privileges and hardware writes; make hardware tests explicitly selected.

The starter has no test target. Add a Swift Testing target under `Tests/` when introducing testable behaviour, then use `swift test` or `swift test --filter <test-name>`. Do not claim a test suite ran when none exists. Use XCTest/XCUITest for app automation when an actual UI test target is configured.

## Meaningful Tests

For each test, identify the claim, a realistic challenge, the observable failure, and the defect it would catch. Derive expected values independently of the implementation.

- Test the lowest responsible boundary. Use pure tests for decoding, limits, curves, and presets; fake the hardware/XPC boundary for lifecycle and failure scenarios.
- Challenge malformed payloads, NaN/infinity, absent sensors, legitimate zero RPM, invalid limits, stale readings, rejected writes, retries, and interrupted sessions where relevant.
- Verify user-visible results and durable settings rather than private method calls or a copy of the implementation.
- Do not add tests solely for reversible copy or tiny visual changes. Do not weaken meaningful assertions or skip failures to get a green result.

## Real-Device Evidence

- Record the commit, Mac model/chip, macOS version, operation, observed result, and remaining limits without serial numbers or hardware UUIDs.
- Verify readings and control through the real adapter/helper path. Mocks, screenshots, successful IPC, and compilation do not prove hardware compatibility.
- For control changes, verify automatic → manual → automatic, rejected inputs, connection loss, and relevant quit/crash/sleep/wake recovery on the target machine. Verify restoration before ending the session.
- Keep fanless detection, sensor-read support, and fan-write support separate. Report unavailable machines and untested combinations explicitly; do not advertise M1–M5 support based on a single device.

## Review And Reporting

- Review a stable owned diff once for high-risk changes: unsafe interop, privileges/XPC, fan writes, lifecycle recovery, persistence, packaging/signing, and larger behaviour changes.
- Review correctness, security, ownership, duplication, and affected consumers. Fix concrete issues and rerun affected checks; repeat review only when the fix materially changes the design.
- Report build, tests, native interaction, hardware, and distribution evidence separately. Missing prerequisites are a verification gap, not a pass.
