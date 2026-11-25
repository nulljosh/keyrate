import AuthenticationServices
import CryptoKit
import SwiftUI

/// Settings in the window: your account first, appearance at the bottom as three small previews (like Claude's).
/// Drawn in Keyrate's own palette, not a system Form, so it matches the test. Buttons are glass on iOS and macOS 26
/// (glassProminent for the main action) and plain capsules before that.
struct SettingsScreen: View {
    @Environment(\.colorScheme) private var scheme
    private var p: Palette { scheme == .dark ? .dark : .light }

    /// Follows the window: two columns when there's room (account left, appearance slices right), one column
    /// otherwise. Margins grow with the width and the content sits in the middle of the height.
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 880
            ScrollView {
                Group {
                    if wide {
                        HStack(alignment: .top, spacing: 40) {
                            section("Account") { AccountCard(p: p) }.frame(maxWidth: 560)
                            section("Appearance") { AppearancePicker(p: p, vertical: true) }.frame(width: 260)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 40) {
                            section("Account") { AccountCard(p: p) }
                            section("Appearance") { AppearancePicker(p: p, vertical: false) }
                        }
                        .frame(maxWidth: 560)
                    }
                }
                .padding(.horizontal, max(24, geo.size.width * 0.06))
                .padding(.top, 56).padding(.bottom, 104) // clear of the traffic lights and the bottom bar
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
        .background(p.bg.ignoresSafeArea())
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(.footnote, weight: .semibold)).foregroundStyle(p.dim).textCase(.uppercase).kerning(0.4)
            content()
        }
    }
}

// MARK: - Account

private struct AccountCard: View {
    let p: Palette
    @ObservedObject private var account = Account.shared
    @State private var email = ""
    @State private var password = ""
    @State private var signingUp = false
    @State private var message: (text: String, bad: Bool)?
    @State private var armed = false
    @State private var nonce = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let who = account.email { signedIn(who) } else { signedOut }
            if let message {
                Text(message.text).font(.footnote).foregroundStyle(message.bad ? Color.red : p.bad)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(p.chip, in: RoundedRectangle(cornerRadius: 20))
    }

