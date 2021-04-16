//
//  File.swift
//  
//
//  Created by Matthias Felix on 15.04.21.
//

import Foundation
import HKDF

public final class CryptoUtilsBase {

    private static let hkdfDomainKey = "CrowdNotifier_v3"

    public static func getNoncesAndNotificationKey(qrCodePayload: Bytes) -> (nonce1: Bytes, nonce2: Bytes, notificationKey: Bytes)? {
        // Length: 32 bytes each for nonce1, nonce2 & notification_key
        let length = 32 + 32 + 32
        let hkdfKey = HKDF.deriveKey(seed: qrCodePayload.data, info: hkdfDomainKey.bytes.data, salt: Bytes().data, count: length)

        guard hkdfKey.count == length else {
            return nil
        }

        let nonce1 = Bytes(hkdfKey[0..<32])
        let nonce2 = Bytes(hkdfKey[32..<64])
        let notificationKey = Bytes(hkdfKey[64..<96])

        return (nonce1, nonce2, notificationKey)
    }
}
