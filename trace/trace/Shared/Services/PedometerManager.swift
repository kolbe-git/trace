import Foundation
import CoreMotion
import Observation

/// 计步器封装：室内跑（无 GPS）用它估算累计距离。
/// 注意：模拟器不提供计步数据，需真机验证。
@Observable
final class PedometerManager {
    private let pedometer = CMPedometer()

    /// 累计距离回调（米，自 start 起算）
    var onDistance: ((Double) -> Void)?

    static var isAvailable: Bool { CMPedometer.isDistanceAvailable() }

    func start() {
        guard CMPedometer.isDistanceAvailable() else { return }
        pedometer.startUpdates(from: .now) { [weak self] data, _ in
            guard let meters = data?.distance?.doubleValue else { return }
            DispatchQueue.main.async { self?.onDistance?(meters) }
        }
    }

    func stop() {
        pedometer.stopUpdates()
    }
}
