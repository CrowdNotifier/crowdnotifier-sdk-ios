/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation
import Sodium
import Clibsodium

class CryptoFunctions {

    private static let sodium = Sodium()

    static func createPublicAndSharedKey() -> (publicKey: Bytes, sharedKey: Bytes) {
        let esk = sodium.randomBytes.buf(length: crypto_scalarmult_scalarbytes())!

        var epk = Bytes(repeating: 0, count: crypto_scalarmult_ed25519_bytes())
        crypto_scalarmult_ed25519_base(&epk, esk)

        var h = Bytes(repeating: 0, count: crypto_scalarmult_ed25519_bytes())
        let result = crypto_scalarmult_ed25519(&h, esk, epk)

        if result != 0 {
            print("Clibsodium.crypto_scalarmult(&h, esk, epk) failed!")
        }

        return (epk, h)
    }

    static func encryptVenuePayload(from checkinPayload: CheckinPayload, pk: Bytes) -> Bytes? {
        guard let m = try? JSONSerialization.data(withJSONObject: checkinPayload, options: []) else {
            return nil
        }

        var pk_curve25519 = Bytes(repeating: 0, count: crypto_box_publickeybytes())
        _ = crypto_sign_ed25519_pk_to_curve25519(&pk_curve25519, pk)

        return sodium.box.seal(message: m.bytes, recipientPublicKey: pk_curve25519)
    }

    static func computeSharedKey(privateKey: Bytes, publicKey: Bytes) -> Bytes {
        var sharedKey = Bytes(repeating: 0, count: crypto_scalarmult_ed25519_bytes())
        let result = crypto_scalarmult_ed25519(&sharedKey, privateKey, publicKey)

        if result != 0 {
            print("Clibsodium.crypto_scalarmult(&h, esk, epk) failed!")
        }

        return sharedKey
    }

    static func decryptPayload(ciphertext: Bytes, privateKey: Bytes) -> CheckinPayload? {
        var publicKey = Bytes(repeating: 0, count: crypto_scalarmult_curve25519_bytes())
        crypto_scalarmult_curve25519_base(&publicKey, privateKey)

        if let data = sodium.box.open(anonymousCipherText: ciphertext, recipientPublicKey: publicKey, recipientSecretKey: privateKey)?.data {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? CheckinPayload
        }

        return nil
    }

}
