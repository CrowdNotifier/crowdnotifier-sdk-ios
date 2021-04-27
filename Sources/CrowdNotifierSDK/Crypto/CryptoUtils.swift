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
import HKDF
import libmcl

final class CryptoUtils {
    private static let NONCE_LENGTH: Int = 32

    private enum DomainKeys {
        static let preid = "CN-PREID"
        static let id = "CN-ID"
    }

    public static func createEncryptedVenueVisits(id: String, arrivalTime: Date, departureTime: Date, venueInfo: VenueInfo) -> [EncryptedVenueVisit] {
        var masterPublicKey = mclBnG2()
        mclBnG2_deserialize(&masterPublicKey, venueInfo.publicKey.bytes, venueInfo.publicKey.bytes.count)

        var encryptedVisits = [EncryptedVenueVisit]()

        for hour in arrivalTime.hoursSince1970 ... departureTime.hoursSince1970 {
            guard let identity = generateIdentityV3(startOfInterval: hour * 3600, qrCodePayload: venueInfo.qrCodePayload.bytes) else {
                continue
            }

            let payload = Payload(arrivalTime: arrivalTime, departureTime: departureTime, notificationKey: venueInfo.notificationKey)

            guard let message = try? JSONEncoder().encode(payload).bytes else {
                continue
            }

            guard let encryptedData = encryptInternal(message: message, identity: identity, masterPublicKey: masterPublicKey) else {
                continue
            }

            encryptedVisits.append(EncryptedVenueVisit(id: id, daysSince1970: arrivalTime.daysSince1970, encryptedData: encryptedData))
        }

        return encryptedVisits
    }

    public static func searchAndDecryptMatches(eventInfo: ProblematicEventInfo, venueVisits: [EncryptedVenueVisit]) -> [ExposureEvent] {
        var exposureEvents = [ExposureEvent]()

        for visit in venueVisits {
            var sk_ = eventInfo.secretKeyForIdentity
            var secretKeyForIdentity = mclBnG1()
            mclBnG1_deserialize(&secretKeyForIdentity, &sk_, sk_.count)

            guard let msg_p = decryptInternal(encryptedData: visit.encryptedData, secretKeyForIdentity: secretKeyForIdentity, identity: eventInfo.identity) else {
                continue
            }

            guard let payload = try? JSONDecoder().decode(Payload.self, from: msg_p.data) else {
                continue
            }

            if let decryptedBytes = crypto_secretbox_open_easy(key: payload.notificationKey.bytes, cipherText: eventInfo.encryptedAssociatedData, nonce: eventInfo.cipherTextNonce), let associatedData = try? AssociatedData(serializedData: decryptedBytes.data) {
                let event = ExposureEvent(checkinId: visit.id,
                                          arrivalTime: payload.arrivalTime,
                                          departureTime: payload.departureTime,
                                          message: associatedData.message,
                                          countryData: associatedData.countryData)
                exposureEvents.append(event)
            }
        }

        return exposureEvents
    }

