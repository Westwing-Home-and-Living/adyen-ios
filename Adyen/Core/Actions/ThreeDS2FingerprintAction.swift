//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// Describes an action in which a 3D Secure device fingerprint is taken.
public struct ThreeDS2FingerprintAction: Decodable {

    /// The 3D Secure authorization token.
    public let authorisationToken: String?
    
    /// The 3D Secure fingerprint token.
    public let token: String
    
    /// The server-generated payment data that should be submitted to the `/payments/details` endpoint.
    public let paymentData: String?
    
    /// Initializes a 3D Secure fingerprint action.
    ///
    /// - Parameters:
    ///   - authorisationToken: The 3D Secure authorization token.
    ///   - token: The 3D Secure challenge token.
    ///   - paymentData: The server-generated payment data that should be submitted to the `/payments/details` endpoint.
    public init(authorisationToken: String?, token: String, paymentData: String?) {
        self.authorisationToken = authorisationToken
        self.token = token
        self.paymentData = paymentData
    }
    
}
