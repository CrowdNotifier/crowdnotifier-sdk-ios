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

extension Data {
    var bytes: Bytes {
        return Bytes(self)
    }
}

extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}
