import Foundation
import Observation

/// 统计页控制器：按周期过滤、聚合汇总、生成趋势分桶与个人最佳。
@Observable
final class StatsController {
    var period: StatsPeriod = .week

    /// 当前周期内的运动
    private func inPeriod(_ all: [Workout]) -> [Workout] {
        let interval = period.interval
        return all.filter { interval.contains($0.startDate) }
    }

    /// 当前周期汇总
    func summary(from all: [Workout]) -> StatsSummary {
        var summary = StatsSummary()
        for workout in inPeriod(all) {
            summary.totalDistance += workout.distance
            summary.totalDuration += workout.duration
            summary.workoutCount += 1
        }
        return summary
    }

    /// 当前周期趋势分桶（没运动的桶也占位，保证图表连续）
    func buckets(from all: [Workout]) -> [StatsBucket] {
        let calendar = Calendar.current
        let interval = period.interval
        let component = period.bucketComponent

        // 预生成空桶
        var slots: [Date] = []
        var cursor = calendar.dateInterval(of: component, for: interval.start)?.start ?? interval.start
        while cursor < interval.end {
            slots.append(cursor)
            cursor = calendar.date(byAdding: component, value: 1, to: cursor) ?? interval.end
        }

        // 把运动距离累加到对应桶
        var totals: [Date: Double] = [:]
        for workout in inPeriod(all) {
            let key = calendar.dateInterval(of: component, for: workout.startDate)?.start ?? workout.startDate
            totals[key, default: 0] += workout.distance
        }

        return slots.map { StatsBucket(date: $0, distance: totals[$0] ?? 0) }
    }

    /// 全期个人最佳（仅跑步）
    func personalRecords(from all: [Workout]) -> PersonalRecords {
        let runs = all.filter { $0.activityType == .outdoorRun || $0.activityType == .indoorRun }
        var records = PersonalRecords()
        records.longestDistance = runs.map(\.distance).max() ?? 0
        records.longestDuration = runs.map(\.duration).max() ?? 0
        records.fastestKmPace = runs.flatMap { $0.splits ?? [] }.map(\.pace).filter { $0 > 0 }.min() ?? 0
        records.fastest5KPace = runs.filter { $0.distance >= 5000 }.map(\.averagePace).filter { $0 > 0 }.min() ?? 0
        records.fastest10KPace = runs.filter { $0.distance >= 10000 }.map(\.averagePace).filter { $0 > 0 }.min() ?? 0
        return records
    }

    /// 全期累计距离（米，所有运动）
    func lifetimeDistance(from all: [Workout]) -> Double {
        all.reduce(0) { $0 + $1.distance }
    }

    /// 当前连续打卡天数（截止今天，今天没运动则从昨天起算）
    func currentStreak(from all: [Workout]) -> Int {
        let calendar = Calendar.current
        let days = Set(all.map { calendar.startOfDay(for: $0.startDate) })
        guard !days.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: .now)
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}
