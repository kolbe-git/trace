import Foundation

/// 地图样式偏好。映射到具体 MapStyle 的逻辑在 RouteMapView 里，保持本类型纯净。
enum MapStylePreference: String, Codable, CaseIterable, Identifiable {
    case standard   // 标准
    case hybrid     // 混合
    case satellite  // 卫星

    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard:  "标准"
        case .hybrid:    "混合"
        case .satellite: "卫星"
        }
    }
}
