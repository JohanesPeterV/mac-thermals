import SwiftUI

struct TemperaturePanel: View {
    let model: MonitorModel
    @State private var tab = SensorTab.overview
    @State private var search = ""
    @State private var favoritesOnly = false
    @State private var hottestFirst = false
    @State private var selectedSensor: String?

    private enum SensorTab: String, CaseIterable {
        case overview = "Overview"
        case all = "All sensors"
    }

    private var visibleSensors: [TemperatureReading] {
        let sensors = (model.snapshot?.temperatures ?? []).filter {
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.id.localizedCaseInsensitiveContains(search))
                && (!favoritesOnly || model.settings.favoriteSensors.contains($0.id))
        }
        return sensors.sorted {
            if hottestFirst, $0.temperature.value != $1.temperature.value {
                return ($0.temperature.value ?? -.infinity) > ($1.temperature.value ?? -.infinity)
            }
            if $0.name != $1.name { return $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return $0.id < $1.id
        }
    }

    var body: some View {
        GroupBox("Temperatures") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Temperature view", selection: $tab) {
                    ForEach(SensorTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if let snapshot = model.snapshot {
                    if let issue = snapshot.sensorIssue, snapshot.temperatures.isEmpty {
                        ContentUnavailableView("Sensors unavailable", systemImage: "thermometer", description: Text(issue))
                    } else if tab == .overview {
                        overview
                    } else {
                        allSensors
                    }
                } else {
                    VStack(spacing: 12) {
                        if model.isRefreshing { ProgressView().controlSize(.small) }
                        Text(model.status).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.summaries.isEmpty {
                ContentUnavailableView("Sensor names unavailable", systemImage: "thermometer", description: Text("This Mac’s temperature sensors have not been mapped yet. You can still inspect their readings in All sensors."))
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(model.summaries) { summary in
                            DisclosureGroup {
                                ForEach(summary.sensors) { sensor in
                                    HStack {
                                        Text(sensor.name)
                                        Spacer()
                                        Text(sensor.temperature.value.map(model.settings.unit.formatted) ?? "Unavailable")
                                            .monospacedDigit()
                                    }
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 3)
                                    .help("\(sensor.id)\(sensor.temperature.issue.map { ": \($0)" } ?? "")")
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: summary.group.symbol)
                                        .font(.title2)
                                        .frame(width: 26)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(summary.group.name).font(.headline)
                                        Text(summary.group.detail).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 4)
                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text(summary.maximum.map(model.settings.unit.formatted) ?? "Unavailable")
                                            .font(.title2.weight(.semibold))
                                            .monospacedDigit()
                                        Text("\(model.isLive ? "Highest" : "Last highest") · \(summary.availableCount)/\(summary.sensors.count) \(summary.sensors.count == 1 ? "sensor" : "sensors")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Button {
                                        model.settings.menuSensor = model.settings.menuSensor == summary.group.menuID ? "" : summary.group.menuID
                                    } label: {
                                        Image(systemName: model.settings.menuSensor == summary.group.menuID ? "pin.fill" : "pin")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Show \(summary.group.name) in the menu bar")
                                    .accessibilityLabel("\(model.settings.menuSensor == summary.group.menuID ? "Remove" : "Show") \(summary.group.name) \(model.settings.menuSensor == summary.group.menuID ? "from" : "in") the menu bar")
                                }
                            }
                            if summary.id != model.summaries.last?.id { Divider() }
                        }
                    }
                    .padding(6)
                }
            }
            Text("Highest available reading per component. Expand a row for individual sensors, or pin a component to the menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var allSensors: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Search names or sensor keys", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Search temperature sensors")
                Toggle(isOn: $favoritesOnly) { Image(systemName: "star.fill") }
                    .toggleStyle(.button)
                    .help("Show favourites only")
                    .accessibilityLabel("Show favourites only")
            }
            Toggle("Hottest first", isOn: $hottestFirst).font(.callout)
            if visibleSensors.isEmpty {
                ContentUnavailableView("No matching sensors", systemImage: "magnifyingglass", description: Text("Try another name or turn off the favourites filter."))
            } else {
                Table(visibleSensors, selection: $selectedSensor) {
                    TableColumn("") { sensor in
                        Button {
                            model.settings.toggleFavorite(sensor.id)
                        } label: {
                            Image(systemName: model.settings.favoriteSensors.contains(sensor.id) ? "star.fill" : "star")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("\(model.settings.favoriteSensors.contains(sensor.id) ? "Remove" : "Add") \(sensor.name) \(sensor.id) \(model.settings.favoriteSensors.contains(sensor.id) ? "from" : "to") favourites")
                    }
                    .width(24)
                    TableColumn("Sensor") { sensor in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sensor.name)
                            Text(sensor.id).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                    TableColumn(model.isLive ? "Temperature" : "Temperature (last)") { sensor in
                        Text(sensor.temperature.value.map(model.settings.unit.formatted) ?? "Unavailable")
                            .monospacedDigit()
                            .help(sensor.temperature.issue ?? sensor.name)
                    }
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
            }
            HStack {
                Button("Show in Menu Bar") {
                    if let selectedSensor { model.settings.menuSensor = selectedSensor }
                }
                .disabled(selectedSensor == nil || !visibleSensors.contains { $0.id == selectedSensor })
                if !model.settings.menuSensor.isEmpty {
                    Button("Clear") { model.settings.menuSensor = "" }
                        .help("Remove the temperature from the menu bar")
                }
                Spacer()
                Text("\(visibleSensors.count) \(visibleSensors.count == 1 ? "sensor" : "sensors")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Unidentified sensors are kept here until their component mapping is known.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
