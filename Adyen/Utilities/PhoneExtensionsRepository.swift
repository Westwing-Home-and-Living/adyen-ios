//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// :nodoc:
public enum PhoneNumberPaymentMethod {

    /// :nodoc:
    case qiwiWallet

    /// :nodoc:
    case mbWay

    /// :nodoc:
    internal var codes: [String] {
        switch self {
        case .qiwiWallet:
            return ["RU",
                    "GE",
                    "PA",
                    "GB",
                    "TJ",
                    "LT",
                    "IL",
                    "KG",
                    "UA",
                    "VN",
                    "TR",
                    "AZ",
                    "AM",
                    "LV",
                    "IN",
                    "TH",
                    "MD",
                    "US",
                    "JP",
                    "UZ",
                    "KZ",
                    "BY",
                    "EE",
                    "RO",
                    "KR"]
        case .mbWay:
            return ["PT", "ES"]
        }
    }
}

/// :nodoc:
public struct PhoneExtensionsQuery {

    /// :nodoc:
    public let codes: [String]

    /// :nodoc:
    public init(codes: [String]) {
        let validator = CountryCodeValidator()
        self.codes = codes.filter { validator.isValid($0) }
    }

    /// :nodoc:
    public init(paymentMethod: PhoneNumberPaymentMethod) {
        self.init(codes: paymentMethod.codes)
    }
}

/// :nodoc:
public struct PhoneExtensionsRepository {

    /// :nodoc:
    public static func get(with query: PhoneExtensionsQuery) -> [PhoneExtension] {
        return query.codes.compactMap {
            guard let phoneExtension = allCountriesPhoneExtensions[$0] else {
                return nil
            }
            return PhoneExtension(value: phoneExtension,
                                  countryCode: $0)
        }
    }
}
