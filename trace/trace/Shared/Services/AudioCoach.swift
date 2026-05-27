import Foundation
import AVFoundation

/// 运动语音播报：开始 / 每公里 / 结束时用中文 TTS 播报。
///
/// 用 .playback + .voicePrompt + duckOthers，运动中（App 因后台定位保持存活）即可播报；
/// 锁屏后台播报如不稳定，再给 target 加 UIBackgroundModes = audio。
final class AudioCoach {
    private let synthesizer = AVSpeechSynthesizer()

    func announce(_ text: String) {
        activateSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        synthesizer.speak(utterance)
    }

    /// 每公里（或英里）的语音播报：累计距离、本段配速/速度、当前心率。
    ///
    /// - 文本里把单位写成"公里/英里/公里每小时"等中文形式（而不是 km / km/h），
    ///   zh-CN TTS 念出来才自然。
    /// - paceSeconds 是本段"每公里秒数"，单位偏好为英制时需要换算成"每英里秒数"。
    /// - 骑行场景（prefersSpeed=true）以速度为主，不播配速；跑步/步行两个都给。
    func announceKilometer(
        km: Int,
        distance: Double,
        paceSeconds: Double,
        heartRate: Double,
        unit: UnitPreference,
        prefersSpeed: Bool
    ) {
        let unitName = unit == .metric ? "公里" : "英里"
        let factor   = unit == .metric ? 1000.0 : 1609.344
        let totalInUnit = distance / factor

        var text = "已跑 \(String(format: "%.2f", totalInUnit)) \(unitName)"

        if paceSeconds > 0 {
            let mps = 1000 / paceSeconds
            let speedPerHour = unit == .metric ? mps * 3.6 : mps * 2.236936
            if prefersSpeed {
                text += "，本\(unitName)速度 \(String(format: "%.1f", speedPerHour)) \(unitName)每小时"
            } else {
                let perUnit = unit == .metric ? paceSeconds : paceSeconds * 1.609344
                text += "，本\(unitName)配速 \(Int(perUnit) / 60) 分 \(Int(perUnit) % 60) 秒"
                text += "，速度 \(String(format: "%.1f", speedPerHour)) \(unitName)每小时"
            }
        }
        if heartRate > 0 {
            text += "，心率 \(Int(heartRate))"
        }
        announce(text)
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
        try? session.setActive(true)
    }
}
