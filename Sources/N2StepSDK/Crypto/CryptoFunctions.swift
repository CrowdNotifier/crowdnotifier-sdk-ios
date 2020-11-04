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
import Sodium

class CryptoFunctions {

    static func createKeyPair() -> (sk: String, pk: String) {
        return (String.random(length: 15), String.random(length: 15))
    }

    static func createSharedKey(key1: String, key2: String) -> String {
        return key1 + key2
    }

    static func encrypt(text: String, withKey key: String) -> String {
        return text
    }

    static func decrypt(ciphertext: String, withKey key: String) -> String {
        return ciphertext
    }

}

extension String {
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
