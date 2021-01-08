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
    private static let currentVersion = 2
    private static let minimumVersion = 2
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

        guard let entry = try? QRCodeEntry(serializedData: decoded.data) else {
            print("Could not create code from data")
            return .failure(.invalidQRCode)
        }

        // check version
        if isInvalidVersion(Int(entry.version)) {
            return .failure(.invalidQRCodeVersion)
        }

        let content = entry.data

        let info = VenueInfo(masterPublicKey: entry.masterPublicKey,
                             nonce1: entry.entryProof.nonce1,
                             nonce2: entry.entryProof.nonce2,
                             name: content.name,
                             location: content.location,
                             room: content.room,
                             venueType: .fromVenueType(content.venueType),
                             notificationKey: content.notificationKey)

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
