import SwiftUI
import SwiftData
import CoreLocation
import Charts

/// 单条运动详情：轨迹地图 + 汇总 + 每公里配速图 + 海拔图 + 备注，室内可手动校正距离。
struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    @Query private var profiles: [UserProfile]

    private var unit: UnitPreference { profiles.first?.unit ?? .metric }
    private var mapStyle: MapStylePreference { profiles.first?.mapStyle ?? .standard }

    private var samples: [RouteSample] {
        (workout.samples ?? []).sorted { $0.timestamp < $1.timestamp }
    }
    private var coordinates: [CLLocationCoordinate2D] {
        samples.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    private var sortedSplits: [Split] {
        (workout.splits ?? []).sorted { $0.index < $1.index }
    }

    @State private var gpxURL: URL?
    @State private var sampleCSVURL: URL?

    var body: some View {
        List {
            if coordinates.count > 1 {
                RouteMapView(coordinates: coordinates, style: mapStyle)
                    .frame(height: 240)
                    .listRowInsets(EdgeInsets())
            } else if workout.activityType.usesGPS {
                ContentUnavailableView {
                    Label("没有轨迹", systemImage: "map")
                } description: {
                    Text("这次没记录到 GPS 轨迹。请确认定位权限已开启；模拟器需用 Features → Location 模拟移动后再跑。")
                }
                .frame(height: 200)
            }

            summarySection
            if !sortedSplits.isEmpty { paceChartSection }
            if samples.count > 1 { elevationChartSection }
            if !sortedSplits.isEmpty { splitsSection }
            noteSection
            if workout.activityType == .indoorRun { manualSection }
        }
        .navigationTitle(workout.activityType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if gpxURL != nil || sampleCSVURL != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let gpxURL {
                            ShareLink(item: gpxURL) {
                                Label("导出 GPX 轨迹", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            }
                        }
                        if let sampleCSVURL {
                            ShareLink(item: sampleCSVURL) {
                                Label("导出明细 CSV", systemImage: "tablecells")
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .task(id: workout.persistentModelID) { generateExports() }
    }

    /// 生成可分享的导出文件。没有轨迹点（如室内跑）则不提供单条导出，
    /// 这类记录可在「我的 → 数据导出」里随汇总 CSV 一起带走。
    private func generateExports() {
        guard !samples.isEmpty else {
            gpxURL = nil; sampleCSVURL = nil
            return
        }
        gpxURL = try? WorkoutExporter.gpxFile(for: workout)
        sampleCSVURL = try? WorkoutExporter.sampleCSVFile(for: workout)
    }

    // MARK: - 汇总

    private var summarySection: some View {
        Section("汇总") {
            LabeledContent("距离", value: Formatters.distance(workout.distance, unit: unit))
            LabeledContent("时长", value: Formatters.duration(workout.duration))
            if workout.activityType.prefersSpeed {
                LabeledContent("平均速度",
                    value: Formatters.speed(metersPerSecond: workout.averageSpeed, unit: unit))
            } else {
                LabeledContent("平均配速",
                    value: Formatters.pace(secondsPerKm: workout.averagePace, unit: unit))
            }
            LabeledContent("卡路里", value: String(format: "%.0f kcal", workout.calories))
            if workout.activityType.usesGPS {
                // 户外活动一律展示，平地跑会是 0 m，避免用户疑惑"字段哪去了"
                LabeledContent("累计爬升", value: String(format: "%.0f m", workout.elevationGain))
            }
            if workout.averageHeartRate > 0 {
                LabeledContent("平均心率", value: String(format: "%.0f bpm", workout.averageHeartRate))
            }
        }
    }

    // MARK: - 配速图

    private var paceChartSection: some View {
        Section("每公里配速") {
            Chart(sortedSplits) { split in
                BarMark(
                    x: .value("公里", split.index),
                    y: .value("配速(秒)", split.pace)
                )
                .foregroundStyle(.blue)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) { Text(paceShort(seconds)) }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: sortedSplits.map(\.index)) { value in
                    AxisValueLabel {
                        if let km = value.as(Int.self) { Text("\(km)") }
                    }
                }
            }
            .frame(height: 180)
        }
    }

    // MARK: - 海拔图

    private var elevationChartSection: some View {
        Section("海拔") {
            Chart(samples) { sample in
                AreaMark(
                    x: .value("时间", sample.timestamp),
                    y: .value("海拔", sample.altitude)
                )
                .foregroundStyle(.green.opacity(0.25))
                LineMark(
                    x: .value("时间", sample.timestamp),
                    y: .value("海拔", sample.altitude)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 150)
        }
    }

    // MARK: - 分段

    private var splitsSection: some View {
        Section("分段配速") {
            ForEach(sortedSplits) { split in
                HStack {
                    Text("第 \(split.index) 公里")
                    Spacer()
                    Text(Formatters.pace(secondsPerKm: split.pace, unit: unit))
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - 备注 / 手动校正

    private var noteSection: some View {
        Section("备注") {
            TextField("写点什么…", text: $workout.note, axis: .vertical)
                .lineLimit(1...5)
        }
    }

    private var manualSection: some View {
        Section {
            HStack {
                Text("距离（\(unit == .metric ? "公里" : "英里")）")
                Spacer()
                TextField("距离", value: distanceBinding, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("手动校正")
        } footer: {
            Text("跑步机没有 GPS，可在此填写实际距离，平均配速会自动重算。")
        }
    }

    // MARK: - Helpers

    private var distanceBinding: Binding<Double> {
        let factor = unit == .metric ? 1000.0 : 1609.344
        return Binding(
            get: { workout.distance / factor },
            set: { newValue in
                workout.distance = newValue * factor
                workout.averagePace = workout.distance > 0
                    ? workout.duration / (workout.distance / 1000) : 0
            }
        )
    }

    private func paceShort(_ secondsPerKm: Double) -> String {
        guard secondsPerKm > 0 else { return "" }
        return String(format: "%d:%02d", Int(secondsPerKm) / 60, Int(secondsPerKm) % 60)
    }
}
