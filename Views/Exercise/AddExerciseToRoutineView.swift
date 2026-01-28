import SwiftUI

struct AddExerciseToRoutineView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    let initialSets: Int?
    let initialReps: String?
    let initialRest: Int?
    let initialNotes: String?
    @State private var sets: [SetTemplate] = []
    @State private var restSeconds = 90
    @State private var notes = ""
    let onAdd: (Int, String, Int, String?) -> Void
    
    init(exercise: Exercise, 
         initialSets: Int? = nil,
         initialReps: String? = nil,
         initialRest: Int? = nil,
         initialNotes: String? = nil,
         onAdd: @escaping (Int, String, Int, String?) -> Void) {
        self.exercise = exercise
        self.initialSets = initialSets
        self.initialReps = initialReps
        self.initialRest = initialRest
        self.initialNotes = initialNotes
        self.onAdd = onAdd
        
        _restSeconds = State(initialValue: initialRest ?? 90)
        _notes = State(initialValue: initialNotes ?? "")
        _sets = State(initialValue: {
            let count = initialSets ?? 1
            return (0..<count).map { _ in SetTemplate(reps: initialReps ?? "-", weight: nil) }
        }())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text(exercise.muscleGroup.displayName)
                                Text("•")
                                Text(exercise.equipment.displayName)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SETS")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("SET")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.gray)
                                            .frame(width: 50)
                                        
                                        Text("REPS")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                        
                                        Text("WEIGHT (KG)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    
                                    ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
                                        SetTemplateRow(
                                            setNumber: index + 1,
                                            reps: Binding(get: { sets[index].reps }, set: { sets[index].reps = $0 }),
                                            weight: Binding(get: { sets[index].weight ?? "" }, set: { sets[index].weight = $0.isEmpty ? nil : $0 })
                                        )
                                    }
                                    
                                    Button(action: { sets.append(SetTemplate(reps: "-", weight: nil)) }) {
                                        HStack {
                                            Image(systemName: "plus")
                                            Text("Agregar Serie")
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.neonGreen)
                                        .padding(.vertical, 12)
                                    }
                                }
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.05)))
                            }
                            
                            HStack {
                                Text("Rest Time")
                                    .foregroundColor(.gray)
                                Spacer()
                                Picker("", selection: $restSeconds) {
                                    Text("30s").tag(30)
                                    Text("60s").tag(60)
                                    Text("90s").tag(90)
                                    Text("2 min").tag(120)
                                    Text("3 min").tag(180)
                                }
                                .pickerStyle(.menu)
                                .accentColor(.neonGreen)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.05)))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes (Optional)")
                                    .foregroundColor(.gray)
                                
                                TextField("Exercise notes or reminders", text: $notes)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            onAdd(sets.count, sets.first?.reps ?? "-", restSeconds, notes.isEmpty ? nil : notes)
                            dismiss()
                        }) {
                            Text("Add to Routine")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.neonGreen))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
