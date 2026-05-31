import WidgetKit
import SwiftUI

/// TraceWidgets 扩展入口。目前只含运动 Live Activity（锁屏 + 灵动岛）。
/// 后续主屏 Widget（本周距离 / 最近一次运动）也挂在这里。
@main
struct TraceWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TraceLiveActivity()
    }
}
