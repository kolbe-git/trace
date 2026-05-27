import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @Query private var workouts: [Workout]
    @Query private var profiles: [UserProfile]
    @State private var controller = GoalsController()
    @State private var showAdd = false

    private var unit: UnitPreference { profiles.first?.unit ?? .metric }

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    ContentUnavailableView {
                        Label("还没有目标", systemImage: "target")
                    } description: {
                        Text("设定一个每周或每月目标，跟踪你的进度")
                    } actions: {
                        Button("新建目标") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(controller.progress(for: goals, workouts: workouts)) { item in
                            GoalRow(item: item, unit: unit)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("目标")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddGoalView(unit: unit)
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        let items = controller.progress(for: goals, workouts: workouts)
        for index in offsets { modelContext.delete(items[index].goal) }
    }
}

private struct GoalRow: View {
    let item: GoalProgress
    var unit: UnitPreference

    var body: some View {
        HStack(spacing: 16) {
            Gauge(value: item.fraction) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(item.fraction * 100))").font(.caption2)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(item.isComplete ? .green : .blue)
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(item.goal.period.title)\(item.goal.metric.title)目标")
                    .font(.headline)
                Text("\(valueText(item.current)) / \(valueText(item.goal.target))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if item.isComplete {
                    Label("已达成", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func valueText(_ value: Double) -> String {
        switch item.goal.metric {
        case .distance: Formatters.distance(value, unit: unit)
        case .count:    "\(Int(value)) 次"
        }
    }
}

#Preview {
    GoalsView()
        .modelContainer(for: [Goal.self, Workout.self], inMemory: true)
}
