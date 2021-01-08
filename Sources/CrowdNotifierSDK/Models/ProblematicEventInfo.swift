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

public struct ProblematicEventInfo {
    public let identity: Bytes
    public let secretKeyForIdentity: Bytes
    public let startTimestamp: Date
    public let endTimestamp: Date
    public let nonce: Bytes
    public let encryptedMessage: Bytes

    public init(identity: Bytes, secretKeyForIdentity: Bytes, startTimestamp: Date, endTimestamp: Date, nonce: Bytes, encryptedMessage: Bytes) {
        self.identity = identity
        self.secretKeyForIdentity = secretKeyForIdentity
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.nonce = nonce
        self.encryptedMessage = encryptedMessage
    }

    public static let sample = ProblematicEventInfo(identity: [-118,-93,-53,-41,-6,-77,-105,-52,111,51,-37,-25,-53,-91,-100,-38,15,-45,82,75,118,28,-47,26,31,-53,-86,66,-95,-125,43,-17].uint8,
                                             secretKeyForIdentity: [49,84,121,28,-5,48,49,-89,-109,89,101,-88,1,37,-3,-23,6,117,-36,-64,108,-102,48,117,37,-119,-23,40,-80,-84,99,-68,36,74,106,-30,20,45,-125,119,-127,65,-68,-73,52,59,109,-125].uint8,
                                             startTimestamp: Date(millisecondsSince1970: 1610101578000).addingTimeInterval(-2 * .hour),
                                             endTimestamp: Date(millisecondsSince1970: 1610101578000).addingTimeInterval(2 * .hour),
                                             nonce: [-85,33,-128,9,66,123,34,-23,70,-56,-72,-12,-102,-122,37,103,9,-105,96,-79,111,39,-14,36].uint8,
                                             encryptedMessage: [-69,-6,-89,-35,49,76,122,-50,40,-128,-98,82,117,68,-34,-21,-90,38,98,61,68,89,28,86,56,-113,74,75,109,-100,22,-5,22].uint8)
}

extension Array where Element == Int8 {
    var uint8: [UInt8] {
        return self.map { UInt8(bitPattern: $0) }
    }
}
