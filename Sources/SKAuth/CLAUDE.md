# SKAuth — Module Rules

FirebaseAuth-backed implementation of `SKCore.Auth`. Wraps the
`FirebaseAuth.Auth` lifecycle and the `OAuthProvider.appleCredential` exchange
behind the protocol-neutral surface so feature code never imports
`FirebaseAuth` directly. Sign-in providers handled today: Sign in with Apple.

The consumer is responsible for running the `ASAuthorizationAppleIDProvider`
UI flow itself — `SignInWithAppleNonce` produces the matched raw/hashed nonce
pair for the request, and `Auth.signIn(with: .apple(...))` consumes the
resulting identity token.

## Structure

```
SKAuth/
├── SKAuth.swift                 — Module docstring (no code)
├── FirebaseAuthAdapter.swift    — Auth conformance + state listener
├── AuthUser+Firebase.swift      — FirebaseAuth.User → AuthUser projection
├── AuthError+Firebase.swift     — AuthErrorCode → AuthError mapping (+ Sendable error wrapper)
└── SignInWithAppleNonce.swift   — Raw + SHA-256-hashed nonce pair generator
```

## Gotchas

- `FirebaseApp.configure()` must run **before** any `FirebaseAuthAdapter` is
  constructed. The adapter assumes the default `FirebaseApp` is already set
  up; use the `init(firebaseAuth:)` overload for non-default FirebaseApp
  setups.
- `FirebaseAuth.User` doesn't conform to `Sendable`. The adapter never
  exposes it — every public method projects it through `AuthUser` first.
- Firebase's `addStateDidChangeListener` fires shortly after registration
  with the current cached user (or `nil`). Until that first callback, the
  adapter is in `AuthState.unknown`. Subscribers that arrive after the
  first concrete state see that state immediately, not `.unknown`.
- The Apple nonce flow is brittle: the **hashed** value goes on
  `ASAuthorizationOpenIDRequest.nonce`, the **raw** value goes into
  `AuthCredential.apple(...)`. `SignInWithAppleNonce` exists precisely so
  callers stop mixing these up.
