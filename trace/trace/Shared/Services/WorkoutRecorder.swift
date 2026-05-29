import Foundation
import CoreLocation
import Observation

/// 一次"进行中"的运动会话：聚合定位，实时计算距离/配速/爬升，结束时生成 Workout。
///
/// 设计要点：过程中样本只在内存里 buffer，只有 finish() 才构造 Workout / RouteSample /
/// Split 供上层写入 SwiftData，避免高频写盘。时长由日期推算，因此 App 退到后台、
/// 计时器被系统暂停也不会算错。
@Observable
final class WorkoutRecorder {
    enum State { case idle, recording, paused }

    private(set) var state: State = .idle
    let activityType: ActivityType

    // 实时指标（供界面绑定）
    private(set) var elapsed: TimeInterval = 0
    private(set) var distance: Double = 0           // 米
    private(set) var currentSpeed: Double = 0       // 米/秒
    private(set) var currentHeartRate: Double = 0
    private(set) var elevationGain: Double = 0
    private(set) var coordinates: [CLLocationCoordinate2D] = []   // 实时地图轨迹

    /// 平均配速（秒/公里）
    var averagePace: Double { distance > 0 ? elapsed / (distance / 1000) : 0 }
    /// 当前配速（秒/公里）
    var currentPace: Double { currentSpeed > 0.3 ? 1000 / currentSpeed : 0 }

    private let location: LocationManager
    private let health: HealthKitManager?
    private let pedometer: PedometerManager?
    private let altimeter: AltimeterManager?
    private let coach: AudioCoach?
    private let voiceEnabled: Bool
    private let weightKG: Double
    private let unit: UnitPreference

    private var timer: Timer?
    private var sessionStart = Date()
    private var accumulated: TimeInterval = 0
    private var segmentStart: Date?
    private var lastLocation: CLLocation?

    private var sampleBuffer: [RouteSample] = []
    private var heartRates: [Double] = []

    // 爬升：优先气压计；若不可用则用 GPS 海拔的滤波算法。
    private var usesBarometer = false
    private var lastBaroAltitude: Double?
    private let baroMinStep: Double = 1.0
    private var gpsElevation = ElevationCalculator()

    // 分段（每 1km 一段）
    private var splitBuffer: [(index: Int, distance: Double, duration: TimeInterval)] = []
    private var lastSplitDistance: Double = 0
    private var lastSplitElapsed: TimeInterval = 0

    init(
        activityType: ActivityType,
        location: LocationManager,
        health: HealthKitManager? = nil,
        pedometer: PedometerManager? = nil,
        altimeter: AltimeterManager? = nil,
        coach: AudioCoach? = nil,
        voiceEnabled: Bool = false,
        weightKG: Double,
        unit: UnitPreference = .metric
    ) {
        self.activityType = activityType
        self.location = location
        self.health = health
        self.pedometer = pedometer
        self.altimeter = altimeter
        self.coach = coach
        self.voiceEnabled = voiceEnabled
        self.weightKG = weightKG
        self.unit = unit
    }

    // MARK: - 会话控制

    func start() {
        guard state == .idle else { return }
        state = .recording
        sessionStart = .now
        segmentStart = .now
        if activityType.usesGPS {
            location.onLocation = { [weak self] in self?.ingest($0) }
            location.start()
            startAltimeterIfPossible()
        } else {
            // 室内：用计步器估算累计距离
            pedometer?.onDistance = { [weak self] in self?.ingestPedometer($0) }
            pedometer?.start()
        }
        health?.startHeartRateUpdates()
        if voiceEnabled {
            coach?.prepare()    // 先激活音频会话，锁屏/后台才能出声
            coach?.announce("开始\(activityType.title)")
        }
        startTimer()
    }

    func pause() {
        guard state == .recording else { return }
        accumulate()
        state = .paused
        timer?.invalidate()
        location.stop()
        stopAltimeter()
        health?.stopHeartRateUpdates()
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = .now
        state = .recording
        if activityType.usesGPS {
            location.start()
            startAltimeterIfPossible()
        }
        health?.startHeartRateUpdates()
        if voiceEnabled { coach?.prepare() }   // 暂停可能让 session 失活，恢复时重新激活
        startTimer()
    }

    /// 结束会话，构造可落库的 Workout（含 samples / splits）。
    func finish() -> Workout {
        accumulate()
        timer?.invalidate(); timer = nil
        location.onLocation = nil
        location.stop()
        pedometer?.onDistance = nil
        pedometer?.stop()
        stopAltimeter()
        health?.stopHeartRateUpdates()
        state = .idle

        let workout = Workout(activityType: activityType, startDate: sessionStart)
        workout.endDate = .now
        workout.duration = elapsed
        workout.distance = distance
        workout.elevationGain = elevationGain
        workout.averagePace = averagePace
        workout.averageHeartRate = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
        workout.maxHeartRate = heartRates.max() ?? 0
        workout.calories = CalorieCalculator.estimate(
            activityType: activityType, distance: distance, duration: elapsed, weightKG: weightKG
        )
        workout.samples = sampleBuffer
        workout.splits = splitBuffer.map {
            Split(index: $0.index, distance: $0.distance, duration: $0.duration)
        }
        if voiceEnabled {
            coach?.announce(String(format: "运动结束，共 %.2f 公里，用时约 %d 分钟",
                                   distance / 1000, Int(elapsed / 60)))
            coach?.deactivate()    // 让出音频焦点，恢复其他 App 音量
        }
        return workout
    }

