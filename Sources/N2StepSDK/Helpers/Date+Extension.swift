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

extension Date {
    var millisecondsSince1970: Int {
        return Int(timeIntervalSince1970 * 1000.0)
    }

    init(millisecondsSince1970: Int) {
        self.init(timeIntervalSince1970: TimeInterval(Double(millisecondsSince1970) / 1000.0))
    }

    var daysSince1970: Int {
        return Int(timeIntervalSince1970 / .day)
    }
}
