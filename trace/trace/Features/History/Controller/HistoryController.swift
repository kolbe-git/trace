import Foundation
import Observation

/// 历史页控制器：持有筛选条件，判断某条记录是否符合当前筛选。
@Observable
final class HistoryController {
    var filter = HistoryFilter.all

    func matches(_ workout: Workout) -> Bool {
        if let type = filter.activityType, workout.activityType != type { return false }
        return true
    }
}
