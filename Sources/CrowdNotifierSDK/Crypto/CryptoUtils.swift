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
import libmcl

typealias EncryptedCheckinData = (c1: Bytes, c2: Bytes, c3: Bytes, nonce: Bytes)

final class CryptoUtils {

    private static let NONCE_LENGTH: Int = 32

    static func createCheckinEntry(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date, hour: Int) -> EncryptedCheckinData? {

        var masterPublicKey = mclBnG2()
        mclBnG2_deserialize(&masterPublicKey, venueInfo.masterPublicKey.bytes, venueInfo.masterPublicKey.bytes.count)

        guard let info = venueInfoToBytes(venueInfo) else {
            return nil
        }

        let aux = CheckinPayload(arrivalTime: arrivalTime, departureTime: departureTime, notificationKey: venueInfo.notificationKey)

        guard let encodedAux = try? JSONEncoder().encode(aux).bytes else {
            return nil
        }

        var proof = EntryProof()
        proof.nonce1 = venueInfo.nonce1
        proof.nonce2 = venueInfo.nonce2

        return scan(masterPublicKey: masterPublicKey, entryProof: proof, info: info, hour: hour, aux: encodedAux)
    }

    private static func scan(masterPublicKey: mclBnG2, entryProof: EntryProof, info: Bytes, hour: Int, aux: Bytes) -> EncryptedCheckinData? {
        guard let id = genId(info: info, hour: hour, nonce1: entryProof.nonce1.bytes, nonce2: entryProof.nonce2.bytes) else {
            return nil
        }

        return enc(masterPublicKey: masterPublicKey, id: id, aux: aux)
    }

    private static func genId(info: Bytes, hour: Int, nonce1: Bytes, nonce2: Bytes) -> Bytes? {
        let combined = info + nonce1

        guard let hash = sha256(input: combined) else {
            return nil
        }

        return sha256(input: hash + nonce2 + "\(hour)".bytes)
    }

    private static func enc(masterPublicKey: mclBnG2, id: Bytes, aux: Bytes) -> EncryptedCheckinData? {
        var x = Bytes(count: NONCE_LENGTH)
        randombytes(&x, UInt64(x.count))

        let combined = x + id + aux

        var r = mclBnFr()
        mclBnFr_setHashOf(&r, combined, combined.count)

        var g2 = baseG2()

        var c1 = mclBnG2()
        mclBnG2_mul(&c1, &g2, &r)

        var identity = id
        var g1_temp = mclBnG1()
        mclBnG1_hashAndMapTo(&g1_temp, &identity, identity.count)

        var mpk = masterPublicKey
        var gt1_temp = mclBnGT()
        mclBn_pairing(&gt1_temp, &g1_temp, &mpk)

        var gt_temp = mclBnGT()
        mclBnGT_pow(&gt_temp, &gt1_temp, &r)

        var serializedGT = Bytes(count: Int(mclBn_getG1ByteSize() * 12))
        mclBnGT_serialize(&serializedGT, Int(mclBn_getG1ByteSize() * 12), &gt_temp)
        guard let c2_pair = sha256(input: serializedGT) else {
            return nil
        }

        let c2 = xor(a: x, b: c2_pair)

        var nonce = Bytes(count: crypto_secretbox_noncebytes())
        randombytes(&nonce, UInt64(nonce.count))

        var c3 = Bytes(count: aux.count + crypto_secretbox_macbytes())

        guard let k = sha256(input: x) else {
            return nil
        }

        let result = crypto_secretbox_easy(&c3, aux, UInt64(aux.count), nonce, k)

        if result != 0 {
            print("crypto_secretbox_easy failed")
            return nil
        }

        var serializedC1 = Bytes(count: Int(mclBn_getG1ByteSize() * 2))
        mclBnG2_serialize(&serializedC1, Int(mclBn_getG1ByteSize() * 2), &c1)

        return (serializedC1, c2, c3, nonce)
    }

