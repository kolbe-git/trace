import Foundation
import SwiftData

enum GoalPeriod: String, Codable, CaseIterable, Identifiable {
    case weekly, monthly
    var id: String { rawValue }
    var title: String { self == .weekly ? "每周" : "每月" }
}

enum GoalMetric: String, Codable, CaseIterable, Identifiable {
    case distance   // 目标距离（米）
    case count      // 目标次数
    var id: String { rawValue }
    var title: String { self == .distance ? "距离" : "次数" }
}

/// 周期性目标，例如"每周跑 20 公里"或"每月运动 12 次"。
@Model
final class Goal {
    var period: GoalPeriod = GoalPeriod.weekly
    var metric: GoalMetric = GoalMetric.distance
    /// 目标值：metric 为 distance 时单位是米，为 count 时是次数
    var target: Double = 0
    var isActive: Bool = true
    var createdAt: Date = Date()

    init(period: GoalPeriod, metric: GoalMetric, target: Double) {
        self.period = period
        self.metric = metric
        self.target = target
    }
}
