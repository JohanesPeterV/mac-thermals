# Hardware implementation and control design

## Implemented: read-only monitoring

`SMCTransport` contains the fixed 80-byte AppleSMC C packet ABI, checks its size
and offsets at compilation, and exposes only open, close, metadata/read, and key
enumeration operations. It has no SMC write command. IOKit connection and payload
lifetimes stay inside this boundary.

`SMCReader` serializes access on a Swift actor, away from the main actor. It checks
transport status, SMC result/status, payload sizes, supported encodings, finite
values, fan count, RPM bounds, and thermal bounds. Discovery is limited to 16,384
keys and 512 temperature channels. Only `T` keys with `flt ` or `sp78` encodings
are admitted as thermal channels. Accepted temperatures are above 0 and at most
150 °C; zero/inactive channels are unavailable. Zero RPM and zero fans remain
valid, separate from failed queries. The RPM sanity ceiling is 30,000; it is not a
manual-control limit. Fan limits come from the hardware.

`SensorCatalog` associates exact keys with community-documented names for the
identified chip generation and variant. It does not infer core identity from key
prefixes. The overview takes the maximum of available mapped readings in each
component and displays the available/total sensor count. Unmapped keys never
contribute to CPU/GPU summaries; they remain in the advanced list. A component
with no valid readings stays unavailable. Sources and the upstream MIT notice
are in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

One app-owned `MonitorModel` supplies the dashboard and menu. It cancels old
polling, waits for cleanup before reconnecting, and ignores obsolete results.
Snapshots become stale after the greater of 5 seconds or 2.5 polling intervals;
errors and pause invalidate live status immediately. Future timestamps are not
live. A separate lightweight clock checks freshness while a hardware read awaits.
Connection failures retry no faster than every 5 seconds. Wake rediscovers
capabilities without replaying control state. Logs record lifecycle and changes
in failure state, not every sample or an unrestricted hardware dump.

The protocol reference is the open-source
[Stats SMC implementation](https://github.com/exelban/stats/blob/master/SMC/smc.swift).
This is a reverse-engineered protocol, not a documented Apple sensor API. The app
does not depend on or bundle Stats. Apple's public IOKit API supplies transport.

## Not implemented: privileged fan control

The current build has no helper, fan-write interface, fixed-speed control,
temperature curves, or control presets. Display settings are not control presets.
The following is the design gate for that work, not a description of shipped code.

1. Package a separate privileged helper using
   [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice).
   Authenticate both XPC peers with
   [code-signing requirements](https://developer.apple.com/documentation/foundation/nsxpcconnection/setcodesigningrequirement(_:))
   anchored to the trusted signing team and exact bundle identifiers. A caller's
   PID, supplied name, or bundle identifier alone is insufficient.
2. Expose typed operations for bounded per-fan targets, lease renewal, status, and
   restoration. Never expose arbitrary SMC keys, files, or shell commands. Validate
   fresh hardware limits, identifiers, finite targets, and session ownership again
   inside the helper. Refuse takeover of an existing externally controlled fan.
3. Begin from automatic mode. Use a helper-owned monotonic lease, renewed by the
   app, and serialize commands. Record owned manual sessions durably before any
   write so helper restart can attempt recovery. Do not reapply old targets at launch.
4. Verify mode and target read-back plus measured RPM response within a bounded
   settling window before calling a setting applied. Define and record the
   tolerance and timeout for the actual verified model. Restore automatic on a
   failed change, expired lease, XPC loss, thermal emergency, or invalid sensor.
   Never blindly resume manual mode after wake.
5. Verify automatic → manual → automatic and app/helper crash, connection loss,
   invalid commands, quit, sleep, and wake on each supported hardware path. Surface
   recovery failures. Never claim recovery based only on a successful XPC reply.
6. Only then enable fixed RPM, validated monotonic temperature curves, and saved
   presets. Persisted preferences never prove an active control session. Missing
   curve sensors must recover to automatic, not retain an old target.

The design excludes `Ftst` test-mode unlocking, disabling thermal services,
disabling system thermal protections, and bypassing security controls. If the
target Mac cannot be controlled without those operations, manual control remains
unsupported.

## Signing setup

Read-only development works with the ad-hoc signature produced by `scripts/run.sh`.
No paid account or administrator access is needed for monitoring.

For Apple development signing, install Xcode and add your Apple Account under
**Xcode → Settings → Accounts**. Select your team, open **Manage Certificates**,
and create **Apple Development**. Xcode manages the certificate and its private
key in your local Keychain. A free account can use a Personal Team for local
development, subject to Apple's restrictions; it does not establish that helper
registration and recovery work. See
[Apple's certificate guide](https://developer.apple.com/documentation/xcode/sharing-your-teams-signing-certificates).

Distributing a signed, notarised app outside the App Store requires the appropriate
Developer ID identity and Apple Developer Program membership. The current run
script does not build, sign, register, or approve a privileged helper. Do not
replace this missing implementation with a root launch of the UI process.
