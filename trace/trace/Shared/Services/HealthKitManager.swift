import Foundation
import HealthKit
import CoreLocation
import Observation

/// 与 Apple 健康交互：请求授权、运动中读实时心率、读体重、把运动写回"健康"App。
///
/// 说明：iPhone 单机一般拿不到实时心率（需要 Apple Watch 在录运动时写入），这里用
/// anchored query 订阅——一旦有心率源（手表 / 心率带）写入，liveHeartRate 就会更新。
@Observable
final class HealthKitManager {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// 运动中的实时心率（bpm），无数据时为 0
    private(set) var liveHeartRate: Double = 0
    private var heartRateQuery: HKAnchoredObjectQuery?

    private let heartRateUnit = HKUnit.count().unitDivided(by: .minute())

    // MARK: - 授权

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
        ]
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass),
            HKObjectType.workoutType(),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    // MARK: - 实时心率

    func startHeartRateUpdates() {
        guard isAvailable else { return }
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: .now, end: nil, options: .strictStartDate)
        let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            [weak self] _, samples, _, _, _ in
            self?.consume(samples)
        }
        let query = HKAnchoredObjectQuery(
            type: type, predicate: predicate, anchor: nil,
            limit: HKObjectQueryNoLimit, resultsHandler: handler
        )
        query.updateHandler = handler
        store.execute(query)
        heartRateQuery = query
    }

    func stopHeartRateUpdates() {
        if let heartRateQuery { store.stop(heartRateQuery) }
        heartRateQuery = nil
        liveHeartRate = 0
    }

    private func consume(_ samples: [HKSample]?) {
        guard let last = (samples as? [HKQuantitySample])?.last else { return }
        let bpm = last.quantity.doubleValue(for: heartRateUnit)
        DispatchQueue.main.async { self.liveHeartRate = bpm }
    }

    // MARK: - 读体重

    /// 最近一次体重（千克）。用于在用户没手填体重时改善卡路里估算。
    func latestBodyMassKG() async -> Double? {
        guard isAvailable else { return nil }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.bodyMass))],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let result = try? await descriptor.result(for: store)
        return result?.first?.quantity.doubleValue(for: .gramUnit(with: .kilo))
    }

    // MARK: - 写入运动

    /// 把一条运动写入"健康"App：总能量 + 距离 + 心率样本 + 轨迹路线。
    func save(
        activityType: ActivityType,
        start: Date,
        end: Date,
        distance: Double,
        calories: Double,
        heartRates: [HeartRateSample],
        locations: [CLLocation]
    ) async {
        guard isAvailable else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType.hkActivityType
        configuration.locationType = activityType.usesGPS ? .outdoor : .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: store, device: .local())

        do {
            try await builder.beginCollection(at: start)

            var samples: [HKSample] = []
            if calories > 0 {
                samples.append(HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: start, end: end))
            }
            if distance > 0 {
                let distanceType: HKQuantityType = activityType == .cycling
                    ? HKQuantityType(.distanceCycling)
                    : HKQuantityType(.distanceWalkingRunning)
                samples.append(HKQuantitySample(
                    type: distanceType,
                    quantity: HKQuantity(unit: .meter(), doubleValue: distance),
                    start: start, end: end))
            }
            for hr in heartRates {
                samples.append(HKQuantitySample(
                    type: HKQuantityType(.heartRate),
                    quantity: HKQuantity(unit: heartRateUnit, doubleValue: hr.bpm),
                    start: hr.date, end: hr.date))
            }
            if !samples.isEmpty {
                try await builder.addSamples(samples)
            }

            try await builder.endCollection(at: end)
            let workout = try await builder.finishWorkout()

            if let workout, !locations.isEmpty {
                try await routeBuilder.insertRouteData(locations)
                try await routeBuilder.finishRoute(with: workout, metadata: nil)
            }
        } catch {
            print("HealthKit save failed: \(error)")
        }
    }
}

/// 写入健康时用的轻量心率样本（避免把 SwiftData 模型带进异步任务）。
struct HeartRateSample {
    let date: Date
    let bpm: Double
}

private extension ActivityType {
    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .outdoorRun, .indoorRun: .running
        case .cycling: .cycling
        case .walking: .walking
        }
    }
}
