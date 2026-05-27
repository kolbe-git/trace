import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var controller = RecordController()
    @State private var showEndConfirm = false
    /// 结束保存后把新 Workout push 进来，直接落到详情页；用户返回时回到 idle。
    @State private var path: [Workout] = []
    @AppStorage("voiceCoachEnabled") private var voiceEnabled = true

    private var unit: UnitPreference { profiles.first?.unit ?? .metric }
    private var weightKG: Double { profiles.first?.weightKG ?? 0 }
    private var mapStyle: MapStylePreference { profiles.first?.mapStyle ?? .standard }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let recorder = controller.recorder {
                    activeSession(recorder)
                } else {
                    idleSession
                }
            }
            .navigationTitle("记录")
            .navigationDestination(for: Workout.self) { workout in
                WorkoutDetailView(workout: workout)
            }
            .onAppear { controller.requestAuthorizations() }
            .confirmationDialog("确定结束本次运动？", isPresented: $showEndConfirm, titleVisibility: .visible) {
                Button("结束并保存", role: .destructive) { finishAndSave() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - 未开始

    private var idleSession: some View {
        VStack(spacing: 20) {
            if controller.selectedType.usesGPS {
                RouteMapView(coordinates: [], live: true, style: mapStyle)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
            } else {
                indoorPlaceholder
            }

            Picker("运动类型", selection: $controller.selectedType) {
                ForEach(ActivityType.allCases) { type in
                    Label(type.title, systemImage: type.symbol).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Button {
                controller.begin(weightKG: weightKG, voiceEnabled: voiceEnabled, unit: unit)
            } label: {
                Label("开始", systemImage: "play.fill")
                    .font(.title2).bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding([.horizontal, .bottom])
        }
        .padding(.top)
    }

    // MARK: - 记录中

    private func activeSession(_ recorder: WorkoutRecorder) -> some View {
        VStack(spacing: 0) {
            if recorder.activityType.usesGPS {
                RouteMapView(coordinates: recorder.coordinates, live: true, style: mapStyle)
            } else {
                indoorPlaceholder
            }

            metrics(recorder).padding(.vertical)

            controls.padding([.horizontal, .bottom])
        }
    }

    private var indoorPlaceholder: some View {
        VStack {
            Spacer()
            Image(systemName: controller.selectedType.symbol)
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("室内运动，无需地图")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func metrics(_ recorder: WorkoutRecorder) -> some View {
        HStack {
            metric("时长", Formatters.duration(recorder.elapsed))
            Divider()
            metric("距离", Formatters.distance(recorder.distance, unit: unit))
            Divider()
            if recorder.activityType.prefersSpeed {
                metric("速度", Formatters.speed(metersPerSecond: recorder.currentSpeed, unit: unit))
            } else {
                metric("配速", Formatters.pace(secondsPerKm: recorder.currentPace, unit: unit))
            }
            Divider()
            metric("心率", recorder.currentHeartRate > 0
                ? String(format: "%.0f", recorder.currentHeartRate) : "--")
        }
        .frame(height: 64)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).bold().monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            if controller.isPaused {
                Button {
                    controller.resume()
                } label: {
                    Label("继续", systemImage: "play.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    showEndConfirm = true
                } label: {
                    Label("结束", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    controller.pause()
                } label: {
                    Label("暂停", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func finishAndSave() {
        guard let workout = controller.finish() else { return }
        modelContext.insert(workout)
        // 显式插入子对象，确保轨迹点/分段一定落库（不依赖关系级联）
        (workout.samples ?? []).forEach { modelContext.insert($0) }
        (workout.splits ?? []).forEach { modelContext.insert($0) }
        // 直接跳到本次运动的详情页；返回后回到 idle 状态
        path.append(workout)
    }
}

#Preview {
    RecordView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
