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
        let esk = sodium.randomBytes.buf(length: 32)!

        var epk = Bytes(repeating: 0, count: 32)
        Clibsodium.crypto_scalarmult_ed25519_base(&epk, esk)

        var h = Bytes(repeating: 0, count: 32)
        _ = Clibsodium.crypto_scalarmult_ed25519(&h, esk, epk)

        return (epk, h)
    }

    static func encryptVenuePayload(from checkinPayload: CheckinPayload, pk: Bytes) -> Bytes? {
        var pk_curve25519 = Bytes(repeating: 0, count: 32)
        _ = Clibsodium.crypto_sign_ed25519_pk_to_curve25519(&pk_curve25519, pk)

        guard let m = try? JSONSerialization.data(withJSONObject: checkinPayload, options: []) else {
            return nil
        }

        return sodium.box.seal(message: m.bytes, recipientPublicKey: pk_curve25519)
    }

}
