import Foundation

/// 记录页用的实时指标快照（与持久化的 Workout 区分开，只为界面绑定）。
struct RecordMetrics {
    var elapsed: TimeInterval = 0
    var distance: Double = 0       // 米
    var pace: Double = 0           // 秒/公里
    var heartRate: Double = 0

    static let zero = RecordMetrics()
}
