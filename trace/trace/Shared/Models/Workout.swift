import Foundation
import SwiftData

/// 一条完成的运动记录。距离存米、时长存秒、配速存"秒/公里"。
///
/// CloudKit 约束：每个属性都有默认值；关系都可选并带反向。
@Model
final class Workout {
    var activityType: ActivityType = ActivityType.outdoorRun
    var startDate: Date = Date()
    var endDate: Date = Date()

    /// 运动时长（秒，已扣除暂停）
    var duration: TimeInterval = 0
    /// 距离（米）
    var distance: Double = 0
    /// 消耗（千卡）
    var calories: Double = 0

    /// 平均配速（秒/公里）
    var averagePace: Double = 0
    var averageHeartRate: Double = 0
    var maxHeartRate: Double = 0
    /// 累计爬升（米）
    var elevationGain: Double = 0

    var note: String = ""

    @Relationship(deleteRule: .cascade, inverse: \RouteSample.workout)
    var samples: [RouteSample]? = []

    @Relationship(deleteRule: .cascade, inverse: \Split.workout)
    var splits: [Split]? = []

    init(activityType: ActivityType, startDate: Date = .now) {
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = startDate
    }

    /// 平均速度（米/秒）—— 骑行展示用
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return distance / duration
    }
}
