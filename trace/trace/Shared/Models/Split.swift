import Foundation
import SwiftData

/// 分段：通常每 1 公里一段，用于详情页的"分段配速"。
@Model
final class Split {
    /// 第几段（从 1 开始）
    var index: Int = 0
    /// 该段距离（米）
    var distance: Double = 0
    /// 该段用时（秒）
    var duration: TimeInterval = 0
    var averageHeartRate: Double = 0

    var workout: Workout?

    init(index: Int, distance: Double, duration: TimeInterval, averageHeartRate: Double = 0) {
        self.index = index
        self.distance = distance
        self.duration = duration
        self.averageHeartRate = averageHeartRate
    }

    /// 配速（秒/公里）
    var pace: Double {
        guard distance > 0 else { return 0 }
        return duration / (distance / 1000)
    }
}
