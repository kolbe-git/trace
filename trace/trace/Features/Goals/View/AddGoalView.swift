import SwiftUI
import SwiftData

/// 新建目标表单。
struct AddGoalView: View {
    var unit: UnitPreference

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var period: GoalPeriod = .weekly
    @State private var metric: GoalMetric = .distance
    @State private var distanceValue: Double = 20   // 用户单位
    @State private var countValue: Int = 3

    var body: some View {
        NavigationStack {
            Form {
                Picker("周期", selection: $period) {
                    ForEach(GoalPeriod.allCases) { Text($0.title).tag($0) }
                }
                Picker("类型", selection: $metric) {
                    ForEach(GoalMetric.allCases) { Text($0.title).tag($0) }
                }

                if metric == .distance {
                    HStack {
                        Text("目标距离（\(unit == .metric ? "公里" : "英里")）")
                        Spacer()
                        TextField("距离", value: $distanceValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    Stepper("目标次数：\(countValue) 次", value: $countValue, in: 1...50)
                }
            }
            .navigationTitle("新建目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
        }
    }

    private func save() {
        let target: Double = switch metric {
        case .distance: distanceValue * (unit == .metric ? 1000 : 1609.344)
        case .count:    Double(countValue)
        }
        modelContext.insert(Goal(period: period, metric: metric, target: target))
        dismiss()
    }
}

#Preview {
    AddGoalView(unit: .metric)
        .modelContainer(for: Goal.self, inMemory: true)
}
