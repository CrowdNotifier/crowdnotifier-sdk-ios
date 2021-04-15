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

public typealias Bytes = [UInt8]

public extension Bytes {
    init(count: Int) {
        self.init(repeating: 0, count: count)
    }
}

public extension Data {
    var bytes: Bytes { return Bytes(self) }
}

public extension Array where Element == UInt8 {
    var data: Data { return Data(self) }
}

public extension ArraySlice where Element == UInt8 {
    var bytes: Bytes { return Bytes(self) }
}

public extension String {
    var bytes: Bytes { return Bytes(utf8) }
}

public extension Int32 {
    var bytes: Bytes { return withUnsafeBytes(of: self, { Data($0) }).bytes }
}

public extension Int64 {
    var bytes: Bytes { return withUnsafeBytes(of: self, { Data($0) }).bytes }
}
