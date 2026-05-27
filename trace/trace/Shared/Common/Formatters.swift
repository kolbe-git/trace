import Foundation

/// 集中式格式化：距离存米、时长存秒、配速存"秒/公里"，只在这里转换成展示文本。
/// 业务里永远不要手写 "km"/"mi"，统一走这里并传入用户的单位偏好。
enum Formatters {

    /// 距离：米 → "12.34 km" / "7.67 mi"
    static func distance(_ meters: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:   String(format: "%.2f km", meters / 1000)
        case .imperial: String(format: "%.2f mi", meters / 1609.344)
        }
    }

    /// 时长：秒 → "1:02:03" 或 "12:03"
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }

    /// 配速：秒/公里 → "5'30\"/km"（imperial 自动换算成 /mi）
    static func pace(secondsPerKm: Double, unit: UnitPreference) -> String {
        guard secondsPerKm > 0 else { return "--" }
        let perUnit = unit == .metric ? secondsPerKm : secondsPerKm * 1.609344
        let m = Int(perUnit) / 60, s = Int(perUnit) % 60
        let suffix = unit == .metric ? "/km" : "/mi"
        return String(format: "%d'%02d\"%@", m, s, suffix)
    }

    /// 速度：米/秒 → "25.3 km/h"（骑行常用）
    static func speed(metersPerSecond: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:   String(format: "%.1f km/h", metersPerSecond * 3.6)
        case .imperial: String(format: "%.1f mph", metersPerSecond * 2.236936)
        }
    }
}
