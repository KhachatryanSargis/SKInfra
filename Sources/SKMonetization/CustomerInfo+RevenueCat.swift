import Foundation

import RevenueCat

import SKCore

// MARK: - CustomerInfo ← RevenueCat.CustomerInfo

internal extension SKCore.CustomerInfo {

    init(rcCustomerInfo: RevenueCat.CustomerInfo) {
        let entitlements = Dictionary(
            uniqueKeysWithValues: rcCustomerInfo.entitlements.active.map { key, value in
                (key, SKCore.Entitlement(rcEntitlement: value))
            }
        )
        self.init(
            originalAppUserId: rcCustomerInfo.originalAppUserId,
            firstSeen: rcCustomerInfo.firstSeen,
            activeEntitlements: entitlements,
            allPurchasedProductIdentifiers: rcCustomerInfo.allPurchasedProductIdentifiers,
            latestExpirationDate: rcCustomerInfo.latestExpirationDate,
            managementURL: rcCustomerInfo.managementURL
        )
    }
}

// MARK: - Entitlement ← RevenueCat.EntitlementInfo

internal extension SKCore.Entitlement {

    init(rcEntitlement: RevenueCat.EntitlementInfo) {
        self.init(
            id: rcEntitlement.identifier,
            isActive: rcEntitlement.isActive,
            productIdentifier: rcEntitlement.productIdentifier,
            originalPurchaseDate: rcEntitlement.originalPurchaseDate,
            expirationDate: rcEntitlement.expirationDate,
            willRenew: rcEntitlement.willRenew,
            store: Store(rcStore: rcEntitlement.store),
            isBillingRetryPeriod: rcEntitlement.billingIssueDetectedAt != nil,
            periodType: PeriodType(rcPeriodType: rcEntitlement.periodType)
        )
    }
}

// MARK: - Store ← RevenueCat.Store

internal extension SKCore.Entitlement.Store {

    init(rcStore: RevenueCat.Store) {
        switch rcStore {
        case .appStore:     self = .appStore
        case .macAppStore:  self = .macAppStore
        case .playStore:    self = .playStore
        case .stripe:       self = .stripe
        case .promotional:  self = .promotional
        case .unknownStore,
             .amazon,
             .rcBilling,
             .external,
             .paddle,
             .testStore,
             .galaxy:
            self = .unknown
        @unknown default:   self = .unknown
        }
    }
}

// MARK: - PeriodType ← RevenueCat.PeriodType

internal extension SKCore.Entitlement.PeriodType {

    init(rcPeriodType: RevenueCat.PeriodType) {
        switch rcPeriodType {
        case .normal, .prepaid: self = .normal
        case .intro:            self = .intro
        case .trial:            self = .trial
        @unknown default:       self = .normal
        }
    }
}
