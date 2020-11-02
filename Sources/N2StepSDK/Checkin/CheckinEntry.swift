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

struct CheckinEntry: Codable {
    let id: Int
    let daydate: String
    let pk: String
    let sharedKey: String
    let encryptedArrivalTimeAndNotificationKey: String
    var encryptedCheckoutTime: String
}

extension CheckinEntry {

    mutating func updateCheckoutTime(_ newCheckoutTime: String) {
        encryptedCheckoutTime = newCheckoutTime
    }

}
