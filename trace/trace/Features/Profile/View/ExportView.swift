import SwiftUI
import SwiftData

/// 批量数据导出：把全部运动记录带走。
///
/// - **汇总 CSV**：每条运动一行（类型/起止/时长/距离/卡路里/配速/心率/爬升/备注），
///   适合在表格软件里查看或归档。
/// - **全部 GPX**：每条有轨迹的运动各一个标准 GPX 文件，可导入 Strava / Garmin
///   等其它运动 App（室内跑无轨迹，仅出现在汇总 CSV 里）。
///
/// 体现 trace 的初心：数据永远属于你，随时带得走。
struct ExportView: View {
    @Query(sort: \Workout.startDate, order: .reverse) private var workouts: [Workout]

    @State private var summaryURL: URL?
    @State private var gpxURLs: [URL] = []
    @State private var isBuilding = false

    private var gpxCount: Int {
        workouts.filter { !($0.samples ?? []).isEmpty }.count
    }

    var body: some View {
        Form {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "暂无可导出的记录",
                    systemImage: "square.and.arrow.up",
                    description: Text("先去『记录』页完成一次运动")
                )
            } else {
                Section {
                    if !gpxURLs.isEmpty {
                        ShareLink(items: gpxURLs) {
                            Label("导出全部轨迹 GPX（\(gpxURLs.count) 条）", systemImage: "map")
                        }
                    } else if gpxCount > 0 {
                        Label(isBuilding ? "正在生成轨迹 GPX…" : "准备轨迹 GPX…", systemImage: "map")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("暂无含 GPS 轨迹的运动", systemImage: "map")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("完整轨迹（GPX）")
                } footer: {
                    Text("含逐点经纬度、海拔与心率的完整路线，标准 WGS-84 坐标，"
                         + "可导入 Strava / Garmin 等。单条运动也可在其详情页右上角分享。"
                         + "室内跑无 GPS 轨迹，不在此列。")
                }

                Section {
                    if let summaryURL {
                        ShareLink(item: summaryURL) {
                            Label("导出汇总 CSV（\(workouts.count) 条）", systemImage: "tablecells")
                        }
                    } else {
                        Label("正在准备汇总 CSV…", systemImage: "tablecells")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("概览表格（CSV）")
                } footer: {
                    Text("每条运动一行的概览（类型/距离/时长/配速…），**不含轨迹点**，"
                         + "适合在表格软件里统计或归档。用米/秒等原始单位与 ISO8601 时间，便于再导入。")
                }
            }
        }
        .navigationTitle("数据导出")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: workouts.count) { await build() }
    }

    @MainActor
    private func build() async {
        guard !workouts.isEmpty else {
            summaryURL = nil; gpxURLs = []
            return
        }
        isBuilding = true
        defer { isBuilding = false }
        summaryURL = try? WorkoutExporter.summaryCSVFile(for: workouts)
        gpxURLs = (try? WorkoutExporter.gpxFiles(for: workouts)) ?? []
    }
}

#Preview {
    NavigationStack { ExportView() }
        .modelContainer(for: Workout.self, inMemory: true)
}
