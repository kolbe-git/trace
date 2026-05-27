import Foundation
import Observation

/// 目标页控制器：把每个目标和它所在周期内的运动数据组合成进度。
@Observable
final class GoalsController {
    func progress(for goals: [Goal], workouts: [Workout]) -> [GoalProgress] {
        goals.map { goal in
            let interval = Self.interval(for: goal.period)
            let inPeriod = workouts.filter { interval.contains($0.startDate) }
            let current: Double = switch goal.metric {
            case .distance: inPeriod.reduce(0) { $0 + $1.distance }
            case .count:    Double(inPeriod.count)
            }
            return GoalProgress(goal: goal, current: current)
        }
    }

    /// 目标周期对应的当前时间区间（本周 / 本月）
    static func interval(for period: GoalPeriod) -> DateInterval {
        let calendar = Calendar.current
        let component: Calendar.Component = period == .weekly ? .weekOfYear : .month
        return calendar.dateInterval(of: component, for: .now)
            ?? DateInterval(start: .now, duration: 0)
    }
}
