import Auth0
import SwiftUI
import FrameKit

@MainActor
@Observable
class AuthManager {
    // Authentication state
    var isAuthenticated = false
    var user: UserInfo?
    var accessToken: String?
    var userProfile: UserProfile?
    
    // Loading states
    var isLoading = false
    var error: AuthError?
    
    // Auth0 instance
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    init() {
        // Check for existing credentials on app launch
        checkExistingCredentials()
    }
    
    // MARK: - Authentication Methods
    
    func signInWithApple() {
        isLoading = true
        error = nil
        
        // Use webAuth without connection for Apple - it should auto-detect
        Auth0
            .webAuth()
            .scope("openid profile email")
            .start { result in
                Task { @MainActor in
                    self.isLoading = false
                    
                    switch result {
                    case .success(let credentials):
                        await self.handleSuccessfulAuth(credentials)
                    case .failure(let authError):
                        self.error = .authenticationFailed(authError.localizedDescription)
                    }
                }
            }
    }
    
    func signInWithEmail(email: String, password: String) {
        isLoading = true
        error = nil
        
        Auth0
            .authentication()
            .login(
                usernameOrEmail: email,
                password: password
            )
            .start { result in
                Task { @MainActor in
                    self.isLoading = false
                    
                    switch result {
                    case .success(let credentials):
                        await self.handleSuccessfulAuth(credentials)
                    case .failure(let authError):
                        self.error = .authenticationFailed(authError.localizedDescription)
                    }
                }
            }
    }
    
    func signUp(email: String, password: String, username: String) {
        isLoading = true
        error = nil
        
        Auth0
            .authentication()
            .signup(
                email: email,
                password: password,
                connection: "Username-Password-Authentication",
                userMetadata: ["username": username]
            )
            .start { result in
                Task { @MainActor in
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        // Auto sign-in after successful signup
                        self.signInWithEmail(email: email, password: password)
                    case .failure(let authError):
                        self.error = .signupFailed(authError.localizedDescription)
                    }
                }
            }
    }
    
    func signOut() {
        // Clear local credentials
        _ = credentialsManager.clear()
        
        // Reset state
        isAuthenticated = false
        user = nil
        accessToken = nil
        userProfile = nil
        
        // Optional: Logout from Auth0 (clears SSO session)
        Auth0
            .webAuth()
            .clearSession { result in
                switch result {
                case .success:
                    print("Successfully logged out from Auth0")
                case .failure(let error):
                    print("Logout error: \(error)")
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func handleSuccessfulAuth(_ credentials: Credentials) async {
        // Store credentials securely
        let stored = credentialsManager.store(credentials: credentials)
        guard stored else {
            error = .credentialStorageFailed
            return
        }
        
        // Update authentication state
        isAuthenticated = true
        accessToken = credentials.accessToken
        
        // Get user info
        await fetchUserProfile()
        
        // Create or update user profile in your backend
        await createOrUpdateUserProfile()
    }
    
    private func fetchUserProfile() async {
        guard let accessToken = accessToken else { return }
        
        Auth0
            .authentication()
            .userInfo(withAccessToken: accessToken)
            .start { result in
                Task { @MainActor in
                    switch result {
                    case .success(let userInfo):
                        self.user = userInfo
                        self.userProfile = UserProfile.from(auth0User: userInfo)
                    case .failure(let error):
                        self.error = .profileFetchFailed(error.localizedDescription)
                    }
                }
            }
    }
    
    private func createOrUpdateUserProfile() async {
        guard let user = user else { return }
        
        // TODO: Call your Azure Function to create/update user profile
        // This will sync Auth0 user data with your Cosmos DB
        print("User authenticated: \(user.name ?? "Unknown")")
    }
    
    private func checkExistingCredentials() {
        guard credentialsManager.hasValid() else { return }
        
        credentialsManager.credentials { result in
            Task { @MainActor in
                switch result {
                case .success(let credentials):
                    self.accessToken = credentials.accessToken
                    self.isAuthenticated = true
                    await self.fetchUserProfile()
                case .failure:
                    // Credentials expired or invalid
                    self.signOut()
                }
            }
        }
    }
    
    func refreshTokenIfNeeded() async {
        guard credentialsManager.hasValid() else {
            signOut()
            return
        }
        
        credentialsManager.credentials { result in
            Task { @MainActor in
                switch result {
                case .success(let credentials):
                    self.accessToken = credentials.accessToken
                case .failure:
                    self.signOut()
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct UserProfile {
    let id: String
    let email: String?
    let name: String?
    let picture: String?
    let userType: UserType
    let location: String?
    let createdAt: Date
    
    enum UserType: String, CaseIterable {
        case viewer = "viewer"
        case creator = "creator"
        case admin = "admin"
    }
    
    static func from(auth0User: UserInfo) -> UserProfile {
        return UserProfile(
            id: auth0User.sub,
            email: auth0User.email,
            name: auth0User.name,
            picture: auth0User.picture,
            userType: .viewer, // Default, will be updated by backend
            location: nil, // Will be set based on user selection
            createdAt: Date()
        )
    }
}

enum AuthError: LocalizedError {
    case authenticationFailed(String)
    case signupFailed(String)
    case credentialStorageFailed
    case profileFetchFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .signupFailed(let message):
            return "Signup failed: \(message)"
        case .credentialStorageFailed:
            return "Failed to store credentials securely"
        case .profileFetchFailed(let message):
            return "Failed to fetch user profile: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
