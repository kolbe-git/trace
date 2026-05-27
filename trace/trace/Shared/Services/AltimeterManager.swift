import Foundation
import CoreMotion
import Observation

/// 气压计封装：用 CMAltimeter 累计爬升，比 GPS 海拔精确得多。
///
/// 真机 iPhone 6 及以后均支持气压计；模拟器与极少数老设备不支持
/// （`isRelativeAltitudeAvailable` 返回 false）。
/// 每次 `start()` 都会从 0 开始计算 `relativeAltitude`，因此调用方应在
/// 每次 start 后把"上一次海拔"重置为 nil，避免第一帧产生跳变。
@Observable
final class AltimeterManager {
    private let altimeter = CMAltimeter()
    private(set) var isRunning = false

    /// 相对海拔回调（米，自本次 start 起算）
    var onRelativeAltitude: ((Double) -> Void)?

    static var isAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }

    func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable(), !isRunning else { return }
        isRunning = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data, let self else { return }
            self.onRelativeAltitude?(data.relativeAltitude.doubleValue)
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        altimeter.stopRelativeAltitudeUpdates()
    }
}