    // MARK: - 私有

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    /// 刷新 elapsed（从日期推算，避免后台丢拍）并同步实时心率
    private func tick() {
        if let segmentStart {
            elapsed = accumulated + Date().timeIntervalSince(segmentStart)
        }
        if let health, health.liveHeartRate > 0 { currentHeartRate = health.liveHeartRate }
    }

    /// 把当前运动段折算进 accumulated 并清空 segmentStart
    private func accumulate() {
        guard let segmentStart else { return }
        accumulated += Date().timeIntervalSince(segmentStart)
        self.segmentStart = nil
        elapsed = accumulated
    }

    private func ingest(_ loc: CLLocation) {
        guard state == .recording else { return }
        if let last = lastLocation {
            let step = loc.distance(from: last)
            if step > 1 {   // 过滤 GPS 水平抖动
                distance += step
            }
        }
        // 没有气压计时，用滤波后的 GPS 海拔估算爬升
        if !usesBarometer {
            elevationGain = gpsElevation.ingest(
                altitude: loc.altitude,
                verticalAccuracy: loc.verticalAccuracy
            )
        }
        lastLocation = loc
        currentSpeed = max(loc.speed, 0)
        coordinates.append(loc.coordinate)
        sampleBuffer.append(RouteSample(
            timestamp: loc.timestamp,
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            altitude: loc.altitude,
            speed: max(loc.speed, 0),
            heartRate: currentHeartRate
        ))
        if currentHeartRate > 0 { heartRates.append(currentHeartRate) }
        updateSplits()
    }

    // MARK: - 气压计（A 方案，优先于 GPS 海拔）

    private func startAltimeterIfPossible() {
        guard let altimeter, AltimeterManager.isAvailable else { return }
        usesBarometer = true
        lastBaroAltitude = nil      // CMAltimeter 每次 start 都从 0 算
        altimeter.onRelativeAltitude = { [weak self] in self?.ingestBaro($0) }
        altimeter.start()
    }

    private func stopAltimeter() {
        altimeter?.onRelativeAltitude = nil
        altimeter?.stop()
    }

    /// 气压计相对海拔，采用**死区滞回（deadband hysteresis）**累计爬升。
    ///
    /// 关键点：锚点 `lastBaroAltitude` 在死区内**保持不动**，只有相对锚点的累计
    /// 变化超过 `baroMinStep` 才提交。这样平地上 ±0.x 米的气压噪声（开关门、风、
    /// 体感动作）不会被反复计入。早期版本对每个 |delta|≥0.3 都移动锚点，使
    /// "+0.4 累加 → −0.4 移锚不加 → +0.4 又累加"的噪声不断叠加成虚高（实测 6m）。
    private func ingestBaro(_ relativeAltitude: Double) {
        guard state == .recording else { return }
        guard let anchor = lastBaroAltitude else {
            lastBaroAltitude = relativeAltitude
            return
        }
        let delta = relativeAltitude - anchor
        if delta >= baroMinStep {
            elevationGain += delta          // 上坡：累加并把锚点抬到当前高度
            lastBaroAltitude = relativeAltitude
        } else if delta <= -baroMinStep {
            lastBaroAltitude = relativeAltitude   // 下坡：只移锚点，不累加
        }
        // |delta| < baroMinStep：死区内，锚点不动、忽略噪声
    }

    /// 室内：计步器给的是累计距离，直接覆盖
    private func ingestPedometer(_ cumulativeMeters: Double) {
        guard state == .recording else { return }
        distance = cumulativeMeters
        if let segmentStart {
            currentSpeed = distance / max(accumulated + Date().timeIntervalSince(segmentStart), 1)
        }
        updateSplits()
    }

    private func updateSplits() {
        while distance - lastSplitDistance >= 1000 {
            let index = splitBuffer.count + 1
            let segmentDuration = elapsed - lastSplitElapsed
            splitBuffer.append((index, 1000, segmentDuration))
            lastSplitDistance += 1000
            lastSplitElapsed = elapsed
            if voiceEnabled {
                coach?.announceKilometer(
                    km: index,
                    distance: distance,
                    paceSeconds: segmentDuration,
                    heartRate: currentHeartRate,
                    unit: unit,
                    prefersSpeed: activityType.prefersSpeed
                )
            }
        }
    }
}
