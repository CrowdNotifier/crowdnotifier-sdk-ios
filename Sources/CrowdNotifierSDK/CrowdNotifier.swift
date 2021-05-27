/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

@_exported import CrowdNotifierBaseSDK
import Foundation

private var instance: CrowdNotifierMain!

// MARK: - API

public enum CrowdNotifier {
    /// The current version of the SDK
    public static let frameworkVersion: String = "3.0"

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

    public static func removeCheckin(with checkinId: String) {
        instancePrecondition()
        instance.removeCheckin(with: checkinId)
    }

    public static func hasCheckins() -> Bool {
        instancePrecondition()
        return instance.hasCheckins()
    }

    public static func checkForMatches(problematicEventInfos: [ProblematicEventInfo]) -> [ExposureEvent] {
        instancePrecondition()
        return instance.checkForMatches(problematicEventInfos: problematicEventInfos)
    }

    public static func generateQRCodeString(baseUrl: String, masterPublicKey: Bytes, description: String, address: String, startTimestamp: Date, endTimestamp: Date, countryData: Data?) -> Result<(VenueInfo, String), CrowdNotifierError> {
        instancePrecondition()
        return instance.generateQRCodeString(baseUrl: baseUrl, masterPublicKey: masterPublicKey, description: description, address: address, startTimestamp: startTimestamp, endTimestamp: endTimestamp, countryData: countryData)
    }

    public static func generateUserUploadInfo(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> [UserUploadInfo] {
        instancePrecondition()
        return instance.generateUserUploadInfo(venueInfo: venueInfo, arrivalTime: arrivalTime, departureTime: departureTime)
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
