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

    public static func getVenueInfo(qrCodeData: QRCodeData) -> VenueInfo? {
        instancePrecondition()
        return instance.getVenueInfo(qrCodeData: qrCodeData)
    }

    public static func checkin(qrCodeData: QRCodeData, arrivalTime: Date) -> (VenueInfo, Int)? {
        instancePrecondition()
        return instance.checkin(qrCodeData: qrCodeData, arrivalTime: arrivalTime)
    }

    public static func changeDuration(checkinId: Int, newDuration: TimeInterval) {
        instancePrecondition()
        instance.changeDuration(checkinId: checkinId, newDuration: newDuration)
    }

    public static func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent] {
        instancePrecondition()
        return instance.checkForMatches(publishedSKs: publishedSKs)
    }

    public static func cleanUpOldData(maxDaysToKeep: Int) {
        instancePrecondition()
        instance.cleanUpOldData(maxDaysToKeep: maxDaysToKeep)
    }

    private static func instancePrecondition() {
        precondition(instance != nil, "N2StepSDK not initialized, call `initialize()`")
    }
    
}
