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
import CrowdNotifierBaseSDK

private var instance: CrowdNotifierMain!

public enum CrowdNotifier {
    /// The current version of the SDK
    public static let frameworkVersion: String = "1.0"

    public static func initialize() {
        precondition(instance == nil, "CrowdNotifierSDK already initialized")
        instance = CrowdNotifierMain()
        CrowdNotifierBase.initialize()
    }

    public static func getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError> {
        instancePrecondition()
        return instance.getVenueInfo(qrCode: qrCode, baseUrl: baseUrl)
    }

    public static func addCheckin(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError> {
        instancePrecondition()
        return instance.addCheckin(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime)
    }

    public static func updateCheckin(checkinId: String, venueInfo: VenueInfo, newArrivalTime: Date, newDepartureTime: Date) -> Result<String, CrowdNotifierError> {
        instancePrecondition()
        return instance.updateCheckin(checkinId: checkinId, venueInfo: venueInfo, newArrivalTime: newArrivalTime, newDepartureTime: newDepartureTime)
    }

    public static func checkForMatches(problematicEventInfos: [ProblematicEventInfo]) -> [ExposureEvent] {
        instancePrecondition()
        return instance.checkForMatches(problematicEventInfos: problematicEventInfos)
    }

    public static func getExposureEvents() -> [ExposureEvent] {
        instancePrecondition()
        return instance.getExposureEvents()
    }

    public static func removeExposure(exposure: ExposureEvent) {
        instancePrecondition()
        return instance.removeExposure(exposure: exposure)
    }

    public static func cleanUpOldData(maxDaysToKeep: Int) {
        instancePrecondition()
        instance.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }

    private static func instancePrecondition() {
        precondition(instance != nil, "CrowdNotifierSDK not initialized, call `initialize()`")
    }
}
