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

/// Settings, Account: log in, sign up, reset, log out, delete. Plain form controls, so it looks right on every OS.
struct AccountPane: View {
    /// In the window's own Settings tab the appearance picker sits above the account; the Cmd-, window has it on General.
    var withAppearance = false
    @AppStorage("appearance") private var appearance = Appearance.system
    @ObservedObject private var account = Account.shared
    @State private var email = ""
    @State private var password = ""
    @State private var signingUp = false
    @State private var message: (text: String, bad: Bool)?
    @State private var armed = false

    var body: some View {
        Form {
            if withAppearance {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) { ForEach(Appearance.allCases) { Text($0.label).tag($0) } }
                        .pickerStyle(.segmented).labelsHidden()
                }
            }
            if let who = account.email {
                Section("Account") {
                    LabeledContent("Signed in as", value: who)
                    Text("Your results still stay on this device. Syncing your bests comes in a later update.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Section {
                    Button("Log Out") { Task { await account.logOut(); say("Logged out.") } }
                    Button(armed ? "Click Again to Delete for Good" : "Delete Account", role: .destructive) { delete() }
                }
            } else {
                Section {
                    Picker("", selection: $signingUp) { Text("Log In").tag(false); Text("Sign Up").tag(true) }
                        .pickerStyle(.segmented).labelsHidden()
                    TextField("Email", text: $email).textContentType(.username).autocorrectionDisabled()
                    SecureField(signingUp ? "Password (8 or more characters)" : "Password", text: $password)
                        .textContentType(.password) // .newPassword needs macOS 14
                        .onSubmit(go)
                } footer: {
                    Text("One account for Keyrate and the other Jaybulb apps.").font(.callout).foregroundStyle(.secondary)
                }
                Section {
                    Button(signingUp ? "Create Account" : "Log In", action: go)
                        .keyboardShortcut(.defaultAction)
                        .disabled(account.busy || email.isEmpty || password.isEmpty)
                    if !signingUp { Button("Forgot Password?") { reset() }.disabled(account.busy || email.isEmpty) }
                }
            }
            if let message {
                Text(message.text).foregroundStyle(message.bad ? Color.red : Color.accentColor).font(.callout)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .formStyle(.grouped)
    }

    private func say(_ t: String, bad: Bool = false) { message = (t, bad) }

    private func go() {
        let e = email.trimmingCharacters(in: .whitespaces)
        guard e.contains("@"), e.contains(".") else { return say("Enter a valid email address.", bad: true) }
        guard password.count >= 8 else { return say("Passwords are at least 8 characters.", bad: true) }
        Task {
            do {
                if signingUp { try await Account.shared.signUp(email: e, password: password); password = ""; say("Check your email for a link to confirm your account, then log in."); signingUp = false }
                else { try await Account.shared.logIn(email: e, password: password); password = ""; message = nil }
            } catch { say(error.localizedDescription, bad: true) }
        }
    }

    private func reset() {
        Task {
            do { try await Account.shared.resetPassword(email: email.trimmingCharacters(in: .whitespaces)); say("If there is an account for that email, a reset link is on its way.") }
            catch { say(error.localizedDescription, bad: true) }
        }
    }

    private func delete() {
        guard armed else { armed = true; Task { try? await Task.sleep(for: .seconds(4)); armed = false }; return }
        Task {
            do { try await Account.shared.deleteAccount(); say("Your account is deleted.") } catch { say(error.localizedDescription, bad: true) }
            armed = false
        }
    }
}
