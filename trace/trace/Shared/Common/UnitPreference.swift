import Foundation

/// 距离单位偏好。所有展示层通过它决定显示 km 还是 mi。
enum UnitPreference: String, Codable, CaseIterable, Identifiable {
    case metric    // 公里 km
    case imperial  // 英里 mi

    var id: String { rawValue }
    var title: String { self == .metric ? "公里" : "英里" }
}
