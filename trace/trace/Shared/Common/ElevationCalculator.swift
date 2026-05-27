import Foundation
import CoreLocation

/// GPS 海拔的"累计爬升"计算器。
///
/// GPS 的垂直精度差，单次读数在静止时也会上下抖动十几米。直接对相邻样本
/// 累加正向差会得到严重偏大的爬升（比如 3m 实际跑出 100m+）。本类做三件事：
///
/// 1. **精度过滤**：丢掉 `verticalAccuracy < 0`（无效）或 > 阈值（默认 10m）的样本；
/// 2. **滑动平均**：对最近 N 个 altitude 取均值，压掉高频抖动；
/// 3. **最小阈值（hysteresis）**：只有当平滑后的高度变化超过 `minStep` 时
///    才更新参考点，避免在阈值附近反复触发。
///
/// 在录制时被 `WorkoutRecorder` 实时调用 —— 仅作为气压计不可用时的 GPS 回退路径。
/// 详情页直接展示存进 `Workout.elevationGain` 的值，不再重算（气压计的高精度结果
/// 不该被 GPS 海拔覆盖）。
struct ElevationCalculator {
    var maxVerticalAccuracy: Double = 10
    var windowSize: Int = 5
    var minStep: Double = 1.0

    private var window: [Double] = []
    private var lastSmoothed: Double?
    private(set) var elevationGain: Double = 0

    /// 喂一个新的样本，返回当前累计爬升。
    /// - Parameters:
    ///   - altitude: GPS 给出的海拔（米）
    ///   - verticalAccuracy: GPS 垂直精度（米，负数表示无效）。若调用方拿不到
    ///     就传一个 0 让样本默认通过——但建议拿真值。
    @discardableResult
    mutating func ingest(altitude: Double, verticalAccuracy: Double) -> Double {
        guard verticalAccuracy >= 0, verticalAccuracy <= maxVerticalAccuracy else {
            return elevationGain
        }
        window.append(altitude)
        if window.count > windowSize { window.removeFirst(window.count - windowSize) }
        // 窗口没攒满前不出值，避免开头几个样本剧烈抖动
        guard window.count == windowSize else { return elevationGain }

        let smoothed = window.reduce(0, +) / Double(window.count)
        if let last = lastSmoothed {
            let diff = smoothed - last
            if abs(diff) >= minStep {
                if diff > 0 { elevationGain += diff }
                lastSmoothed = smoothed
            }
        } else {
            lastSmoothed = smoothed
        }
        return elevationGain
    }
}
