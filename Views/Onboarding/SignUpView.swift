import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var handle = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Join the fitness revolution")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
                        CustomTextField(
                            placeholder: "Name",
                            text: $name,
                            icon: "person.fill"
                        )
                        
                        CustomTextField(
                            placeholder: "Handle (e.g., @ironwarrior)",
                            text: $handle,
                            icon: "at"
                        )
                        .textInputAutocapitalization(.never)
                        
                        CustomTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill"
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        
                        CustomTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                    }
                    
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.signUp(email: email, password: password, name: name, handle: handle)
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Sign Up")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isFormValid ? Color.neonGreen : Color.gray)
                    .cornerRadius(16)
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    Spacer()
                }
                .padding(32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !name.isEmpty && !handle.isEmpty && password.count >= 6
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}
