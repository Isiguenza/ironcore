import SwiftUI
import Charts

struct ExerciseDetailView: View {
    let exerciseName: String
    let exerciseId: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @StateObject private var viewModel: ExerciseDetailViewModel
    
    init(exerciseName: String, exerciseId: String) {
        self.exerciseName = exerciseName
        self.exerciseId = exerciseId
        _viewModel = StateObject(wrappedValue: ExerciseDetailViewModel(exerciseId: exerciseId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                customTabBar
                
                TabView(selection: $selectedTab) {
                    OverviewTab(exerciseName: exerciseName, viewModel: viewModel)
                        .tag(0)
                    
                    HistoryTab(exerciseName: exerciseName, viewModel: viewModel)
                        .tag(1)
                    
                    InstructionsTab(exerciseName: exerciseName)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(exerciseName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabButton(title: "Overview", isSelected: selectedTab == 0) {
                withAnimation { selectedTab = 0 }
            }
            
            TabButton(title: "History", isSelected: selectedTab == 1) {
                withAnimation { selectedTab = 1 }
            }
            
            TabButton(title: "Instructions", isSelected: selectedTab == 2) {
                withAnimation { selectedTab = 2 }
            }
        }
        .background(Color.black)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .neonGreen : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.neonGreen : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct OverviewTab: View {
    let exerciseName: String
    @ObservedObject var viewModel: ExerciseDetailViewModel
    @State private var selectedMetric = "Max Weight"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                exerciseIllustration
                
                exerciseInfo
                
                chartSection
                
                metricsButtons
                
                personalRecords
            }
            .padding()
        }
    }
    
    private var exerciseIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.15))
                .frame(height: 250)
            
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.gray)
        }
    }
    
    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            HStack {
                Text("Primary:")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text("Chest")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("0 lbs")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("(In Progress)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Year")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.neonGreen)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.neonGreen)
                
                Spacer()
            }
            
            Chart {
                ForEach(chartData, id: \.date) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Weight", data.weight)
                    )
                    .foregroundStyle(Color.neonGreen)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", data.date),
                        y: .value("Weight", data.weight)
                    )
                    .foregroundStyle(Color.neonGreen)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(Color.gray)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.gray)
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
    
    private var metricsButtons: some View {
        HStack(spacing: 12) {
            MetricButton(title: "Max Weight", isSelected: selectedMetric == "Max Weight") {
                selectedMetric = "Max Weight"
            }
            
            MetricButton(title: "One Rep Max", isSelected: selectedMetric == "One Rep Max") {
                selectedMetric = "One Rep Max"
            }
            
            MetricButton(title: "Best Volume", isSelected: selectedMetric == "Best Volume") {
                selectedMetric = "Best Volume"
            }
        }
    }
    
    private var personalRecords: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Personal Records")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            RecordRow(
                title: "Max Weight",
                value: viewModel.personalRecords?.maxWeight.map { "\(Int($0.weight)) lbs" } ?? "-"
            )
            RecordRow(
                title: "Best 1RM",
                value: viewModel.personalRecords?.best1RM.map { "\(Int($0.weight)) lbs" } ?? "-"
            )
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
    
    private var chartData: [(date: String, weight: Double)] {
        if viewModel.stats.isEmpty {
            // Sample data if no real data
            return [
                ("Jul 11", 100),
                ("Jul 24", 100),
                ("Aug 21", 120),
                ("Sep 15", 110),
                ("Jan 20", 130)
            ]
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        return viewModel.stats.reversed().map { stat in
            (dateFormatter.string(from: stat.date), stat.maxWeight)
        }
    }
}

struct MetricButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.neonGreen : Color(white: 0.2))
                .cornerRadius(20)
        }
    }
}

struct RecordRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.neonGreen)
        }
    }
}

struct HistoryTab: View {
    let exerciseName: String
    @ObservedObject var viewModel: ExerciseDetailViewModel
    
    var body: some View {
        ScrollView {
            if viewModel.history.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No workout history yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text("Complete a workout with this exercise to see history")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.history) { item in
                        WorkoutHistoryCard(
                            workoutName: item.workoutName,
                            date: formatDate(item.date),
                            sets: item.sets.map { (number: $0.setNumber, weight: $0.weight, reps: $0.reps) }
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy, HH:mm"
        return formatter.string(from: date)
    }
}

struct WorkoutHistoryCard: View {
    let workoutName: String
    let date: String
    let sets: [(number: Int, weight: Double, reps: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(date)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("SET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 50, alignment: .leading)
                        
                        Text("WEIGHT & REPS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    ForEach(sets, id: \.number) { set in
                        HStack {
                            Text("\(set.number)")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .frame(width: 50, alignment: .leading)
                            
                            Text("\(Int(set.weight)) lbs x \(set.reps)")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

struct InstructionsTab: View {
    let exerciseName: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.15))
                        .frame(height: 250)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(exerciseName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    InstructionStep(
                        number: 1,
                        text: "Position yourself on the equipment and adjust the settings. Your muscles should be relaxed, allowing you to release the weight by extending your ankles."
                    )
                    
                    InstructionStep(
                        number: 2,
                        text: "Place your muscles against the pad and grip the handles firmly."
                    )
                    
                    InstructionStep(
                        number: 3,
                        text: "Take a breath and release the weight by flexing your calves."
                    )
                    
                    InstructionStep(
                        number: 4,
                        text: "Remove the safety bar and flex your ankles to lower the weight until you feel a stretch in your calves."
                    )
                }
            }
            .padding()
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
