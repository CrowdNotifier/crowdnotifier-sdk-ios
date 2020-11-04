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

public struct ExposureEvent {
    public let checkinId: Int
    public let start: Date
    public let duration: TimeInterval
    public let message: String
}

extension ExposureEvent: Equatable {
    public static func == (lhs: ExposureEvent, rhs: ExposureEvent) -> Bool {
        return lhs.checkinId == rhs.checkinId
    }
}