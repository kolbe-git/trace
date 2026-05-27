import Foundation

/// 目标进度：当前值 vs 目标值，供进度环展示。
struct GoalProgress: Identifiable {
    let id = UUID()
    let goal: Goal
    let current: Double   // distance(米) 或 count

    /// 完成比例，0...1
    var fraction: Double {
        guard goal.target > 0 else { return 0 }
        return min(current / goal.target, 1)
    }

    var isComplete: Bool { goal.target > 0 && current >= goal.target }
}
