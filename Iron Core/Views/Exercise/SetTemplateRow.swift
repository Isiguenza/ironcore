import SwiftUI

struct SetTemplate {
    var reps: String
    var weight: String?
}

struct SetTemplateRow: View {
    let setNumber: Int
    @Binding var reps: String
    @Binding var weight: String
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50)
            
            TextField("-", text: $reps)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                .cornerRadius(8)
            
            TextField("-", text: $weight)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
