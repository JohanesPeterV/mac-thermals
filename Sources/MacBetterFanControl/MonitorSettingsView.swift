import SwiftUI

struct MonitorSettingsView: View {
    @Bindable var settings: MonitorSettings

    var body: some View {
        Form {
            Picker("Temperature unit", selection: $settings.unit) {
                Text("Celsius (°C)").tag(TemperatureUnit.celsius)
                Text("Fahrenheit (°F)").tag(TemperatureUnit.fahrenheit)
            }
            Picker("Refresh interval", selection: $settings.interval) {
                ForEach(MonitorSettings.intervals, id: \.self) { interval in
                    Text("\(interval) \(interval == 1 ? "second" : "seconds")").tag(interval)
                }
            }
            Text("Monitoring continues when the dashboard is closed. Your temperature unit, interval, and favourite sensors are saved on this Mac.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Section("Fan control") {
                Text("This build monitors your fans without changing their settings. Manual speeds and temperature curves are unavailable until a verified control helper is installed.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 440)
    }
}
