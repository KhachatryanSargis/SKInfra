import Foundation

import RevenueCat

import SKCore

// MARK: - Offering ← RevenueCat.Offering

internal extension SKCore.Offering {

    init(rcOffering: RevenueCat.Offering) {
        self.init(
            id: rcOffering.identifier,
            serverDescription: rcOffering.serverDescription,
            packages: rcOffering.availablePackages.map {
                SKCore.Package(rcPackage: $0)
            },
            metadata: rcOffering.metadata.compactMapValues { value in
                "\(value)"
            }
        )
    }
}
