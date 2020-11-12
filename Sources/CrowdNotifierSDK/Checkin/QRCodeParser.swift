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
    func extractVenueInformation(from qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        guard let url = URL(string: qrCode) else {
            print("Could not create url from string: \(qrCode)")
            return .failure(.invalidQRCode)
        }

        guard url.absoluteString.starts(with: baseUrl) else {
            print("Base URL does not match \(baseUrl)")
            return .failure(.invalidQRCode)
        }

        guard let fragment = url.fragment, let decoded = base642bin(fragment) else {
            print("Could not create data from fragment of url: \(url.absoluteString)")
            return .failure(.invalidQRCode)
        }

        guard let wrapper = try? QRCodeWrapper(serializedData: decoded.data) else {
            print("Could not create code from data")
            return .failure(.invalidQRCode)
        }

        // Verify signature
        let signature = wrapper.signature.bytes
        let pk = wrapper.content.publicKey.bytes
        var message = (try? wrapper.content.serializedData())?.bytes ?? []

        let result = crypto_sign_ed25519_verify_detached(signature, &message, UInt64(message.count), pk)

        guard result == 0 else {
            return .failure(.invalidSignature)
        }

        let code = wrapper.content

        let info = VenueInfo(publicKey: code.publicKey,
                             notificationKey: code.notificationKey,
                             name: code.name,
                             location: code.location,
                             room: code.hasRoom ? code.room : nil,
                             venueType: .fromVenueType(code.venueType))

        return .success(info)
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

extension ArraySlice where Element == UInt8 {
    var bytes: Bytes { return Bytes(self) }
}

extension String {
    var bytes: Bytes { return Bytes(utf8) }
}
