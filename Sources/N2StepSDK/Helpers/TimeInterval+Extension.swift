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

extension TimeInterval {

    /// A time interval of one second.
    public static var second: TimeInterval {
        return 1
    }

    /// A time interval of one minute.
    public static var minute: TimeInterval {
        return 60 * .second
    }

    /// A time interval of one hour.
    public static var hour: TimeInterval {
        return 60 * .minute
    }

    /// A time interval of one day.
    public static var day: TimeInterval {
        return 24 * .hour
    }

}
