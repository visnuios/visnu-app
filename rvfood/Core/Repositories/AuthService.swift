import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> UserProfile
    func register(name: String, email: String, phone: String, password: String) async throws -> UserProfile
    func forgotPassword(email: String) async throws -> String
    func logout() async
    func currentProfile() async throws -> UserProfile?
}

final class SessionStore {

    static let shared = SessionStore()

    private(set) var profile: UserProfile?

    private let defaults: UserDefaults
    private static let storageKey = "rvfood.session"

    var isLoggedIn: Bool { profile != nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = saved
        }
    }

    func signIn(_ profile: UserProfile) {
        self.profile = profile
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    func signOut() {
        profile = nil
        defaults.removeObject(forKey: Self.storageKey)
    }
}

final class DemoAuthService: AuthServiceProtocol {

    private let session: SessionStore

    init(session: SessionStore = .shared) {
        self.session = session
    }

    func login(email: String, password: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 600_000_000)
        guard email.contains("@"), password.count >= 4 else {
            throw APIError.businessRule("Enter a valid email and a password with at least 4 characters.")
        }
        let profile = UserProfile(
            id: "user_1",
            name: session.profile?.name ?? "Customer",
            email: email,
            phone: session.profile?.phone ?? "9876543210"
        )
        session.signIn(profile)
        return profile
    }

    func register(name: String, email: String, phone: String, password: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 700_000_000)
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw APIError.businessRule("Please enter your name.")
        }
        guard email.contains("@") else {
            throw APIError.businessRule("Please enter a valid email address.")
        }
        guard phone.count >= 10 else {
            throw APIError.businessRule("Please enter a valid 10-digit phone number.")
        }
        guard password.count >= 4 else {
            throw APIError.businessRule("Password must have at least 4 characters.")
        }
        let profile = UserProfile(id: "user_1", name: name, email: email, phone: phone)
        session.signIn(profile)
        return profile
    }

    func forgotPassword(email: String) async throws -> String {
        try await Task.sleep(nanoseconds: 600_000_000)
        guard email.contains("@") else {
            throw APIError.businessRule("Please enter a valid email address.")
        }
        return "Password reset link sent to \(email)"
    }

    func logout() async {
        session.signOut()
    }

    func currentProfile() async throws -> UserProfile? {
        session.profile
    }
}
