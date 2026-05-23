import Foundation

import FirebaseAuth

import SKCore

// MARK: - AuthUser ← FirebaseAuth.User

internal extension AuthUser {
    /// Projects a Firebase user record onto the protocol-neutral
    /// ``AuthUser`` snapshot.
    init(firebaseUser: FirebaseAuth.User) {
        self.init(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            email: firebaseUser.email,
            photoURL: firebaseUser.photoURL,
            isAnonymous: firebaseUser.isAnonymous,
            providerIDs: firebaseUser.providerData.map(\.providerID),
            creationDate: firebaseUser.metadata.creationDate,
            lastSignInDate: firebaseUser.metadata.lastSignInDate
        )
    }
}
