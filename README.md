# Mac Better Fan Control

A native, open-source macOS utility for seeing what your Mac’s cooling hardware is doing. Built with Swift 6, SwiftUI, and a small read-only IOKit adapter, with no third-party dependencies.

## Current state

**Live monitoring works. Fan control is not implemented yet.** The app reads real fan speeds and temperature channels without administrator privileges. It never changes fan settings or substitutes simulated readings when hardware access fails.

- Live measured RPM, hardware-reported targets, control modes, and fan limits.
- A plain-language overview of CPU, GPU, memory, battery, and other mapped components, showing the highest available reading in each group.
- Expandable component details and an advanced sensor list with names, hardware keys, search, favourites, and hottest-first sorting.
- A selectable temperature in the menu bar, plus fan readings and dashboard access from its menu.
- Saved Celsius/Fahrenheit, refresh interval, favourites, and menu sensor preferences.
- Pause/resume and reconnect, explicit stale/unavailable readings, and reconnection after wake.
- A resizable native dashboard that continues monitoring after its window is closed.

Component names use chip-specific community mappings; see [source attribution](THIRD_PARTY_NOTICES.md). Unknown sensor locations stay in **All sensors** as unidentified channels with their SMC keys. A manual fan mode reported by hardware may belong to another utility; it does not mean this app applied that setting.

The logo in `Resources/Logo.png` appears in the dashboard and menu bar and is also used as the T3 Code project icon. `Resources/AppIcon.icns` contains its macOS app icon sizes for Finder and the Dock.

## Requirements

- An Apple Silicon Mac running macOS 14 or later
- Swift 6 or later, available through Xcode or Apple Command Line Tools

There are no third-party dependencies.

## Run

```sh
./scripts/run.sh
```

This builds a development app bundle at `.build/Mac Better Fan Control.app`, applies an ad-hoc local signature, and opens it. Quit an older running build before running the script again. The menu bar entry can reopen the dashboard after its window is closed.

To compile without launching:

```sh
swift build
```

Open `Package.swift` in Xcode or edit the Swift sources in your preferred editor. Distribution signing, notarisation, and downloadable releases are not configured.

## Use

The default **Overview** shows named components. Expand a component for its individual sensor readings, or pin it to display its highest available temperature in the menu bar. These are measured temperatures, not a judgement that the Mac is safe or overheating.

In **All sensors**, search by name or key, star channels you want to keep, and use the star filter to see favourites. Select a sensor row and choose **Show in Menu Bar** to display that individual reading. **Clear** removes the menu-bar selection.

Open **Settings** to change temperature units or the polling interval (1, 2, 5, or 10 seconds; the default is 2). **Pause** retains the last sample with an explicit non-live label. **Reconnect** discards the previous sample and rediscovers hardware. Quit from the app or menu bar menu to stop monitoring.

## Hardware status

Read-only monitoring was verified on **Mac16,5 / Apple M4 Max / macOS 26.5.1** on 23 October 2026: two fans, reported limits of 1,350–5,777 RPM, and 338 valid temperature readings out of 356 discovered channels. Counts and values can change with device state. Inactive or invalid channels remain unavailable.

M1–M5, including Pro, Max, and Ultra variants, are a target range, **not a compatibility guarantee**. Other models, fanless detection on real hardware, and physical sleep/wake have not been verified. AppleSMC is a reverse-engineered interface that may vary across machines and macOS releases.

## Tests

```sh
swift build
swift test
```

Ordinary tests use synthetic input at the hardware boundary and never access or change hardware. They cover number decoding, malformed readings, freshness, fanless/error distinctions, settings persistence, cancelled sessions, and reconnects.

Run the separate, explicitly selected read-only check on a physical Mac:

```sh
MBF_LIVE_TEST=1 swift test --filter liveHardwareRead
```

It prints fan readings and a small temperature sample; it does not write to the SMC. A passing test establishes reading support on that machine only.

## Fan control roadmap

Fixed RPM, temperature curves, and saved control presets remain unimplemented. They require a narrowly scoped, authenticated privileged helper, hardware-validated limits, read-back verification, and recovery to automatic control after disconnect, crash, quit, and sleep/wake. Signing alone does not establish safe fan control.

See [hardware implementation and control design](docs/HARDWARE.md) for the current boundary, remaining prerequisites, and verification requirements. No test-mode unlocks, thermal-service shutdowns, or security bypasses are part of this design.

## Contributing

Read [AGENTS.md](AGENTS.md) and the relevant files in [rules/](rules/) before changing code. Keep changes small and preserve the distinction between measured readings and requested fan settings. Include the Mac model/chip and macOS version with hardware reports; exclude serial numbers and hardware UUIDs.

Build and run the tests before opening a pull request. UI changes also need a local app launch and interaction checks. Hardware changes need real-device evidence, not just successful compilation.

## License

[MIT](LICENSE).
