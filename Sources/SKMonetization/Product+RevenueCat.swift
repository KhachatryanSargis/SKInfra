import Foundation

import RevenueCat

import SKCore

// MARK: - Product ← RevenueCat.StoreProduct

internal extension SKCore.Product {

    init(rcProduct: RevenueCat.StoreProduct) {
        self.init(
            id: rcProduct.productIdentifier,
            localizedTitle: rcProduct.localizedTitle,
            localizedDescription: rcProduct.localizedDescription,
            price: rcProduct.price,
            localizedPriceString: rcProduct.localizedPriceString,
            currencyCode: rcProduct.currencyCode,
            subscriptionPeriod: rcProduct.subscriptionPeriod.map {
                SKCore.SubscriptionPeriod(rcPeriod: $0)
            },
            introductoryDiscount: rcProduct.introductoryDiscount.map {
                SKCore.ProductDiscount(rcDiscount: $0)
            }
        )
    }
}

// MARK: - SubscriptionPeriod ← RevenueCat

internal extension SKCore.SubscriptionPeriod {

    init(rcPeriod: RevenueCat.SubscriptionPeriod) {
        self.init(
            unit: SKCore.SubscriptionPeriod.Unit(rcUnit: rcPeriod.unit),
            value: rcPeriod.value
        )
    }
}

internal extension SKCore.SubscriptionPeriod.Unit {

    init(rcUnit: RevenueCat.SubscriptionPeriod.Unit) {
        switch rcUnit {
        case .day:   self = .day
        case .week:  self = .week
        case .month: self = .month
        case .year:  self = .year
        @unknown default: self = .month
        }
    }
}

// MARK: - ProductDiscount ← RevenueCat

internal extension SKCore.ProductDiscount {

    init(rcDiscount: RevenueCat.StoreProductDiscount) {
        self.init(
            price: rcDiscount.price,
            localizedPriceString: rcDiscount.localizedPriceString,
            paymentMode: SKCore.ProductDiscount.PaymentMode(rcMode: rcDiscount.paymentMode),
            period: SKCore.SubscriptionPeriod(rcPeriod: rcDiscount.subscriptionPeriod),
            numberOfPeriods: rcDiscount.numberOfPeriods
        )
    }
}

internal extension SKCore.ProductDiscount.PaymentMode {

    init(rcMode: RevenueCat.StoreProductDiscount.PaymentMode) {
        switch rcMode {
        case .freeTrial:  self = .freeTrial
        case .payUpFront: self = .payUpFront
        case .payAsYouGo: self = .payAsYouGo
        @unknown default: self = .payAsYouGo
        }
    }
}
