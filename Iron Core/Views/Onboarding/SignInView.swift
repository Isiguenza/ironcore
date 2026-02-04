import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue your journey")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
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
                            await authViewModel.signIn(email: email, password: password)
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Sign In")
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
        !email.isEmpty && !password.isEmpty
    }
}