    static func searchAndDecryptMatches(eventInfo: ProblematicEventInfo, visits: [CheckinEntry]) -> [ExposureEvent] {
        var events = [ExposureEvent]()

        for visit in visits {
            var sk = eventInfo.secretKeyForIdentity
            var secretKeyForIdentity = mclBnG1()
            mclBnG1_deserialize(&secretKeyForIdentity, &sk, sk.count)

            if let msg_p = decryptInternal(visit: visit, secretKeyForIdentity: secretKeyForIdentity, identity: eventInfo.identity), let payload = try? JSONDecoder().decode(CheckinPayload.self, from: msg_p.data) {
                var notificationKey = payload.notificationKey.bytes
                var decryptedMessage = Bytes(count: eventInfo.encryptedMessage.count)
                let result = crypto_secretbox_open_easy(&decryptedMessage, eventInfo.encryptedMessage, UInt64(eventInfo.encryptedMessage.count), &notificationKey, eventInfo.nonce)

                let decryptedMessageString: String
                if result != 0 {
                    print("crypto_secretbox_open_easy failed")
                    decryptedMessageString = ""
                } else {
                    decryptedMessageString = String(data: decryptedMessage.data, encoding: .utf8) ?? ""
                }

                events.append(ExposureEvent(checkinId: visit.id, arrivalTime: payload.arrivalTime, departureTime: payload.departureTime, message: decryptedMessageString))
            }
        }

        return events
    }

    private static func decryptInternal(visit: CheckinEntry, secretKeyForIdentity: mclBnG1, identity: Bytes) -> Bytes? {
        var c1Bytes = visit.c1.bytes
        var c1 = mclBnG2()
        mclBnG2_deserialize(&c1, &c1Bytes, c1Bytes.count)

        var gt_temp = mclBnGT()
        var sk = secretKeyForIdentity
        mclBn_pairing(&gt_temp, &sk, &c1)

        var serializedGT = Bytes(count: Int(mclBn_getG1ByteSize() * 12))
        mclBnGT_serialize(&serializedGT, serializedGT.count, &gt_temp)

        guard let hash = sha256(input: serializedGT) else {
            return nil
        }

        let x_p = xor(a: visit.c2.bytes, b: hash)
        guard let x_p_hash = sha256(input: x_p) else {
            return nil
        }

        var c3Bytes = visit.c3.bytes
        var nonceBytes = visit.nonce.bytes
        var msg_p = Bytes(count: c3Bytes.count - crypto_secretbox_macbytes())
        let result = crypto_secretbox_open_easy(&msg_p, &c3Bytes, UInt64(c3Bytes.count), &nonceBytes, x_p_hash)

        if result != 0 {
            print("decryptInternal failed")
            return nil
        }

        // Additional verification
        var r_p = mclBnFr()
        var combined = x_p + identity + msg_p
        mclBnFr_setHashOf(&r_p, &combined, combined.count)

        var c1_p = mclBnG2()
        var g2 = baseG2()
        mclBnG2_mul(&c1_p, &g2, &r_p)

        let isEqual = mclBnG2_isEqual(&c1, &c1_p)
        print("isEqual: \(isEqual)")
        if isEqual != 1 {
            return nil
        }

        let isValidOrder = mclBnG1_isValidOrder(&sk)
        let isZero = mclBnG1_isZero(&sk)
        print("isValidOrder: \(isValidOrder), isZero: \(isZero)")
        if isValidOrder != 1 || isZero != 1 {
            return nil
        }

        return msg_p
    }

    private static func sha256(input: Bytes) -> Bytes? {
        var hash = Bytes(count: crypto_hash_sha256_bytes())
        let result = crypto_hash_sha256(&hash, input, UInt64(input.count))

        if result != 0 {
            print("crypto_hash_sha256 failed")
            return nil
        }

        return hash
    }

    private static func xor(a: Bytes, b: Bytes) -> Bytes {
        assert(a.count == b.count, "a and b must have equal length")

        var c = Bytes(count: a.count)
        for i in 0..<a.count {
            c[i] = a[i] ^ b[i]
        }

        return c
    }

    private static func baseG2() -> mclBnG2 {
        let baseString = ("1 3527010695874666181871391160110601448900299527927752" +
                            "40219908644239793785735715026873347600343865175952761926303160 " +
                            "305914434424421370997125981475378163698647032547664755865937320" +
                            "6291635324768958432433509563104347017837885763365758 " +
                            "198515060228729193556805452117717163830086897821565573085937866" +
                            "5066344726373823718423869104263333984641494340347905 " +
                            "927553665492332455747201965776037880757740193453592970025027978" +
                            "793976877002675564980949289727957565575433344219582").bytes.map(Int8.init)

        var baseG2 = mclBnG2()
        mclBnG2_setStr(&baseG2, baseString, baseString.count, 10)

        return baseG2
    }

    // MARK: - Helpers

    private static func venueInfoToBytes(_ venueInfo: VenueInfo) -> Bytes? {
        var content = QRCodeContent()
        content.name = venueInfo.name
        content.location = venueInfo.location
        if let r = venueInfo.room {
            content.room = r
        }
        content.notificationKey = venueInfo.notificationKey
        content.venueType = .fromVenueType(venueInfo.venueType)

        return try? content.serializedData().bytes
    }
}