    private func signedIn(_ who: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(String(who.prefix(1)).uppercased()).font(.system(.title3, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 40, height: 40).background(p.bad, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(who).font(.system(.subheadline, weight: .semibold)).foregroundStyle(p.text)
                    Text("Your results stay on this device. Syncing bests comes later.").font(.footnote).foregroundStyle(p.dim)
                }
            }
            HStack(spacing: 8) {
                GlassButton("Log Out", p: p) { Task { await account.logOut(); say("Logged out.") } }
                GlassButton(armed ? "Click again to delete" : "Delete Account", p: p, destructive: true) { delete() }
            }
        }
    }

    private var signedOut: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Log in | Sign up, the same pill switch as the mode bar
            HStack(spacing: 4) {
                tab("Log In", !signingUp) { signingUp = false; message = nil }
                tab("Sign Up", signingUp) { signingUp = true; message = nil }
            }
            .padding(4).background(p.bg.opacity(0.6), in: Capsule())

            // Apple, Google, GitHub
            VStack(spacing: 8) {
                // Our own capsule, full width like the rest (the stock button won't stretch on macOS 13); same request
                Button { startApple() } label: {
                    HStack(spacing: 6) { Image(systemName: "applelogo"); Text(signingUp ? "Sign up with Apple" : "Sign in with Apple").fontWeight(.semibold) }
                        .font(.subheadline).foregroundStyle(scheme == .dark ? Color.black : Color.white)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(scheme == .dark ? Color.white : Color.black, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(signingUp ? "Sign up with Apple" : "Sign in with Apple")
                HStack(spacing: 8) {
                    GlassButton("Google", icon: "g.circle", p: p, soon: true) {}
                    GlassButton("GitHub", icon: "chevron.left.forwardslash.chevron.right", p: p, soon: true) {}
                }
            }

            HStack { line; Text("or with email").font(.caption).foregroundStyle(p.dim); line }

            VStack(spacing: 8) {
                field("Email", text: $email, secure: false)
                field(signingUp ? "Password, 8 or more characters" : "Password", text: $password, secure: true)
            }
            GlassButton(signingUp ? "Create Account" : "Log In", p: p, prominent: true, disabled: account.busy || email.isEmpty || password.isEmpty, action: go)
                .keyboardShortcut(.defaultAction)
            HStack {
                Text("One account for Keyrate and the other Jaybulb apps.").font(.caption).foregroundStyle(p.dim)
                Spacer()
                if !signingUp {
                    Button("Forgot password?", action: reset).buttonStyle(.plain).font(.system(.caption, weight: .medium))
                        .foregroundStyle(p.text).underline().disabled(account.busy || email.isEmpty)
                }
            }
        }
    }
    @Environment(\.colorScheme) private var scheme

    private var line: some View { Rectangle().fill(p.dim.opacity(0.25)).frame(height: 1) }

    private func tab(_ label: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(.footnote, weight: on ? .semibold : .regular)).foregroundStyle(on ? p.text : p.dim)
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(on ? p.bg : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func field(_ label: String, text: Binding<String>, secure: Bool) -> some View {
        Group {
            if secure { SecureField(label, text: text).textContentType(.password).onSubmit(go) }
            else { TextField(label, text: text).textContentType(.username).autocorrectionDisabled() }
        }
        .textFieldStyle(.plain).font(.subheadline).foregroundStyle(p.text)
        .padding(.horizontal, 14).frame(height: 44)
        .background(p.bg, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(p.dim.opacity(0.25)))
        .accessibilityLabel(label)
    }

    private func say(_ t: String, bad: Bool = false) { message = (t, bad) }

    private func go() {
        let e = email.trimmingCharacters(in: .whitespaces)
        guard e.contains("@"), e.contains(".") else { return say("Enter a valid email address.", bad: true) }
        guard password.count >= 8 else { return say("Passwords are at least 8 characters.", bad: true) }
        Task {
            do {
                if signingUp { try await account.signUp(email: e, password: password); password = ""; signingUp = false; say("Check your email for a link to confirm your account, then log in.") }
                else { try await account.logIn(email: e, password: password); password = ""; message = nil }
            } catch { say(error.localizedDescription, bad: true) }
        }
    }

    @State private var appleFlow: AppleFlow?
    private func startApple() {
        nonce = UUID().uuidString
        let req = ASAuthorizationAppleIDProvider().createRequest()
        req.requestedScopes = [.email, .fullName]
        req.nonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        let flow = AppleFlow { apple($0) }
        appleFlow = flow
        flow.run(req)
    }

    private func apple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let c = auth.credential as? ASAuthorizationAppleIDCredential, let t = c.identityToken, let token = String(data: t, encoding: .utf8) else {
                return say("Apple didn't send a sign-in token. Try again.", bad: true)
            }
            let name = [c.fullName?.givenName, c.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            Task { do { try await account.signInWithApple(idToken: token, nonce: nonce, fullName: name); message = nil } catch { say(error.localizedDescription, bad: true) } }
        case .failure(let e):
            if (e as? ASAuthorizationError)?.code == .canceled { return }
            say("Sign in with Apple isn't available in this build yet. Use email for now.", bad: true)
        }
    }

    private func reset() {
        Task {
            do { try await account.resetPassword(email: email.trimmingCharacters(in: .whitespaces)); say("If there is an account for that email, a reset link is on its way.") }
            catch { say(error.localizedDescription, bad: true) }
        }
    }

    private func delete() {
        guard armed else { armed = true; Task { try? await Task.sleep(for: .seconds(4)); armed = false }; return }
        Task {
            do { try await account.deleteAccount(); say("Your account is deleted.") } catch { say(error.localizedDescription, bad: true) }
            armed = false
        }
    }
}

/// Runs one Sign in with Apple request and hands back the result; held in state until it finishes.
private final class AppleFlow: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let done: (Result<ASAuthorization, Error>) -> Void
    init(_ done: @escaping (Result<ASAuthorization, Error>) -> Void) { self.done = done }
    func run(_ req: ASAuthorizationAppleIDRequest) {
        let c = ASAuthorizationController(authorizationRequests: [req]); c.delegate = self; c.presentationContextProvider = self; c.performRequests()
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization a: ASAuthorization) { done(.success(a)) }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError e: Error) { done(.failure(e)) }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(macOS)
        NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
        #else
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
        #endif
    }
}

