import SwiftUI

struct MonitorView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "fan")
                    .font(.system(size: 38))
                    .foregroundStyle(.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mac Better Fan Control")
                        .font(.title2.bold())
                    Text("A clearer view of your Mac’s cooling.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("Not connected", systemImage: "circle.dotted")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }

            HStack(alignment: .top, spacing: 16) {
                GroupBox {
                    ContentUnavailableView {
                        Label("Fan access pending", systemImage: "fan")
                    } description: {
                        Text("Fan speeds and controls will appear here once hardware access is connected.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    Text("Fans")
                }

                GroupBox {
                    ContentUnavailableView {
                        Label("Sensor access pending", systemImage: "thermometer.medium")
                    } description: {
                        Text("Live temperature readings will appear here once sensors are connected.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } label: {
                    Text("Temperature sensors")
                }
            }

            Label("This starter app does not change fan settings.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 460)
    }
}
