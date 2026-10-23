# Mac Better Fan Control

A native macOS fan and temperature utility, starting with a small SwiftUI app.

## Current state

The starter includes a resizable dashboard, a menu bar entry, and local build and launch commands. Sensor readings, fan writes, and saved presets are not implemented. Empty states explicitly show that hardware access is pending; the app does not display simulated readings or change fan settings.

## Requirements

- macOS 14 or later
- Swift 6 or later, available through Xcode or Apple Command Line Tools

There are no third-party dependencies.

## Run

```sh
./scripts/run.sh
```

This builds a development app bundle at `.build/Mac Better Fan Control.app`, signs it locally, and opens it. The menu bar entry can reopen the dashboard after its window is closed.

To compile without launching:

```sh
swift build
```

Open `Package.swift` in Xcode to work on the package there, or edit the Swift sources in your preferred editor. The initial bundle is for local development; distribution signing and notarisation are not configured.

## Next implementation steps

1. Discover the local Mac’s fans and sensors through a read-only hardware adapter; verify the results on that machine.
2. Show live RPM and temperature values with explicit unavailable and error states.
3. Implement fan writes through a narrowly scoped privileged helper, including hardware-reported limits and recovery to automatic control on failure, quit, and sleep/wake.
4. Add fixed RPM settings, temperature curves, and saved presets after the hardware path is verified.

Hardware support must be verified per Mac model and macOS version. A running interface does not establish hardware compatibility.