    public static func generateQRCodeString(baseUrl: String, masterPublicKey: Bytes, description: String, address: String, startTimestamp: Date, endTimestamp: Date, countryData: Data?) -> Result<(VenueInfo, String), CrowdNotifierError> {
        var traceLocation = TraceLocation()
        traceLocation.version = 3
        traceLocation.description_p = description
        traceLocation.address = address
        traceLocation.startTimestamp = UInt64(startTimestamp.timeIntervalSince1970)
        traceLocation.endTimestamp = UInt64(endTimestamp.timeIntervalSince1970)

        var crowdNotifierData = CrowdNotifierData()
        crowdNotifierData.version = 3
        crowdNotifierData.publicKey = masterPublicKey.data
        crowdNotifierData.cryptographicSeed = randombytes_buf().data
        crowdNotifierData.type = 1

        var payload = QRCodePayload()
        payload.version = 3
        payload.locationData = traceLocation
        payload.crowdNotifierData = crowdNotifierData
        payload.countryData = countryData ?? Data()

        guard var components = URLComponents(string: baseUrl) else {
            return .failure(.qrCodeGenerationError)
        }
        components.queryItems = [URLQueryItem(name: "v", value: "3")]
        guard let data = try? payload.serializedData(), let fragment = binToBase64(bytes: data.bytes) else {
            return .failure(.qrCodeGenerationError)
        }
        components.fragment = fragment

        guard let urlString = components.url?.absoluteString else {
            return .failure(.qrCodeGenerationError)
        }

        guard let (nonce1, nonce2, notificationKey) = CryptoUtilsBase.getNoncesAndNotificationKey(qrCodePayload: data.bytes) else {
            return .failure(.qrCodeGenerationError)
        }

        let venueInfo = VenueInfo(description: description, address: address, notificationKey: notificationKey.data, publicKey: masterPublicKey.data, nonce1: nonce1.data, nonce2: nonce2.data, validFrom: startTimestamp.millisecondsSince1970, validTo: endTimestamp.millisecondsSince1970, qrCodePayload: data, countryData: payload.countryData)

        return .success((venueInfo, urlString))
    }

    // MARK: - Private helper methods

    private static func encryptInternal(message: Bytes, identity: Bytes, masterPublicKey: mclBnG2) -> EncryptedData? {
        let nonceX = randombytes_buf()

        let combined: Bytes = nonceX + identity + message
        var r = mclBnFr()
        mclBnFr_setHashOf(&r, combined, combined.count)

        var g2 = baseG2()

        var c1 = mclBnG2()
        mclBnG2_mul(&c1, &g2, &r)

        var identity_ = identity
        var g1_temp = mclBnG1()
        mclBnG1_hashAndMapTo(&g1_temp, &identity_, identity_.count)

        var masterPublicKey_ = masterPublicKey
        var gt1_temp = mclBnGT()
        mclBn_pairing(&gt1_temp, &g1_temp, &masterPublicKey_)

        var gt_temp = mclBnGT()
        mclBnGT_pow(&gt_temp, &gt1_temp, &r)

        var gt_temp_serialized = Bytes(count: Int(mclBn_getG1ByteSize() * 12))
        mclBnGT_serialize(&gt_temp_serialized, gt_temp_serialized.count, &gt_temp)
        guard let c2_pair = crypto_hash_sha256(input: gt_temp_serialized) else {
            return nil
        }

        let c2 = xor(a: nonceX, b: c2_pair)

        let nonce = randombytes_buf()

        guard let nonceXHash = crypto_hash_sha256(input: nonceX) else {
            return nil
        }

        guard let c3 = crypto_secretbox_easy(secretKey: nonceXHash, message: message, nonce: nonce) else {
            return nil
        }

        var c1_serialized = Bytes(count: Int(mclBn_getG1ByteSize() * 2))
        mclBnG2_serialize(&c1_serialized, c1_serialized.count, &c1)

        return EncryptedData(c1: c1_serialized.data, c2: c2.data, c3: c3.data, nonce: nonce.data)
    }

