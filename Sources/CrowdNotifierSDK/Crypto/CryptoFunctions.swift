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
    static func createCheckinEntry(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> (epk: Bytes, h: Bytes, ctxt: Bytes)? {

        var randomValue = Bytes(count: crypto_box_publickeybytes())
        randombytes(&randomValue, UInt64(randomValue.count))

        var gr = Bytes(count: crypto_box_publickeybytes())
        var result = crypto_scalarmult(&gr, randomValue, venueInfo.publicKey.bytes)

        if result != 0 {
            print("crypt_scalarmult failed")
            return nil
        }

        var h = Bytes(count: crypto_box_publickeybytes())
        result = crypto_scalarmult(&h, randomValue, venueInfo.publicKey.bytes)

        if result != 0 {
            print("crypt_scalarmultt failed")
            return nil
        }

        guard let venueBytes = venueInfoToBytes(venueInfo) else {
            print("venueInfoToBytes failed")
            return nil
        }

        let infoConcatR1 = venueBytes + venueInfo.r1.bytes
        var t = Bytes(count: crypto_generichash_bytes())

        result = crypto_hash(&t, infoConcatR1, UInt64(infoConcatR1.count))

        if result != 0 {
            print("crypt_scalarmultt failed")
            return nil
        }

        let aux = CheckinPayload(arrivalTime: arrivalTime, departureTime: departureTime, notificationKey: venueInfo.notificationKey)

        guard let m = try? JSONEncoder().encode(aux).bytes else {
            print("Could not encode payload")
            return nil
        }

        let tConcatAux = t + m

        var cipher = Bytes(count: tConcatAux.count + crypto_box_sealbytes())

        result = crypto_box_seal(&cipher, tConcatAux, UInt64(tConcatAux.count), venueInfo.publicKey.bytes)

        if result != 0 {
            print("crypto_box_seal failed")
            return nil
        }

        return (epk: gr, h: h, ctxt: cipher)
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

    static func decryptPayload(ciphertext: Bytes, privateKey: Bytes, r2: Bytes) -> CheckinPayload? {
        var gR = Bytes(count: crypto_box_publickeybytes())

        var result = crypto_scalarmult_base(&gR, privateKey)

        if result != 0 {
            print("Error during crypto_scalarmult_base")
            return nil
        }

        var tConcatAux = Bytes(count: ciphertext.count - crypto_box_sealbytes())
        result = crypto_box_seal_open(&tConcatAux, ciphertext, UInt64(ciphertext.count), gR, privateKey)

        if result != 0 {
            print("Error during crypto_box_seal_open")
            return nil
        }

        let t = tConcatAux.prefix(crypto_generichash_bytes())
        let aux = tConcatAux.suffix(from: crypto_generichash_bytes())

        let tConcatR2 = t + r2

        var skP = Bytes(count: crypto_box_publickeybytes())

        result = crypto_hash_sha256(&skP, tConcatR2.bytes, UInt64(tConcatR2.count))

        if result != 0 {
            print("Error during crypto_box_seal_open")
            return nil
        }

        var venuePublicKey = Bytes(count: crypto_box_publickeybytes())
        var venuePrivateKey = Bytes(count: crypto_box_secretkeybytes())

        result = crypto_box_seed_keypair(&venuePublicKey, &venuePrivateKey, skP)

        
        return try? JSONDecoder().decode(CheckinPayload.self, from: aux.bytes.data)
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

    // MARK: - Helpers

    private static func venueInfoToBytes(_ venueInfo: VenueInfo) -> Bytes?
    {
        var content = QRCodeContent()
        content.location = venueInfo.location

        if let r = venueInfo.room {
            content.room = r
        }

        content.name = venueInfo.name
        content.notificationKey = venueInfo.notificationKey
        content.validTo = UInt64(venueInfo.validTo.millisecondsSince1970)
        content.validFrom = UInt64(venueInfo.validFrom.millisecondsSince1970)
        content.venueType = QRCodeContent.VenueType.fromVenueType(venueInfo.venueType)

        return try? content.serializedData().bytes
    }
}
