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

public struct ProblematicEventInfo {
    public let privateKey: Bytes
    public let entry: Date
    public let exit: Date
    public let message: Bytes

    public init(privateKey: Bytes, entry: Date, exit: Date, message: Bytes) {
        self.privateKey = privateKey
        self.entry = entry
        self.exit = exit
        self.message = message
    }
}
