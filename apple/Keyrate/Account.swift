import Foundation
import Security
import SwiftUI

/// The optional Jaybulb account, the same one the website uses (api.jaybulb.com). Email and password for now; Apple,
/// Google and GitHub sign-in come next (roadmap 2.5.0). The session lives in the Keychain only, never in UserDefaults.
/// Results are not uploaded: an account changes nothing about what is saved on this device.
@MainActor final class Account: ObservableObject {
    static let shared = Account()
    @Published private(set) var email: String?
    @Published var busy = false

    private struct Session: Codable { let access_token: String; let refresh_token: String; let user: User? }
    private struct User: Codable { let email: String? }
    private let api = URL(string: "https://api.jaybulb.com")!
    private let keychainKey = "jaybulb.session"

    private init() {
        if let data = Keychain.read(keychainKey), let s = try? JSONDecoder().decode(Session.self, from: data) { email = s.user?.email ?? "Signed in" }
    }

    func logIn(email: String, password: String) async throws {
        let data = try await call("/auth/token?grant_type=password", ["email": email, "password": password])
        let s = try JSONDecoder().decode(Session.self, from: data)
        Keychain.write(keychainKey, data)
        self.email = s.user?.email ?? email
    }

    /// Sends a confirmation email; the account works after the link is opened.
    func signUp(email: String, password: String) async throws {
        _ = try await call("/auth/signup", ["email": email, "password": password, "redirect_to": "https://keyrate.jaybulb.com/account/#confirmed"])
    }

    /// Sign in with Apple: the id token from AuthenticationServices, checked by the server against Apple's keys and
    /// the nonce we hashed into the request. Needs the Sign in with Apple capability (Joshua's team) to work.
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws {
        var body = ["provider": "apple", "id_token": idToken, "nonce": nonce]
        if let fullName, !fullName.isEmpty { body["full_name"] = fullName }
        let data = try await call("/auth/token?grant_type=id_token", body)
        let s = try JSONDecoder().decode(Session.self, from: data)
        Keychain.write(keychainKey, data)
        self.email = s.user?.email ?? "Signed in with Apple"
    }

    func resetPassword(email: String) async throws {
        _ = try await call("/auth/recover", ["email": email, "redirect_to": "https://keyrate.jaybulb.com/account/"])
    }

    func logOut() async {
        if let token = token() { _ = try? await call("/auth/logout", [:], token: token) }
        Keychain.delete(keychainKey); email = nil
    }

    func deleteAccount() async throws {
        guard let token = token() else { return }
        _ = try await call("/auth/user", nil, method: "DELETE", token: token)
        Keychain.delete(keychainKey); email = nil
    }

    private func token() -> String? {
        Keychain.read(keychainKey).flatMap { try? JSONDecoder().decode(Session.self, from: $0) }?.access_token
    }

    private func call(_ path: String, _ body: [String: String]?, method: String = "POST", token: String? = nil) async throws -> Data {
        busy = true; defer { busy = false }
        var req = URLRequest(url: URL(string: path, relativeTo: api)!)
        req.httpMethod = method
        req.setValue("Keyrate", forHTTPHeaderField: "User-Agent")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.setValue("application/json", forHTTPHeaderField: "Content-Type"); req.httpBody = try JSONEncoder().encode(body) }
        let data: Data, res: URLResponse
        do { (data, res) = try await URLSession.shared.data(for: req) } catch { throw AccountError("Can't reach the server. Check your connection and try again.") }
        let code = (res as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Something went wrong (\(code))"
            throw AccountError(Self.human(msg, code))
        }
        return data
    }

    private static func human(_ m: String, _ code: Int) -> String {
        if code == 429 || m.localizedCaseInsensitiveContains("slow down") { return "Too many tries. Wait a minute, then try again." }
        if m.localizedCaseInsensitiveContains("invalid login") { return "That email and password don't match." }
        if m.localizedCaseInsensitiveContains("not confirmed") { return "Confirm your email first: open the link we sent you." }
        return m.prefix(1).uppercased() + m.dropFirst() + "."
    }
}

struct AccountError: LocalizedError { let errorDescription: String?; init(_ m: String) { errorDescription = m } }

/// A generic password item for this app. Only readable while the device is unlocked, never synced to other devices.
enum Keychain {
    private static func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.nulljosh.keyrate", kSecAttrAccount as String: key]
    }
    static func read(_ key: String) -> Data? {
        var q = query(key); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        return SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess ? out as? Data : nil
    }
    static func write(_ key: String, _ data: Data) {
        delete(key)
        var q = query(key); q[kSecValueData as String] = data; q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }
    static func delete(_ key: String) { SecItemDelete(query(key) as CFDictionary) }
}

