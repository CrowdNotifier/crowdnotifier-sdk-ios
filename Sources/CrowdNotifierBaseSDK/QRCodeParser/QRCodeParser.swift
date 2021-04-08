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

class QRCodeParser {
    private static let currentVersion = 3
    private static let minimumVersion = 2
    private static let lastLegacyVersion = 2
    private static let urlVersionKey = "v"

    func extractVenueInformation(from qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        guard let url = URL(string: qrCode) else {
            print("Could not create url from string: \(qrCode)")
            return .failure(.invalidQRCode)
        }

        guard url.absoluteString.starts(with: baseUrl) else {
            print("Base URL does not match \(baseUrl)")
            return .failure(.invalidQRCode)
        }

        guard let version = getVersion(from: url) else {
            return .failure(.invalidQRCode)
        }

        if isInvalidVersion(version) {
            return .failure(.invalidQRCodeVersion)
        }

        guard let fragment = url.fragment, let decoded = base642bin(fragment) else {
            print("Could not create data from fragment of url: \(url.absoluteString)")
            return .failure(.invalidQRCode)
        }

        if version > QRCodeParser.lastLegacyVersion {
            return extractVenueInfo(data: decoded.data)
        } else {
            return legacyExtractVenueInfo(data: decoded.data)
        }
    }

    private func extractVenueInfo(data: Data) -> Result<VenueInfo, CrowdNotifierError> {
        guard let payload = try? QRCodePayload(serializedData: data), let countryData = try? NMLocationData(serializedData: payload.countryData) else {
            print("Could not create code from data")
            return .failure(.invalidQRCode)
        }

        // Length: 32 bytes for nonce1 and nonce2, 16 bytes for notification_key
        let length = 32 + 32 + 16
        let hkdfKey = CryptoUtils.createHKDFKey(length: length, inputKey: data.bytes, salt: [], info: Bytes("NotifyMe_v2.2".utf8))

        guard hkdfKey.count == length else {
            return .failure(.invalidQRCode)
        }

        let nonce1 = Bytes(hkdfKey[0..<32])
        let nonce2 = Bytes(hkdfKey[32..<64])
        let notificationKey = Bytes(hkdfKey[64..<80])

        // check version
        if isInvalidVersion(Int(payload.version)) {
            return .failure(.invalidQRCodeVersion)
        }

        // check date validity
        let now = Date()

        if Date(millisecondsSince1970: Int(payload.locationData.startTimestamp)) > now {
            return .failure(.validFromError)
        }

        if Date(millisecondsSince1970: Int(payload.locationData.endTimestamp)) < now {
            return .failure(.validToError)
        }

        let info = VenueInfo(name: payload.locationData.description_p,
                             location: payload.locationData.address,
                             room: countryData.room,
                             venueType: .fromVenueType(countryData.type),
                             masterPublicKey: payload.crowdNotifierData.publicKey,
                             nonce1: nonce1.data,
                             nonce2: nonce2.data,
                             notificationKey: notificationKey.data,
                             validFrom: Int(payload.locationData.startTimestamp),
                             validTo: Int(payload.locationData.endTimestamp))

        return .success(info)
    }

    private func legacyExtractVenueInfo(data: Data) -> Result<VenueInfo, CrowdNotifierError> {
        guard let entry = try? QRCodeEntry(serializedData: data) else {
            print("Could not create code from data")
            return .failure(.invalidQRCode)
        }

        // check version
        if isInvalidVersion(Int(entry.version)) {
            return .failure(.invalidQRCodeVersion)
        }

        // check date validity
        let now = Date()

        if Date(millisecondsSince1970: Int(entry.data.validFrom)) > now {
            return .failure(.validFromError)
        }

        if Date(millisecondsSince1970: Int(entry.data.validTo)) < now {
            return .failure(.validToError)
        }

        let content = entry.data

        let info = VenueInfo(name: content.name,
                             location: content.location,
                             room: content.room,
                             venueType: .fromVenueType(content.venueType),
                             masterPublicKey: entry.masterPublicKey,
                             nonce1: entry.entryProof.nonce1,
                             nonce2: entry.entryProof.nonce2,
                             notificationKey: content.notificationKey,
                             validFrom: Int(content.validFrom),
                             validTo: Int(content.validTo))

        return .success(info)
    }

    private func isInvalidVersion(_ version: Int) -> Bool {
        return version > QRCodeParser.currentVersion || version < QRCodeParser.minimumVersion
    }

    private func getVersion(from url: URL) -> Int? {
        return Int(getQueryStringParameter(url: url, param: QRCodeParser.urlVersionKey) ?? "")
    }
}

private func base642bin(_ b64: String, ignore: String? = nil) -> Bytes? {
    let b64Bytes = Bytes(b64.utf8).map(Int8.init)
    let b64BytesLen = b64Bytes.count
    let binBytesCapacity = b64BytesLen * 3 / 4 + 1
    var binBytes = Bytes(count: binBytesCapacity)
    var binBytesLen: size_t = 0
    let ignore_nsstr = ignore.flatMap { NSString(string: $0) }
    let ignore_cstr = ignore_nsstr?.cString(using: String.Encoding.isoLatin1.rawValue)

    let result = sodium_base642bin(&binBytes, binBytesCapacity, b64Bytes, b64BytesLen, ignore_cstr, &binBytesLen, nil, sodium_base64_VARIANT_URLSAFE_NO_PADDING)

    guard result == 0 else {
        return nil
    }

    binBytes = binBytes[..<binBytesLen].bytes

    return binBytes
}

private func getQueryStringParameter(url: URL, param: String) -> String? {
  guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
  return url.queryItems?.first(where: { $0.name == param })?.value
}
