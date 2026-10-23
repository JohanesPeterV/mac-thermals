import SwiftUI

struct MonitorView: View {
    let model: MonitorModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(nsImage: AppLogo.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mac Better Fan Control")
                        .font(.title2.bold())
                    Text("A clearer view of your Mac’s cooling.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(model.status, systemImage: model.isLive ? "checkmark.circle" : "circle.dotted")
                    .foregroundStyle(model.isLive ? .green : .secondary)
                    .font(.callout)
            }

            if let error = model.error {
                HStack {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Spacer()
                    Button("Retry") { model.restart() }
                }
                .font(.callout)
            }

            HStack(alignment: .top, spacing: 16) {
                fansPanel
                    .frame(minWidth: 260, idealWidth: 320, maxWidth: 360)
                TemperaturePanel(model: model)
            }

            HStack {
                if let sample = model.snapshot {
                    Text("\(model.isLive ? "Updated" : "Last sample") \(sample.sampledAt.formatted(date: .omitted, time: .standard))")
                }
                Spacer()
                Button(model.isPaused ? "Resume" : "Pause") {
                    if model.isPaused { model.restart() } else { model.pause() }
                }
                Button("Reconnect", systemImage: "arrow.clockwise") { model.restart() }
                    .keyboardShortcut("r", modifiers: .command)
                SettingsLink { Image(systemName: "gearshape") }
                    .help("Settings")
                    .accessibilityLabel("Settings")
            }
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 500)
    }

    private var fansPanel: some View {
        GroupBox("Fans") {
            VStack(alignment: .leading, spacing: 16) {
                if let snapshot = model.snapshot {
                    if let issue = snapshot.fanIssue {
                        ContentUnavailableView("Fans unavailable", systemImage: "fan", description: Text(issue))
                    } else if snapshot.fans.isEmpty {
                        ContentUnavailableView("No fans detected", systemImage: "fan.slash", description: Text("This Mac reports no fans. Temperature monitoring is still available."))
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(snapshot.fans) { fan in
                                    FanRow(fan: fan, isLive: model.isLive)
                                    if fan.id != snapshot.fans.last?.id { Divider() }
                                }
                            }
                            .padding(8)
                        }
                    }
                } else {
                    connectionPlaceholder("Reading fans…")
                }
                Divider()
                Label("Monitoring only", systemImage: "eye")
                    .font(.headline)
                Text("Fan settings are managed outside this app. Manual control is unavailable in this build.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func connectionPlaceholder(_ message: String) -> some View {
        VStack(spacing: 12) {
            if model.isRefreshing { ProgressView().controlSize(.small) }
            Text(model.isPaused ? "Monitoring paused" : model.error == nil ? message : "Connection unavailable")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FanRow: View {
    let fan: FanReading
    let isLive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(fan.name, systemImage: "fan")
                    .font(.headline)
                Spacer()
                Text(fan.speed.value.map(formattedRPM) ?? "Unavailable")
                    .font(.title2.bold())
                    .monospacedDigit()
                    .help(fan.speed.issue ?? "Measured fan speed")
            }
            if !isLive { Text("Last reading · not live").font(.caption).foregroundStyle(.secondary) }
            if let limits = fan.limits {
                if let speed = fan.speed.value {
                    ProgressView(value: min(speed, limits.upperBound), total: limits.upperBound)
                        .accessibilityLabel("\(fan.name) measured speed")
                        .accessibilityValue(formattedRPM(speed))
                }
                Text("Range: \(formattedRPM(limits.lowerBound)) – \(formattedRPM(limits.upperBound))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Fan limits unavailable").font(.caption).foregroundStyle(.secondary)
            }
            Text(fan.modeLabel).font(.callout)
            Text("Hardware target: \(fan.target.value.map(formattedRPM) ?? "Unavailable")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
