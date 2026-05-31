import ActivityKit
import WidgetKit
import SwiftUI

/// 进行中运动的 Live Activity：锁屏/通知中心一张卡片，灵动岛 expanded/compact/minimal 三态。
struct TraceLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TraceActivityAttributes.self) { context in
            // 锁屏 / 通知中心展开视图
            LockScreenView(context: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态（长按灵动岛）
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.activityTitle)
                            .font(.caption).foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: context.attributes.activitySymbol)
                            .foregroundStyle(.green)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timeText(context)
                        .font(.system(.title3, design: .rounded)).monospacedDigit().bold()
                        .foregroundStyle(.green)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        metric(context.state.distanceText, "距离")
                        Spacer()
                        metric(context.state.primaryValue, context.state.primaryLabel)
                        Spacer()
                        metric(context.state.heartRateText, "心率")
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.attributes.activitySymbol)
                    .foregroundStyle(.green)
            } compactTrailing: {
                timeText(context)
                    .font(.system(.body, design: .rounded)).monospacedDigit()
                    .foregroundStyle(.green)
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.attributes.activitySymbol)
                    .foregroundStyle(.green)
            }
            .widgetURL(URL(string: "trace://record"))
            .keylineTint(.green)
        }
    }

    /// 运行中用自走秒计时器；暂停时显示冻结的静态时长。
    @ViewBuilder
    private func timeText(_ context: ActivityViewContext<TraceActivityAttributes>) -> some View {
        if context.state.isPaused {
            Text(context.state.elapsedText)
        } else {
            Text(context.state.effectiveStartDate, style: .timer)
        }
    }

    private func metric(_ value: String, _ title: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.headline, design: .rounded)).monospacedDigit().bold()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

/// 锁屏 / 通知中心展开卡片。
private struct LockScreenView: View {
    let context: ActivityViewContext<TraceActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label {
                    Text(context.attributes.activityTitle).font(.subheadline).bold()
                } icon: {
                    Image(systemName: context.attributes.activitySymbol).foregroundStyle(.green)
                }
                Spacer()
                if context.state.isPaused {
                    Label(context.state.elapsedText, systemImage: "pause.circle.fill")
                        .font(.system(.subheadline, design: .rounded)).monospacedDigit()
                        .foregroundStyle(.orange)
                } else {
                    Text(context.state.effectiveStartDate, style: .timer)
                        .font(.system(.subheadline, design: .rounded)).monospacedDigit().bold()
                        .multilineTextAlignment(.trailing)
                }
            }
            HStack(alignment: .firstTextBaseline) {
                item(context.state.distanceText, "距离")
                Spacer()
                item(context.state.primaryValue, context.state.primaryLabel)
                Spacer()
                item(context.state.heartRateText, "心率")
            }
        }
        .foregroundStyle(.white)
    }

    private func item(_ value: String, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(.title3, design: .rounded)).monospacedDigit().bold()
            Text(title).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
    }
}
