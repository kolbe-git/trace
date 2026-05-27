import Foundation

/// 编辑个人资料时的草稿，提交后写回 SwiftData 的 UserProfile。
struct ProfileDraft {
    var heightCM: Double = 0
    var weightKG: Double = 0
    var sex: BiologicalSex = .unspecified
    var unit: UnitPreference = .metric

    init() {}

    init(from profile: UserProfile) {
        heightCM = profile.heightCM
        weightKG = profile.weightKG
        sex = profile.sex
        unit = profile.unit
    }

    func apply(to profile: UserProfile) {
        profile.heightCM = heightCM
        profile.weightKG = weightKG
        profile.sex = sex
        profile.unit = unit
    }
}
