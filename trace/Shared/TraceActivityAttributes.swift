import Foundation
import ActivityKit

/// 进行中运动会话的 Live Activity 数据契约。
///
/// 这是 app 主 target 与 TraceWidgets 扩展 **共享** 的唯一类型，
/// 因此放在两侧同步文件夹之外、由两个 target 同时编译。
///
/// 设计：固定信息（运动类型标题/图标）放在 attributes；随时间变化的实时指标放在
/// `ContentState`。展示文本在 app 侧用集中式 Formatters 预格式化好再塞进来，
/// 扩展侧只负责渲染，避免把 Formatters / 单位偏好也搬进扩展。
///
/// 时长用 `effectiveStartDate` 让锁屏/灵动岛用 `Text(_:style:.timer)` 自走秒，
/// 无需每秒推送更新；暂停时改用静态 `elapsedText`。
struct TraceActivityAttributes: ActivityAttributes {
    public typealias ContentState = State

    /// 运动类型标题，如「户外跑步」
    var activityTitle: String
    /// 运动类型 SF Symbol，如 "figure.run"
    var activitySymbol: String

    struct State: Codable, Hashable {
        /// 折算掉暂停后的「有效起点」= now - elapsed；配合 `Text(_:style:.timer)` 自走秒
        var effectiveStartDate: Date
        /// 是否暂停（暂停时锁屏显示静态时长而非自走秒）
        var isPaused: Bool
        /// 暂停时显示的静态时长文本，如 "12:03"
        var elapsedText: String

        /// 距离展示文本，如 "3.21 km"
        var distanceText: String
        /// 主指标值（跑步=配速 "5'30\"/km"，骑行=速度 "25.3 km/h"）
        var primaryValue: String
        /// 主指标标题（"配速" / "速度"）
        var primaryLabel: String
        /// 心率文本，如 "142" 或 "--"
        var heartRateText: String
    }
}
