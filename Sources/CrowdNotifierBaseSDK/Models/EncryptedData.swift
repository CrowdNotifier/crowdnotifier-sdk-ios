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

public struct EncryptedData: Codable {
    public init(c1: Data, c2: Data, c3: Data, nonce: Data) {
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.nonce = nonce
    }
    
    public let c1: Data
    public let c2: Data
    public let c3: Data
    public let nonce: Data
}
