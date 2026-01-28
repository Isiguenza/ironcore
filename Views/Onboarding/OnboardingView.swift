import SwiftUI

struct OnboardingView: View {
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.neonGreen)
                        
                        Text("IRONCORE")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Forge your fitness legacy")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        NavigationLink(destination: SignUpView()) {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.neonGreen)
                                .cornerRadius(16)
                        }
                        
                        NavigationLink(destination: SignInView()) {
                            Text("Sign In")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.cardBackground)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
