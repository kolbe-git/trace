import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var health = HealthKitManager()
    @AppStorage("voiceCoachEnabled") private var voiceEnabled = true

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    form(for: profile)
                } else {
                    // 首次进入：建一条空档案
                    Color.clear.onAppear { modelContext.insert(UserProfile()) }
                }
            }
            .navigationTitle("我的")
        }
    }

    private func form(for profile: UserProfile) -> some View {
        Form {
            Section("个人信息") {
                Stepper(value: bind(profile, \.heightCM), in: 100...250, step: 1) {
                    LabeledContent("身高",
                        value: profile.heightCM > 0 ? "\(Int(profile.heightCM)) cm" : "未设置")
                }
                Stepper(value: bind(profile, \.weightKG), in: 30...200, step: 0.5) {
                    LabeledContent("体重",
                        value: profile.weightKG > 0 ? String(format: "%.1f kg", profile.weightKG) : "未设置")
                }
                Picker("性别", selection: bind(profile, \.sex)) {
                    ForEach(BiologicalSex.allCases) { Text($0.title).tag($0) }
                }
                DatePicker("生日",
                           selection: birthdayBinding(profile),
                           in: ...Date.now,
                           displayedComponents: .date)
                Button("从 Apple 健康同步体重") {
                    Task {
                        _ = await health.requestAuthorization()
                        if let kg = await health.latestBodyMassKG() { profile.weightKG = kg }
                    }
                }
            }

            Section("设置") {
                Picker("距离单位", selection: bind(profile, \.unit)) {
                    ForEach(UnitPreference.allCases) { Text($0.title).tag($0) }
                }
                Picker("地图样式", selection: bind(profile, \.mapStyle)) {
                    ForEach(MapStylePreference.allCases) { Text($0.title).tag($0) }
                }
                Toggle("语音播报", isOn: $voiceEnabled)
            }

            Section {
                LabeledContent("卡路里估算", value: "依据体重 · MET 模型")
            } footer: {
                Text("身高/体重用于更准确的卡路里估算；单位影响全 App 的距离与配速显示。")
            }
        }
    }

    /// 直接读写 SwiftData 模型属性的 Binding（SwiftData 会自动保存）。
    private func bind<Value>(_ profile: UserProfile, _ keyPath: ReferenceWritableKeyPath<UserProfile, Value>) -> Binding<Value> {
        Binding(get: { profile[keyPath: keyPath] }, set: { profile[keyPath: keyPath] = $0 })
    }

    /// 生日是可选的，未设置时默认 30 岁。
    private func birthdayBinding(_ profile: UserProfile) -> Binding<Date> {
        Binding(
            get: { profile.birthday ?? Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now },
            set: { profile.birthday = $0 }
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
