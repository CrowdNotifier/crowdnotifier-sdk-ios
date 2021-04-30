/*
 * Copyright (c) 2021 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation

struct TestVector: Decodable {
    let identityTestVector: [IdentityTestVector]
    let hkdfTestVector: [HkdfTestVector]

    struct IdentityTestVector: Decodable {
        let startOfInterval: Int
        let qrCodePayload: [Int8]
        let identity: [Int8]
    }

    struct HkdfTestVector: Decodable {
        let qrCodePayload: [Int8]
        let noncePreId: [Int8]
        let nonceTimekey: [Int8]
        let notificationKey: [Int8]
    }
}
