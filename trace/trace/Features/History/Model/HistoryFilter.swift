import Foundation

/// 历史列表的筛选条件。
struct HistoryFilter {
    var activityType: ActivityType?   // nil = 全部类型

    static let all = HistoryFilter()
}
