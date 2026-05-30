import Foundation
import AVFoundation

/// 运动语音播报：开始 / 每公里 / 结束时用中文 TTS 播报。
///
/// 锁屏 / 后台也要发声，依赖两件事：
/// 1. Info.plist 的 UIBackgroundModes 含 `audio`
/// 2. 每条播报时把 AVAudioSession 激活为 .playback + .voicePrompt + .duckOthers，
///    播报结束（synthesizer 队列清空）后再 deactivate(.notifyOthersOnDeactivation)。
///
/// **关键：ducking 只在播报期间生效。** 早期版本在会话开始时就 setActive 并全程
/// 保持，导致音乐从头到尾被压低、播完也不恢复。现在改为"播报前激活、播完释放"，
/// 其它 App 的音乐只在每段播报的几秒内被压低，播完立即恢复原音量。
final class AudioCoach: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    private var categoryConfigured = false

    /// 选中的中文音色（懒加载并缓存）：优先 premium > enhanced，优先女声，音色更甜。
    private lazy var preferredVoice: AVSpeechSynthesisVoice? = Self.bestChineseVoice()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// 会话开始时调用：只配置一次 category，不在此激活（激活留到每条播报时）。
    func prepare() {
        configureCategoryIfNeeded()
    }

    /// 会话结束时调用：保险地停掉残留播报并释放音频会话。
    func deactivate() {
        synthesizer.stopSpeaking(at: .immediate)
        deactivateSession()
    }

    func announce(_ text: String) {
        configureCategoryIfNeeded()
        // 播报前激活会话并压低其它音频；didFinish/didCancel 里再释放。
        activateSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: "zh-CN")
        // 略慢、略高的音调让中文播报更清晰、更柔和。
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.94
        utterance.pitchMultiplier = 1.08
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    // MARK: - 音频会话

    private func configureCategoryIfNeeded() {
        guard !categoryConfigured else { return }
        // .duckOthers 与 .mixWithOthers 语义冲突，这里只保留 ducking。
        try? AVAudioSession.sharedInstance()
            .setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
        categoryConfigured = true
    }

    private func activateSession() {
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
    }

    private func deactivateSession() {
        // notifyOthersOnDeactivation 让被压低的音乐立刻恢复原音量。
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        scheduleDeactivationIfIdle()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        scheduleDeactivationIfIdle()
    }

    /// 一段播报结束后释放音频会话，让被压低的音乐恢复原音量。
    ///
    /// 两个关键点，缺一就会"永久压低"或"音乐忽大忽小"：
    /// 1. 以 `synthesizer.isSpeaking` 为准而不是自己数 utterance——队列里还有没播完的
    ///    就先不释放，避免连续播报之间音乐反复恢复又压低。
    /// 2. **延后一拍再 deactivate**。didFinish 触发时音频硬件往往还没真正收尾
    ///    （还有 postUtteranceDelay），此刻同步调 setActive(false) 会抛 isBusy 错误，
    ///    被 try? 吞掉后会话其实没释放，音乐就被永久压低。延迟到硬件空闲再释放才稳。
    private func scheduleDeactivationIfIdle() {
        guard !synthesizer.isSpeaking else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, !self.synthesizer.isSpeaking else { return }
            self.deactivateSession()
        }
    }

    // MARK: - 音色挑选

    /// 挑一个最甜美的中文音色：优先质量 premium > enhanced > default，
    /// 同质量下优先女声（gender == .female）。premium/enhanced 需用户在
    /// 「设置 → 辅助功能 → 朗读内容 → 声音」里下载，未下载时自动回退到默认音色。
    private static func bestChineseVoice() -> AVSpeechSynthesisVoice? {
        let chinese = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("zh-CN") || $0.language.hasPrefix("zh-Hans")
        }
        guard !chinese.isEmpty else { return nil }

        func qualityScore(_ q: AVSpeechSynthesisVoiceQuality) -> Int {
            switch q {
            case .premium:  return 3
            case .enhanced: return 2
            default:        return 1
            }
        }
        return chinese.max { a, b in
            let qa = qualityScore(a.quality), qb = qualityScore(b.quality)
            if qa != qb { return qa < qb }
            // 同质量：女声优先
            let fa = a.gender == .female ? 1 : 0
            let fb = b.gender == .female ? 1 : 0
            return fa < fb
        }
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
