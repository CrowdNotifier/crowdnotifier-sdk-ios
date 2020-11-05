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

class QRCodeParser {

    private let sodium = Sodium()

    func extractVenueInformation(from qrCode: String) -> Result<VenueInfo, N2StepError> {
        guard let url = URL(string: qrCode) else {
            print("Could not create url from string: \(qrCode)")
            return .failure(.invalidQRCode)
        }

        guard let fragment = url.fragment, let decoded = sodium.utils.base642bin(fragment, variant: .URLSAFE_NO_PADDING) else {
            print("Could not create data from fragment of url: \(url.absoluteString)")
            return .failure(.invalidQRCode)
        }

        guard let wrapper = try? QRCodeWrapper(serializedData: Data(decoded)) else {
            print("Could not create code from data")
            return .failure(.invalidQRCode)
        }

        // Verify signature
        let signature = wrapper.signature.bytes
        let pk = wrapper.content.publicKey.bytes
        var message = (try? wrapper.content.serializedData())?.bytes ?? []

        let result = Clibsodium.crypto_sign_ed25519_verify_detached(signature, &message, UInt64(message.count), pk)

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
