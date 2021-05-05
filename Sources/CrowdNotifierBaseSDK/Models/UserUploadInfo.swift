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

public struct UserUploadInfo: Codable, Equatable {
    public let preId: Bytes
    public let timeKey: Bytes
    public let notificationKey: Bytes
    public let intervalStartMs: Int // milliseconds since 1970
    public let intervalEndMs: Int // milliseconds since 1970

    public init(preId: Bytes,
                timeKey: Bytes,
                notificationKey: Bytes,
                intervalStartMs: Int,
                intervalEndMs: Int) {
        self.preId = preId
        self.timeKey = timeKey
        self.notificationKey = notificationKey
        self.intervalStartMs = intervalStartMs
        self.intervalEndMs = intervalEndMs
    }
}
