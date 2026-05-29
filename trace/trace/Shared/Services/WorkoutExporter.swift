import Foundation

/// 把运动记录导出成可移植的标准格式：GPX（轨迹）/ CSV（明细、汇总）。
///
/// 设计目标是「数据带得走」：导出文件用通用格式，能导入 Strava / Garmin /
/// 其它运动 App，或长期归档。
///
/// **坐标系**：导出一律用存储层的原始 **WGS-84** 经纬度（GCJ-02 只在大陆地图
/// 显示时临时转换，绝不写进存储，也不写进导出），这样轨迹在任何标准工具里都不偏移。
///
/// 字符串构造方法是纯函数、易测试；`*File` 方法把内容写到临时目录并返回 URL，
/// 供 SwiftUI 的 `ShareLink` 直接分享。
enum WorkoutExporter {

    // MARK: - 公开：生成可分享的文件 URL

    /// 单条运动的 GPX 文件（轨迹点含海拔与心率扩展）。
    static func gpxFile(for workout: Workout) throws -> URL {
        try write(gpxString(for: workout), filename: filename(for: workout, ext: "gpx"))
    }

    /// 单条运动的逐点明细 CSV（每个采样点一行）。
    static func sampleCSVFile(for workout: Workout) throws -> URL {
        try write(sampleCSVString(for: workout), filename: filename(for: workout, ext: "csv"))
    }

    /// 全部运动的汇总 CSV（每条运动一行）。
    static func summaryCSVFile(for workouts: [Workout]) throws -> URL {
        try write(summaryCSVString(for: workouts), filename: "trace-汇总-\(stamp(.now)).csv")
    }

    /// 全部有轨迹的运动各导出一个 GPX 文件，返回 URL 列表（供批量分享）。
    /// 没有采样点的运动（如室内跑）会被跳过。
    static func gpxFiles(for workouts: [Workout]) throws -> [URL] {
        try workouts
            .filter { !( $0.samples ?? [] ).isEmpty }
            .map { try gpxFile(for: $0) }
    }

    // MARK: - GPX

    static func gpxString(for workout: Workout) -> String {
        let samples = sortedSamples(workout)
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="trace" \
        xmlns="http://www.topografix.com/GPX/1/1" \
        xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">
          <metadata>
            <time>\(iso(workout.startDate))</time>
          </metadata>
          <trk>
            <name>\(xmlEscape(workout.activityType.title)) \(displayDate(workout.startDate))</name>
            <type>\(gpxType(workout.activityType))</type>
            <trkseg>

        """
        for s in samples {
            xml += "      <trkpt lat=\"\(coord(s.latitude))\" lon=\"\(coord(s.longitude))\">\n"
            xml += "        <ele>\(String(format: "%.1f", s.altitude))</ele>\n"
            xml += "        <time>\(iso(s.timestamp))</time>\n"
            if s.heartRate > 0 {
                xml += "        <extensions>\n"
                xml += "          <gpxtpx:TrackPointExtension>\n"
                xml += "            <gpxtpx:hr>\(Int(s.heartRate))</gpxtpx:hr>\n"
                xml += "          </gpxtpx:TrackPointExtension>\n"
                xml += "        </extensions>\n"
            }
            xml += "      </trkpt>\n"
        }
        xml += """
            </trkseg>
          </trk>
        </gpx>
        """
        return xml
    }

    // MARK: - CSV

    /// 逐点明细：时间戳、经纬度、海拔、速度、心率（全为 SI 原始量，便于再导入）。
    static func sampleCSVString(for workout: Workout) -> String {
        var rows = ["timestamp,latitude,longitude,altitude_m,speed_mps,heart_rate_bpm"]
        for s in sortedSamples(workout) {
            rows.append([
                iso(s.timestamp),
                coord(s.latitude),
                coord(s.longitude),
                String(format: "%.1f", s.altitude),
                String(format: "%.2f", s.speed),
                String(format: "%.0f", s.heartRate)
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    /// 汇总：每条运动一行。距离用米、时长用秒、配速用秒/公里，日期用 ISO8601（UTC），
    /// 都是稳定的机器可读量，方便归档或再次导入。
    static func summaryCSVString(for workouts: [Workout]) -> String {
        var rows = ["type,start,end,duration_s,distance_m,calories_kcal,"
                    + "avg_pace_s_per_km,avg_hr_bpm,max_hr_bpm,elevation_gain_m,note"]
        for w in workouts.sorted(by: { $0.startDate < $1.startDate }) {
            rows.append([
                w.activityType.rawValue,
                iso(w.startDate),
                iso(w.endDate),
                String(format: "%.0f", w.duration),
                String(format: "%.1f", w.distance),
                String(format: "%.1f", w.calories),
                String(format: "%.1f", w.averagePace),
                String(format: "%.0f", w.averageHeartRate),
                String(format: "%.0f", w.maxHeartRate),
                String(format: "%.1f", w.elevationGain),
                csvField(w.note)
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    // MARK: - 私有工具

    private static func sortedSamples(_ workout: Workout) -> [RouteSample] {
        (workout.samples ?? []).sorted { $0.timestamp < $1.timestamp }
    }

    private static func gpxType(_ type: ActivityType) -> String {
        switch type {
        case .outdoorRun, .indoorRun: "running"
        case .cycling:                "cycling"
        case .walking:                "walking"
        }
    }

    /// 经纬度保留 6 位小数（约 0.1m 精度），足够且不冗长。
    private static func coord(_ value: Double) -> String { String(format: "%.6f", value) }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static func iso(_ date: Date) -> String { isoFormatter.string(from: date) }

    /// 文件名/标题里用的本地日期，如 "2026-05-30 08:30"
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()
    private static func displayDate(_ date: Date) -> String { displayFormatter.string(from: date) }

    /// 文件名里用的紧凑时间戳，如 "20260530-0830"
    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmm"
        return f
    }()
    private static func stamp(_ date: Date) -> String { stampFormatter.string(from: date) }

    private static func filename(for workout: Workout, ext: String) -> String {
        "trace-\(workout.activityType.title)-\(stamp(workout.startDate)).\(ext)"
    }

    /// CSV 字段转义：含逗号/引号/换行时用双引号包裹，内部双引号翻倍。
    private static func csvField(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" })
        else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func xmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// 把内容写到临时目录下的 trace-export 子目录，返回文件 URL。
    private static func write(_ contents: String, filename: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("trace-export", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(filename)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
