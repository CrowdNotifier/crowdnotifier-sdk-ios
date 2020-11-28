/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Clibsodium
import Foundation

class CryptoFunctions {
    static func createCheckinEntry(notificationKey: Bytes, venuePublicKey: Bytes, arrivalTime: Date, departureTime: Date) -> (epk: Bytes, h: Bytes, ctxt: Bytes)? {
        var pk_venue_kx = Bytes(count: crypto_box_publickeybytes())
        var result = crypto_sign_ed25519_pk_to_curve25519(&pk_venue_kx, venuePublicKey)

        if result != 0 {
            print("crypto_sign_ed25519_pk_to_curve25519 failed")
            return nil
        }

        var ephemeralSecretKey = Bytes(count: crypto_scalarmult_scalarbytes())
        randombytes(&ephemeralSecretKey, UInt64(ephemeralSecretKey.count))

        var ephemeralPublicKey = Bytes(count: crypto_scalarmult_bytes())
        result = crypto_scalarmult_base(&ephemeralPublicKey, ephemeralSecretKey)

        if result != 0 {
            print("crypto_scalarmult_base failed")
            return nil
        }

        var tag = Bytes(count: crypto_scalarmult_bytes())
        result = crypto_scalarmult(&tag, ephemeralSecretKey, pk_venue_kx)

        if result != 0 {
            print("crypto_scalarmult failed")
            return nil
        }

        let payload = CheckinPayload(arrivalTime: arrivalTime, departureTime: departureTime, notificationKey: notificationKey.data)

        guard let m = try? JSONEncoder().encode(payload) else {
            print("Could not encode payload")
            return nil
        }

        var encrypted = Bytes(count: m.count + crypto_box_sealbytes())
        crypto_box_seal(&encrypted, m.bytes, UInt64(m.count), pk_venue_kx)

        return (ephemeralPublicKey, tag, encrypted)
    }

    static func privateKeyEd25519ToCurve25519(privateKey: Bytes) -> Bytes? {
        var curve = Bytes(count: crypto_box_secretkeybytes())
        let result = crypto_sign_ed25519_sk_to_curve25519(&curve, privateKey)

        if result != 0 {
            print("crypto_sign_ed25519_sk_to_curve25519 failed")
            return nil
        }

        return curve
    }

    static func computeSharedKey(privateKey: Bytes, publicKey: Bytes) -> Bytes? {
        var tagPrime = Bytes(count: crypto_scalarmult_bytes())
        let result = crypto_scalarmult(&tagPrime, privateKey, publicKey)

        if result != 0 {
            print("crypto_scalarmult failed")
            return nil
        }

        return tagPrime
    }

    static func decryptPayload(ciphertext: Bytes, privateKey: Bytes) -> CheckinPayload? {
        var pk_venue_kx = Bytes(count: crypto_box_publickeybytes())
        var result = crypto_scalarmult_curve25519_base(&pk_venue_kx, privateKey)

        if result != 0 {
            print("Error during crypto_scalarmult_curve25519_base")
            return nil
        }

        var data = Bytes(count: ciphertext.count - crypto_box_sealbytes())
        result = crypto_box_seal_open(&data, ciphertext, UInt64(ciphertext.count), pk_venue_kx, privateKey)

        if result != 0 {
            print("Error during crypto_box_seal_open")
            return nil
        }

        return try? JSONDecoder().decode(CheckinPayload.self, from: data.data)
    }

    static func decryptMessage(message: Bytes, nonce: Bytes, key: Bytes) -> String? {

        var data = Bytes(count: message.count - crypto_secretbox_macbytes())
        let result = crypto_secretbox_open_easy(&data, message, UInt64(message.count), nonce, key)

        if result != 0 {
            print("Error during crypto_box_open_easy")
            return nil
        }

        return String(data: data.data, encoding: .utf8)
    }
}
