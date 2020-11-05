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
import Clibsodium

class CryptoFunctions {

    static func createPublicAndSharedKey() -> (publicKey: Bytes, sharedKey: Bytes) {
        var esk = Bytes(count: crypto_scalarmult_scalarbytes())
        randombytes(&esk, UInt64(esk.count))

        var epk = Bytes(count: crypto_scalarmult_ed25519_bytes())
        crypto_scalarmult_ed25519_base(&epk, esk)

        var h = Bytes(count: crypto_scalarmult_ed25519_bytes())
        let result = crypto_scalarmult_ed25519(&h, esk, epk)

        if result != 0 {
            print("Clibsodium.crypto_scalarmult(&h, esk, epk) failed!")
        }

        return (epk, h)
    }

    static func encryptVenuePayload(from checkinPayload: CheckinPayload, pk: Bytes) -> Bytes? {
        guard let m = try? JSONEncoder().encode(checkinPayload) else {
            return nil
        }

        var pk_curve25519 = Bytes(count: crypto_box_publickeybytes())
        _ = crypto_sign_ed25519_pk_to_curve25519(&pk_curve25519, pk)

        var encrypted = Bytes(count: crypto_box_sealbytes() + m.count)
        crypto_box_seal(&encrypted, m.bytes, UInt64(m.count), pk_curve25519)

        return encrypted
    }

    static func computeSharedKey(privateKey: Bytes, publicKey: Bytes) -> Bytes {
        var sharedKey = Bytes(count: crypto_scalarmult_ed25519_bytes())
        let result = crypto_scalarmult_ed25519(&sharedKey, privateKey, publicKey)

        if result != 0 {
            print("Clibsodium.crypto_scalarmult(&h, esk, epk) failed!")
        }

        return sharedKey
    }

    static func decryptPayload(ciphertext: Bytes, privateKey: Bytes) -> CheckinPayload? {
        var publicKey = Bytes(count: crypto_scalarmult_curve25519_bytes())
        crypto_scalarmult_curve25519_base(&publicKey, privateKey)

        var data = Bytes(count: ciphertext.count - crypto_box_sealbytes())
        let result = crypto_box_seal_open(&data, ciphertext, UInt64(ciphertext.count), publicKey, privateKey)

        if result != 0 {
            print("Error during crypto_box_seal_open")
            return nil
        }

        return try? JSONDecoder().decode(CheckinPayload.self, from: data.data)
    }

}
