import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.startDate, order: .reverse) private var workouts: [Workout]
    @Query private var profiles: [UserProfile]
    @State private var controller = HistoryController()

    private var unit: UnitPreference { profiles.first?.unit ?? .metric }
    private var visible: [Workout] { workouts.filter(controller.matches) }

    var body: some View {
        NavigationStack {
            Group {
                if visible.isEmpty {
                    ContentUnavailableView(
                        "还没有记录",
                        systemImage: "figure.run",
                        description: Text("去『记录』页开始第一次运动")
                    )
                } else {
                    List {
                        ForEach(visible) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout)
                            } label: {
                                WorkoutRow(workout: workout, unit: unit)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("历史")
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { modelContext.delete(visible[index]) }
    }
}

private struct WorkoutRow: View {
    let workout: Workout
    var unit: UnitPreference = .metric

    var body: some View {
        HStack {
            Image(systemName: workout.activityType.symbol)
                .frame(width: 28)
            VStack(alignment: .leading) {
                Text(workout.activityType.title)
                Text(workout.startDate, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Formatters.distance(workout.distance, unit: unit))
                .monospacedDigit()
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Workout.self, inMemory: true)
}
