# SwiftUI And Product Design

## Native Interface

- Prefer native controls, system typography, semantic colours, SF Symbols, and standard macOS menus and keyboard shortcuts.
- Keep the dashboard readable as composition: connection state, fans, temperatures, and relevant actions. Use tables or aligned rows for comparable readings instead of a card for every value.
- Use clear labels, visible units, and monospaced digits for changing measurements. Keep meaning available without colour or hover.
- Support window resizing, light and dark appearance, keyboard navigation, VoiceOver labels, and reduced motion. Use AppKit only for a specific native behaviour.

## State Ownership

- Use `@State` for local UI state and ownership of observable models, `@Binding` for edits owned elsewhere, and Observation for shared app state.
- Derive inexpensive display values directly. Do not copy readings into view state or add observation callbacks just to keep duplicate values in sync.
- Keep side effects out of `body`. Tie view-specific async work to a cancellable lifecycle; keep shared monitoring in its app-level owner.
- Pass only the values and actions a child needs. Extract a model or subview for a real responsibility, not to conceal a large workflow.

## Truthful Feedback

- Distinguish connecting, live, stale, unavailable, unsupported, and failed states. Missing readings are not zero; preserve a last reading only with clear stale status.
- Detect fanless hardware and explain that only temperature monitoring is available. A failed fan query must not be reported as a fanless Mac.
- Show measured RPM separately from a requested target. Use pending and verification states while a change is being applied; a successful request is not a verified result.
- Keep automatic mode and the recovery action easy to find. Disable unavailable control actions with a useful explanation.
- Keep validation and operation errors next to the affected control, with retry where meaningful. Preserve preset edits after failed saves.
- Closing the dashboard, reopening it from the menu bar, and quitting the app are distinct actions; make their behaviour consistent with the control lifecycle.

Verify meaningful interaction changes in the running app using [Testing](TESTING.md). Previews alone do not establish runtime behaviour.
