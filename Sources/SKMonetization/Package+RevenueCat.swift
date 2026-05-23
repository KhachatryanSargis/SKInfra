import Foundation

import RevenueCat

import SKCore

// MARK: - Package ← RevenueCat.Package

internal extension SKCore.Package {

    init(rcPackage: RevenueCat.Package) {
        self.init(
            id: rcPackage.identifier,
            packageType: SKCore.PackageType(rcType: rcPackage.packageType),
            product: SKCore.Product(rcProduct: rcPackage.storeProduct),
            offeringIdentifier: rcPackage.offeringIdentifier
        )
    }
}

// MARK: - PackageType ← RevenueCat.PackageType

internal extension SKCore.PackageType {

    init(rcType: RevenueCat.PackageType) {
        switch rcType {
        case .monthly:    self = .monthly
        case .annual:     self = .annual
        case .weekly:     self = .weekly
        case .twoMonth:   self = .twoMonth
        case .threeMonth: self = .threeMonth
        case .sixMonth:   self = .sixMonth
        case .lifetime:   self = .lifetime
        case .custom:     self = .custom("custom")
        case .unknown:    self = .unknown
        @unknown default: self = .unknown
        }
    }
}
