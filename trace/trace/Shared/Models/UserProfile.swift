import Foundation
import SwiftData

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male, female, unspecified
    var id: String { rawValue }
    var title: String {
        switch self {
        case .male: "男"
        case .female: "女"
        case .unspecified: "未设置"
        }
    }
}

/// 单用户档案（表里通常只有一行）。用于卡路里估算与单位展示。
@Model
final class UserProfile {
    /// 身高（厘米）
    var heightCM: Double = 0
    /// 体重（千克）
    var weightKG: Double = 0
    var birthday: Date?
    var sex: BiologicalSex = BiologicalSex.unspecified
    /// 距离单位偏好
    var unit: UnitPreference = UnitPreference.metric
    /// 地图样式偏好
    var mapStyle: MapStylePreference = MapStylePreference.standard

    init() {}
}