/// A capsule button: Liquid Glass on iOS and macOS 26 (prominent for the main action), a plain capsule before.
private struct GlassButton: View {
    let title: String, icon: String?, p: Palette
    var prominent = false, destructive = false, soon = false, disabled = false
    let action: () -> Void
    init(_ title: String, icon: String? = nil, p: Palette, prominent: Bool = false, destructive: Bool = false, soon: Bool = false, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.p = p; self.prominent = prominent; self.destructive = destructive; self.soon = soon; self.disabled = disabled; self.action = action
    }

    var body: some View {
        let label = HStack(spacing: 6) {
            if let icon { Image(systemName: icon) }
            Text(title).fontWeight(prominent ? .semibold : .medium)
            if soon { Text("soon").font(.caption2).foregroundStyle(p.dim) }
        }
        .font(.subheadline).frame(maxWidth: .infinity, minHeight: 40)
        let fg: Color = destructive ? .red : prominent ? p.bg : p.text
        #if compiler(>=6.2)
        if #available(iOS 26, macOS 26, *) {
            if prominent {
                Button(action: action) { label.foregroundStyle(fg) }.buttonStyle(.glassProminent).tint(p.text).disabled(disabled || soon)
            } else {
                Button(action: action) { label.foregroundStyle(fg) }.buttonStyle(.glass).disabled(disabled || soon)
            }
        } else { fallback(label, fg) }
        #else
        fallback(label, fg)
        #endif
    }

    private func fallback(_ label: some View, _ fg: Color) -> some View {
        Button(action: action) {
            label.foregroundStyle(fg)
                .background(prominent ? p.text : p.bg, in: Capsule())
                .overlay(Capsule().stroke(prominent ? .clear : p.dim.opacity(0.25)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(disabled || soon ? 0.45 : 1)
        .disabled(disabled || soon)
    }
}

// MARK: - Appearance

/// Three cards, each a tiny Keyrate window in that appearance: a mode bar, three lines of words, one blue key.
private struct AppearancePicker: View {
    let p: Palette
    var vertical = true
    @AppStorage("appearance") private var appearance = Appearance.system

    var body: some View {
        let layout = vertical ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        layout {
            ForEach(Appearance.allCases) { a in
                Button { appearance = a } label: {
                    HStack(spacing: 12) {
                        Text(a == .system ? "Auto" : a.label).font(.system(.footnote, weight: appearance == a ? .semibold : .regular))
                            .foregroundStyle(appearance == a ? p.text : p.dim).frame(width: 40, alignment: .leading)
                        preview(a)
                            .frame(height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(appearance == a ? p.bad : p.dim.opacity(0.25), lineWidth: appearance == a ? 2 : 1))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(a == .system ? "Auto, follows your device" : a.label)
                .accessibilityAddTraits(appearance == a ? .isSelected : [])
            }
        }
    }

    @ViewBuilder private func preview(_ a: Appearance) -> some View {
        switch a {
        case .light: mini(.light)
        case .dark: mini(.dark)
        case .system: // half and half, split down the middle
            HStack(spacing: 0) { mini(.light); mini(.dark) } // each half its own slice, so both show words
        }
    }

    /// A slice of the test: one line of words across the whole width, the typed part solid, one missed key blue.
    private func mini(_ m: Palette) -> some View {
        // more words than fit, clipped: the line runs edge to edge, so Auto shows it on both halves
        HStack(spacing: 4) {
            bar(m, 18, true); bar(m, 12, true); RoundedRectangle(cornerRadius: 2).fill(m.bad).frame(width: 8, height: 6)
            ForEach(Array([20, 14, 22, 10, 16, 24, 12, 18, 14, 20, 10, 22, 16].enumerated()), id: \.offset) { bar(m, CGFloat($0.element)) }
        }
        .fixedSize()
        .padding(.leading, 12)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // minWidth 0: never wider than its slot
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(m.bg)
    }

    private func bar(_ m: Palette, _ w: CGFloat, _ typed: Bool = false) -> some View {
        Capsule().fill(typed ? m.text : m.word).frame(width: w, height: 5)
    }
}
