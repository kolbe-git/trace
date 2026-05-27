import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Workout.startDate, order: .reverse) private var workouts: [Workout]
    @Query private var profiles: [UserProfile]
    @State private var controller = StatsController()

    private var unit: UnitPreference { profiles.first?.unit ?? .metric }
    private var summary: StatsSummary { controller.summary(from: workouts) }
    private var buckets: [StatsBucket] { controller.buckets(from: workouts) }
    private var records: PersonalRecords { controller.personalRecords(from: workouts) }
    private var lifetime: Double { controller.lifetimeDistance(from: workouts) }
    private var streak: Int { controller.currentStreak(from: workouts) }

    var body: some View {
        NavigationStack {
            List {
                Picker("周期", selection: $controller.period) {
                    ForEach(StatsPeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                summarySection
                trendSection
                achievementSection
                recordSection
            }
            .navigationTitle("统计")
        }
    }

    // MARK: - 汇总

    private var summarySection: some View {
        Section("汇总") {
            LabeledContent("总距离", value: Formatters.distance(summary.totalDistance, unit: unit))
            LabeledContent("总时长", value: Formatters.duration(summary.totalDuration))
            LabeledContent("次数", value: "\(summary.workoutCount)")
            LabeledContent("平均配速", value: Formatters.pace(secondsPerKm: summary.averagePace, unit: unit))
        }
    }

    // MARK: - 趋势图

    private var trendSection: some View {
        Section("距离趋势（\(distanceUnitLabel)）") {
            if summary.totalDistance == 0 {
                Text("这段时间还没有运动").foregroundStyle(.secondary)
            } else {
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("日期", bucket.date, unit: controller.period.bucketComponent),
                        y: .value(distanceUnitLabel, distanceInUnit(bucket.distance))
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: controller.period.bucketComponent,
                                              count: controller.period.axisStride)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: controller.period.axisLabelFormat)
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 成就

    private var achievementSection: some View {
        Section("成就（全期）") {
            LabeledContent("累计里程", value: Formatters.distance(lifetime, unit: unit))
            LabeledContent("连续打卡", value: "\(streak) 天")
        }
    }

    // MARK: - 个人最佳

    private var recordSection: some View {
        Section("跑步纪录（全期）") {
            LabeledContent("单次最长距离",
                value: records.longestDistance > 0 ? Formatters.distance(records.longestDistance, unit: unit) : "--")
            LabeledContent("单次最长时长",
                value: records.longestDuration > 0 ? Formatters.duration(records.longestDuration) : "--")
            LabeledContent("最快单公里", value: paceText(records.fastestKmPace))
            LabeledContent("最快 5 公里配速", value: paceText(records.fastest5KPace))
            LabeledContent("最快 10 公里配速", value: paceText(records.fastest10KPace))
        }
    }

    // MARK: - Helpers

    private var distanceUnitLabel: String { unit == .metric ? "公里" : "英里" }

    private func distanceInUnit(_ meters: Double) -> Double {
        unit == .metric ? meters / 1000 : meters / 1609.344
    }

    private func paceText(_ secondsPerKm: Double) -> String {
        secondsPerKm > 0 ? Formatters.pace(secondsPerKm: secondsPerKm, unit: unit) : "--"
    }
}

#Preview {
    StatsView()
        .modelContainer(for: Workout.self, inMemory: true)
}
