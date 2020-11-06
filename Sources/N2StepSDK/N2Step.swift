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

private var instance: N2StepMain!

public enum N2Step {
    /// The current version of the SDK
    public static let frameworkVersion: String = "1.0"

    public static func initialize() {
        precondition(instance == nil, "N2StepSDK already initialized")
        instance = N2StepMain()
    }

    public static func getVenueInfo(qrCode: String) -> Result<VenueInfo, N2StepError> {
        instancePrecondition()
        return instance.getVenueInfo(qrCode: qrCode)
    }

    public static func addCheckin(qrCode: String, arrivalTime: Date, departureTime: Date) -> Result<(VenueInfo, String), N2StepError> {
        instancePrecondition()
        return instance.addCheckin(qrCode: qrCode, arrivalTime: arrivalTime, departureTime: departureTime)
    }

    public static func updateCheckin(checkinId: String, qrCode: String, newArrivalTime: Date, newDepartureTime: Date) -> Result<(VenueInfo, String), N2StepError> {
        instancePrecondition()
        return instance.updateCheckin(checkinId: checkinId, qrCode: qrCode, newArrivalTime: newArrivalTime, newDepartureTime: newDepartureTime)
    }

    public static func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        instancePrecondition()
        return instance.checkForMatches(publishedSKs: publishedSKs)
    }

    public static func getExposureEvents() -> [ExposureEvent] {
        instancePrecondition()
        return instance.getExposureEvents()
    }

    public static func cleanUpOldData(maxDaysToKeep: Int) {
        instancePrecondition()
        instance.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }

    private static func instancePrecondition() {
        precondition(instance != nil, "N2StepSDK not initialized, call `initialize()`")
    }
}
