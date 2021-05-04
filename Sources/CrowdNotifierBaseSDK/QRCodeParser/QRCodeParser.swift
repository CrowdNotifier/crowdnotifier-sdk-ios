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
    private static let minimumVersion = 3
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

        return extractVenueInfoV3(data: decoded.data)
    }

    private func extractVenueInfoV3(data: Data) -> Result<VenueInfo, CrowdNotifierError> {
        guard let payload = try? QRCodePayload(serializedData: data) else {
            print("Could not create code from data")
            return .failure(.invalidQRCode)
        }

        guard let (noncePreId, nonceTimekey, notificationKey) = CryptoUtilsBase.getNoncesAndNotificationKey(qrCodePayload: data.bytes) else {
            return .failure(.invalidQRCode)
        }

        // check version
        if isInvalidVersion(Int(payload.version)) {
            return .failure(.invalidQRCodeVersion)
        }

        // check date validity
        let now = Date()

        if Date(timeIntervalSince1970: TimeInterval(payload.locationData.startTimestamp)) > now {
            return .failure(.validFromError)
        }

        if Date(timeIntervalSince1970: TimeInterval(payload.locationData.endTimestamp)) < now {
            return .failure(.validToError)
        }

        guard let qrCodePayload = try? payload.serializedData() else {
            return .failure(.invalidQRCode)
        }

        let info = VenueInfo(description: payload.locationData.description_p,
                             address: payload.locationData.address,
                             notificationKey: notificationKey.data,
                             publicKey: payload.crowdNotifierData.publicKey,
                             noncePreId: noncePreId.data,
                             nonceTimekey: nonceTimekey.data,
                             validFrom: Int(payload.locationData.startTimestamp) * 1000,
                             validTo: Int(payload.locationData.endTimestamp) * 1000,
                             qrCodePayload: qrCodePayload,
                             countryData: payload.countryData)

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
    let b64Bytes = b64.bytes.map(Int8.init)
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
