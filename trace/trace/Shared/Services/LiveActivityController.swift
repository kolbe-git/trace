import Foundation
import ActivityKit

/// 包一层 ActivityKit：开始 / 更新 / 结束「进行中运动」的 Live Activity（锁屏 + 灵动岛）。
///
/// 设计上做成「尽力而为」：系统关闭了 Live Activity、或 request 抛错，都静默忽略，
/// 绝不影响主记录流程。所有 update/end 走后台 Task，不阻塞 1 秒一次的 tick。
final class LiveActivityController {

    private var activity: Activity<TraceActivityAttributes>?

    /// 系统层面是否允许 Live Activity（用户可在设置里关闭）
    var isAvailable: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// 开始一个 Live Activity。已在进行中或系统禁用则忽略。
    func start(attributes: TraceActivityAttributes, state: TraceActivityAttributes.ContentState) {
        guard activity == nil, isAvailable else { return }
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            activity = nil   // 失败就当没有，记录照常进行
        }
    }

    /// 推送最新指标。
    func update(_ state: TraceActivityAttributes.ContentState) {
        guard let activity else { return }
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    /// 结束并立即从锁屏/灵动岛移除。
    func end(_ finalState: TraceActivityAttributes.ContentState) {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
