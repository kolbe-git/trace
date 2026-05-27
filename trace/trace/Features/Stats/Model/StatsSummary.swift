import Foundation

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:  "本周"
        case .month: "本月"
        case .year:  "今年"
        }
    }

    /// 当前周期的时间区间（本周 / 本月 / 今年）
    var interval: DateInterval {
        let calendar = Calendar.current
        let component: Calendar.Component = switch self {
        case .week:  .weekOfYear
        case .month: .month
        case .year:  .year
        }
        return calendar.dateInterval(of: component, for: .now)
            ?? DateInterval(start: .now, duration: 0)
    }

    /// 趋势图分桶单位：周/月按天，年按月
    var bucketComponent: Calendar.Component {
        switch self {
        case .week, .month: .day
        case .year:         .month
        }
    }

    /// X 轴标签间隔
    var axisStride: Int {
        switch self {
        case .week:  1
        case .month: 5
        case .year:  1
        }
    }

    /// X 轴标签格式
    var axisLabelFormat: Date.FormatStyle {
        switch self {
        case .week:  .dateTime.weekday(.narrow)
        case .month: .dateTime.day()
        case .year:  .dateTime.month(.narrow)
        }
    }
}

/// 某个时间段的运动汇总。
struct StatsSummary {
    var totalDistance: Double = 0          // 米
    var totalDuration: TimeInterval = 0
    var workoutCount: Int = 0

    /// 平均配速（秒/公里）
    var averagePace: Double {
        guard totalDistance > 0 else { return 0 }
        return totalDuration / (totalDistance / 1000)
    }

    static let empty = StatsSummary()
}

/// 趋势图的一根柱：某个分桶时间内的总距离。
struct StatsBucket: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double   // 米
}

/// 全期个人最佳（仅统计跑步）。
struct PersonalRecords {
    var longestDistance: Double = 0        // 米
    var longestDuration: TimeInterval = 0  // 秒
    var fastestKmPace: Double = 0          // 秒/公里：最快单公里（取自 splits）
    var fastest5KPace: Double = 0          // 5K+ 跑步里的最快平均配速
    var fastest10KPace: Double = 0         // 10K+ 跑步里的最快平均配速

    static let empty = PersonalRecords()
}
