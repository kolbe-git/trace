import Foundation

/// 支持的运动类型。决定是否走 GPS、用配速还是速度展示。
enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case outdoorRun   // 户外跑步
    case indoorRun    // 室内跑步 / 跑步机
    case cycling      // 骑行
    case walking      // 步行

    var id: String { rawValue }

    var title: String {
        switch self {
        case .outdoorRun: "户外跑步"
        case .indoorRun:  "室内跑步"
        case .cycling:    "骑行"
        case .walking:    "步行"
        }
    }

    /// SF Symbol 名
    var symbol: String {
        switch self {
        case .outdoorRun: "figure.run"
        case .indoorRun:  "figure.run.treadmill"
        case .cycling:    "figure.outdoor.cycle"
        case .walking:    "figure.walk"
        }
    }

    /// 是否依赖 GPS 轨迹（仅室内跑不依赖，靠计步/手动输入）
    var usesGPS: Bool { self != .indoorRun }

    /// 是否更适合用"速度"而非"配速"展示（骑行）
    var prefersSpeed: Bool { self == .cycling }
}
