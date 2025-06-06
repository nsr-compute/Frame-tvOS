import SwiftUI
import Auth0

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showEmailLogin = false
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 60) {
                // Frame branding
                VStack(spacing: 20) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.white)
                    
                    Text("Frame")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Local stories, global reach")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Login options
                VStack(spacing: 30) {
                    // Apple Sign-In (Primary)
                    AppleSignInButton()
                    
                    // Email login option
                    Button("Continue with Email") {
                        showEmailLogin = true
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Creator signup
                    Button("I'm a Creator") {
                        // Navigate to creator signup flow
                    }
                    .font(.title3)
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginView()
        }
        .alert("Authentication Error", isPresented: .constant(authManager.error != nil)) {
            Button("OK") {
                authManager.error = nil
            }
        } message: {
            Text(authManager.error?.localizedDescription ?? "")
        }
    }
}

struct AppleSignInButton: View {
    @Environment(AuthManager.self) private var authManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button {
            authManager.signInWithApple()
        } label: {
            HStack(spacing: 15) {
                if authManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "applelogo")
                        .font(.title2)
                }
                
                Text("Continue with Apple")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .disabled(authManager.isLoading)
    }
}

struct EmailLoginView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 20) {
                        if isSignUp {
                            TextField("Username", text: $username)
                                .textFieldStyle(FrameTextFieldStyle())
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(FrameTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(FrameTextFieldStyle())
                    }
                    
                    Button(isSignUp ? "Create Account" : "Sign In") {
                        if isSignUp {
                            authManager.signUp(email: email, password: password, username: username)
                        } else {
                            authManager.signInWithEmail(email: email, password: password)
                        }
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
                    
                    Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                        isSignUp.toggle()
                    }
                    .foregroundColor(.blue)
                }
                .padding(40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct FrameTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.white)
    }
}
