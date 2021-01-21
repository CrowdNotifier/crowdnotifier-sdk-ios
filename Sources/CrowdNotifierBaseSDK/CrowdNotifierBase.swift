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

private var instance: CrowdNotifierBaseMain!

public enum CrowdNotifierBase {
    /// The current version of the SDK
    public static let frameworkVersion: String = "1.0"

    public static func initialize() {
        precondition(instance == nil, "CrowdNotifierSDK already initialized")
        instance = CrowdNotifierBaseMain()
    }

    public static func getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        instancePrecondition()
        return instance.getVenueInfo(qrCode: qrCode, baseUrl: baseUrl)
    }

    private static func instancePrecondition() {
        precondition(instance != nil, "CrowdNotifierSDK not initialized, call `initialize()`")
    }
}
