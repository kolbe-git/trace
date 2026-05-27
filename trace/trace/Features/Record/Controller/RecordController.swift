import Foundation
import CoreLocation
import Observation

/// 记录页控制器：管定位/健康权限、运动类型与会话生命周期。
@Observable
final class RecordController {
    var selectedType: ActivityType = .outdoorRun
    private(set) var recorder: WorkoutRecorder?

    /// 整个记录页共用一套定位 / 健康 / 计步 / 气压计 / 语音实例
    let location = LocationManager()
    let health = HealthKitManager()
    let pedometer = PedometerManager()
    let altimeter = AltimeterManager()
    let coach = AudioCoach()

    var isRecording: Bool { recorder?.state == .recording }
    var isPaused: Bool { recorder?.state == .paused }
    /// 运动中实时心率（供界面展示）
    var heartRate: Double { recorder?.currentHeartRate ?? 0 }

    func requestAuthorizations() {
        location.requestAuthorization()
        Task { await health.requestAuthorization() }
    }

    func begin(weightKG: Double, voiceEnabled: Bool, unit: UnitPreference) {
        let recorder = WorkoutRecorder(
            activityType: selectedType, location: location, health: health,
            pedometer: pedometer, altimeter: altimeter, coach: coach,
            voiceEnabled: voiceEnabled, weightKG: weightKG, unit: unit
        )
        recorder.start()
        self.recorder = recorder
    }

    func pause()  { recorder?.pause() }
    func resume() { recorder?.resume() }

    /// 结束：返回需写入 SwiftData 的 Workout，并把同一份数据写入 Apple 健康。
    func finish() -> Workout? {
        guard let recorder else { return nil }
        let workout = recorder.finish()
        self.recorder = nil
        writeToHealth(workout)
        return workout
    }

    /// 在主线程把 SwiftData 模型抽成值类型，再交给后台异步写入健康，避免跨线程访问模型。
    private func writeToHealth(_ workout: Workout) {
        let samples = (workout.samples ?? []).sorted { $0.timestamp < $1.timestamp }
        let heartRates = samples
            .filter { $0.heartRate > 0 }
            .map { HeartRateSample(date: $0.timestamp, bpm: $0.heartRate) }
        let locations = samples.map {
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                altitude: $0.altitude,
                horizontalAccuracy: 5, verticalAccuracy: 5,
                timestamp: $0.timestamp
            )
        }
        let type = workout.activityType
        let start = workout.startDate, end = workout.endDate
        let distance = workout.distance, calories = workout.calories

        Task {
            await health.save(
                activityType: type, start: start, end: end,
                distance: distance, calories: calories,
                heartRates: heartRates, locations: locations
            )
        }
    }
}
