# Architecture

## Stack And Scope

- Build a native Apple Silicon app with Swift 6 and SwiftUI. Use AppKit for concrete lifecycle or window behaviour SwiftUI cannot express cleanly.
- Keep the macOS 14 minimum from `Package.swift`; gate newer APIs and provide a working fallback on the minimum supported OS.
- Use Swift Package Manager for code and tests. Add app/helper targets and signing configuration when packaging requires them, not as speculative scaffolding.
- Prefer Apple frameworks. Add a third-party dependency only when its benefit outweighs its maintenance and distribution cost.

## Ownership

- Views compose controls and render state. They do not decode sensors, choose fan limits, implement curves, or call IOKit/XPC directly.
- An app-owned observable model exposes monitoring and control state to both the dashboard and menu bar. Keep UI state on the main actor.
- Plain Swift types and functions own validation, unit conversion, presets, and curve calculations. Keep them independent of SwiftUI and hardware IO.
- A hardware adapter owns AppleSMC/IOKit access, decoding, capability discovery, resource lifetime, and validated readings. Serialize hardware operations and keep blocking IO off the main actor.
- A separate privileged helper owns fan writes and control recovery. Communicate through a narrow typed XPC interface; register the helper through ServiceManagement (`SMAppService`). See [Hardware](HARDWARE.md).
- Keep monitoring lifetime explicit at app level. Opening a second surface must not create another polling loop; closing the dashboard must not accidentally end menu bar monitoring.

These are responsibility boundaries, not a requirement to create a package, protocol, or folder for every layer. Start within the existing `Sources/MacBetterFanControl` target and extract only when a real boundary needs it.

## State And Persistence

- Keep measured RPM, requested targets, verified control mode, and unsaved edits distinct. Derive display values from the owning state instead of synchronising copies.
- Use `UserDefaults` for small preferences and `Codable` for structured presets. Validate decoded values and handle missing or incompatible settings explicitly.
- Saved manual settings are preferences, not proof of active control. Revalidate hardware capabilities and establish a verified control session before applying them.
- Use a replaceable hardware boundary for tests and previews. Simulated data must be explicitly labelled and must never become a live fallback.
