import SwiftUI

/// 首次启动引导：说明用途并请求定位 / 健康授权。
struct OnboardingView: View {
    var onContinue: () -> Void

    @State private var location = LocationManager()
    @State private var health = HealthKitManager()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.tint)
            Text("欢迎使用 trace")
                .font(.largeTitle.bold())
            Text("一个只属于你自己的运动记录")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 18) {
                row("location.fill", "定位", "记录跑步 / 骑行的 GPS 轨迹、距离与配速")
                row("heart.fill", "健康", "读取心率，并把运动写入「健康」App")
                row("icloud.fill", "iCloud", "运动数据在你的设备间自动同步")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: requestAndContinue) {
                Text("开始使用")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func row(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private func requestAndContinue() {
        location.requestAuthorization()
        Task {
            await health.requestAuthorization()
            await MainActor.run { onContinue() }
        }
    }
}

#Preview {
    OnboardingView(onContinue: {})
}
