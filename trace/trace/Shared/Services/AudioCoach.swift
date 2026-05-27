import Foundation
import AVFoundation

/// 运动语音播报：开始 / 每公里 / 结束时用中文 TTS 播报。
///
/// 锁屏 / 后台也要发声，依赖两件事：
/// 1. Info.plist 的 UIBackgroundModes 含 `audio`
/// 2. 会话开始时把 AVAudioSession 激活为 .playback + .voicePrompt + .duckOthers，
///    会话结束时再 deactivate；中途的每条播报不再反复 setCategory/setActive。
final class AudioCoach {
    private let synthesizer = AVSpeechSynthesizer()
    private var sessionActive = false

    /// 会话开始时调用：一次性配置并激活播放型音频会话，让后续 TTS 在锁屏/后台也能出声。
    func prepare() {
        guard !sessionActive else { return }
        let session = AVAudioSession.sharedInstance()
        // .duckOthers 与 .mixWithOthers 语义冲突，这里只保留 ducking：
        // 播报时压低音乐，播完音乐自动恢复。
        try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
        try? session.setActive(true, options: [])
        sessionActive = true
    }

    /// 会话结束时调用：让出音频焦点，恢复其他 App 的正常音量。
    func deactivate() {
        guard sessionActive else { return }
        sessionActive = false
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func announce(_ text: String) {
        prepare()       // 防御性：万一上层忘了调 prepare 也能播
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
}
