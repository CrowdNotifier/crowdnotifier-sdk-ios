//
//  File.swift
//  
//
//  Created by Matthias Felix on 15.04.21.
//

import Foundation

struct TestVector: Decodable {

    let identityTestVector: [IdentityTestVector]
    let hkdfTestVector: [HkdfTestVector]

    struct IdentityTestVector: Decodable {
        let startOfInterval: Int
        let qrCodePayload: [Int8]
        let identity: [Int8]
    }

    struct HkdfTestVector: Decodable {
        let qrCodePayload: [Int8]
        let nonce1: [Int8]
        let nonce2: [Int8]
        let notificationKey: [Int8]
    }
}
