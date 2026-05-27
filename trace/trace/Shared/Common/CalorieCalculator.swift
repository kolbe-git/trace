import Foundation

/// 基于 MET 的卡路里估算：kcal = MET × 体重(kg) × 时长(小时)。
/// 体重未设置时用 65kg 兜底。够个人用，不追求医疗级精度。
enum CalorieCalculator {

    static func estimate(
        activityType: ActivityType,
        distance: Double,        // 米
        duration: TimeInterval,  // 秒
        weightKG: Double
    ) -> Double {
        guard duration > 0 else { return 0 }
        let weight = weightKG > 0 ? weightKG : 65
        let hours = duration / 3600
        let kmh = (distance / 1000) / hours
        return met(for: activityType, speedKMH: kmh) * weight * hours
    }

    /// 按运动类型与速度查 MET 值（参考运动能耗 compendium 的近似）
    private static func met(for type: ActivityType, speedKMH kmh: Double) -> Double {
        switch type {
        case .outdoorRun, .indoorRun:
            // 跑步：MET 约等于速度数值（10km/h≈10），低速兜底 6
            return max(6, kmh)
        case .cycling:
            if kmh < 16 { return 4 }
            if kmh < 19 { return 6.8 }
            if kmh < 22 { return 8 }
            if kmh < 25 { return 10 }
            return 12
        case .walking:
            if kmh < 4 { return 2.8 }
            if kmh < 5.5 { return 3.5 }
            if kmh < 6.5 { return 5 }
            return 7
        }
    }
}
