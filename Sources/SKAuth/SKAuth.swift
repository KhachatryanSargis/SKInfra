/// SKAuth — Firebase-backed implementation of ``SKCore/Auth``.
///
/// Wraps `FirebaseAuth` and exposes a single concrete type,
/// ``FirebaseAuthAdapter``, that conforms to the protocol-neutral
/// ``SKCore/Auth`` surface. Sign-in providers handled today: Sign in with
/// Apple.
///
/// ## Composition
///
/// Consumers register `FirebaseAuthAdapter` in the DI container's
/// composition root and depend on ``SKCore/Auth`` everywhere else. Feature
/// code never imports `FirebaseAuth` directly.
///
/// ```swift
/// // App.swift
/// FirebaseApp.configure()
///
/// container.register(Auth.self, scope: .singleton) {
///     FirebaseAuthAdapter()
/// }
/// ```
///
/// ## Sign in with Apple
///
/// SKAuth deliberately does *not* wrap the
/// `ASAuthorizationAppleIDProvider` UI flow — that lives in the consumer
/// because the presentation context belongs to the app. The consumer runs
/// the ASAuthorization flow, then passes the resulting identity token
/// and the raw nonce into ``SKCore/Auth/signIn(with:)`` as a
/// ``SKCore/AuthCredential/apple(idToken:rawNonce:fullName:)`` credential.
///
/// Use ``SignInWithAppleNonce`` to generate the nonce — it produces both
/// the raw value (kept and passed to SKAuth) and the SHA-256 hash (sent to
/// `ASAuthorizationOpenIDRequest.nonce`).
