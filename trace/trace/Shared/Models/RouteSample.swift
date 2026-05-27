import Foundation
import SwiftData

/// 运动过程中的一个采样点：位置 + 瞬时速度 + 心率。
/// 运动期间先在内存里 buffer，结束时整批落库（见 WorkoutRecorder）。
@Model
final class RouteSample {
    var timestamp: Date = Date()
    var latitude: Double = 0
    var longitude: Double = 0
    var altitude: Double = 0
    /// 瞬时速度（米/秒）
    var speed: Double = 0
    /// 瞬时心率（bpm），无数据为 0
    var heartRate: Double = 0

    var workout: Workout?

    init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        speed: Double = 0,
        heartRate: Double = 0
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.heartRate = heartRate
    }
}
