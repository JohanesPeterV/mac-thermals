# Clean Code

## Types And Boundaries

- Prefer concrete types, structs for values, enums for modes and operation states, and the narrowest access level needed.
- Validate external data where it enters: SMC responses, XPC messages, and persisted presets. Reject non-finite numbers, malformed payloads, and invalid identifiers before they reach control logic.
- Do not use force unwraps, `try!`, or forced casts for external data. Do not use `try?` to hide an operational failure; model expected absence explicitly.
- Avoid `Any` and type erasure unless an Apple API boundary requires them. Narrow immediately at that boundary.
- Do not add `@unchecked Sendable`, `nonisolated(unsafe)`, or unsafe memory operations merely to make compilation pass. Necessary interop belongs in the hardware adapter with a documented layout, lifetime, and synchronisation contract.

## Code Shape

- Give each type and function one clear responsibility. Extract by responsibility, not an arbitrary line count.
- Keep single-use logic local when extraction only adds indirection. Search for an existing owner before introducing helpers or wrappers.
- Prefer named modes over boolean parameters that select behaviour. Use ordinary booleans for actual yes/no state and native SwiftUI APIs.
- Avoid nested ternaries, deeply nested branching, generic manager objects, and speculative abstraction. Use early exits and meaningful names.
- Use Swift naming conventions and explicit units where ambiguity matters, such as `temperatureCelsius` and `targetRPM`.
- Keep comments focused on why a constraint exists. Use `// REASON:` for non-obvious hardware or lifecycle decisions; preserve required license headers, tool directives, and useful API documentation.

## Errors And Concurrency

- Propagate unexpected errors or return an explicit failure the caller handles. Logging alone does not make an operation successful.
- Use structured concurrency with clear task ownership and cancellation. Do not launch detached or unbounded work from view rendering.
- Handle cancellation separately from hardware failure. Recheck session validity after suspension before applying a control decision.
- Fix relevant dead code and duplication exposed by the change; leave unrelated cleanup for follow-up work.
