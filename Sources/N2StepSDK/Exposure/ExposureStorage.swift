//
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

class ExposureStorage {
    static let shared = ExposureStorage()

    private init() {}

    @KeychainPersisted(key: "ch.n2step.exposure.events.key", defaultValue: [])
    private(set) var exposureEvents: [ExposureEvent]

    func setExposureEvents(_ events: [ExposureEvent]) {
        exposureEvents = events
    }
}