    private static func decryptInternal(encryptedData: EncryptedData, secretKeyForIdentity: mclBnG1, identity: Bytes) -> Bytes? {
        var c1_ = encryptedData.c1.bytes
        var c1 = mclBnG2()
        mclBnG2_deserialize(&c1, &c1_, c1_.count)

        var gt_temp = mclBnGT()
        var secretKeyForIdentity_ = secretKeyForIdentity
        mclBn_pairing(&gt_temp, &secretKeyForIdentity_, &c1)

        var gt_temp_serialized = Bytes(count: Int(mclBn_getG1ByteSize() * 12))
        mclBnGT_serialize(&gt_temp_serialized, gt_temp_serialized.count, &gt_temp)

        guard let hash = crypto_hash_sha256(input: gt_temp_serialized) else {
            return nil
        }

        let x_p = xor(a: encryptedData.c2.bytes, b: hash)

        guard let x_p_hash = crypto_hash_sha256(input: x_p) else {
            return nil
        }

        guard let msg_p = crypto_secretbox_open_easy(key: x_p_hash, cipherText: encryptedData.c3.bytes, nonce: encryptedData.nonce.bytes) else {
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
        if isEqual != 1 {
            print("mclBnG2_isEqual failed: \(isEqual)")
            return nil
        }

        let isValidOrder = mclBnG1_isValidOrder(&secretKeyForIdentity_)
        let isZero = mclBnG1_isZero(&secretKeyForIdentity_)
        if isValidOrder != 1 || isZero != 0 {
            print("mclBnG1_isValidOrder: \(isValidOrder), mclBnG1_isZero: \(isZero)")
            return nil
        }

        return msg_p
    }

    public static func generateIdentityV3(startOfInterval: Int, qrCodePayload: Bytes) -> Bytes? {
        guard let (nonce1, nonce2, _) = CryptoUtilsBase.getNoncesAndNotificationKey(qrCodePayload: qrCodePayload) else {
            return nil
        }

        guard let preid = crypto_hash_sha256(input: DomainKeys.preid.bytes + qrCodePayload + nonce1) else {
            return nil
        }

        let duration = Int32(bigEndian: 3600) // at the moment, hour buckets are used
        let intervalStart = Int64(bigEndian: Int64(startOfInterval))

        return crypto_hash_sha256(input: DomainKeys.id.bytes + preid + duration.bytes + intervalStart.bytes + nonce2)
    }

    private static func crypto_secretbox_easy(secretKey: Bytes, message: Bytes, nonce: Bytes) -> Bytes? {
        var encryptedMessage = Bytes(count: message.count + crypto_box_macbytes())
        let result = Clibsodium.crypto_secretbox_easy(&encryptedMessage, message, UInt64(message.count), nonce, secretKey)

        if result != 0 {
            print("crypto_secretbox_easy failed: \(result)")
            return nil
        }

        return encryptedMessage
    }

    private static func crypto_secretbox_open_easy(key: Bytes, cipherText: Bytes, nonce: Bytes) -> Bytes? {
        var decryptedMessage = Bytes(count: cipherText.count - crypto_box_macbytes())
        let result = Clibsodium.crypto_secretbox_open_easy(&decryptedMessage, cipherText, UInt64(cipherText.count), nonce, key)

        if result != 0 {
            print("crypto_secretbox_open_easy failed: \(result)")
            return nil
        }

        return decryptedMessage
    }

    private static func crypto_hash_sha256(input: Bytes) -> Bytes? {
        var hash = Bytes(count: crypto_hash_sha256_bytes())
        let result = Clibsodium.crypto_hash_sha256(&hash, input, UInt64(input.count))

        if result != 0 {
            print("crypto_hash_sha256 failed")
            return nil
        }

        return hash
    }

    private static func randombytes_buf() -> Bytes {
        var nonce = Bytes(count: NONCE_LENGTH)
        randombytes(&nonce, UInt64(nonce.count))
        return nonce
    }

    private static func xor(a: Bytes, b: Bytes) -> Bytes {
        assert(a.count == b.count, "a and b must have equal length")

        var c = Bytes(count: a.count)
        for i in 0 ..< a.count {
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

    private static func binToBase64(bytes: Bytes) -> String? {
        let b64BytesLength = sodium_base64_encoded_len(bytes.count, sodium_base64_VARIANT_URLSAFE_NO_PADDING)
        var b64Bytes = Bytes(count: b64BytesLength).map(Int8.init)

        guard sodium_bin2base64(&b64Bytes, b64BytesLength, bytes, bytes.count, sodium_base64_VARIANT_URLSAFE_NO_PADDING) != nil else {
            return nil
        }

        return String(validatingUTF8: b64Bytes)
    }
}
