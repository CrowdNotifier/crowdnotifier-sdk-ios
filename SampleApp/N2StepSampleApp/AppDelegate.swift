/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import N2StepSDK
import UIKit

func initializeSDK() {
    N2Step.initialize()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initializeSDK()

        if application.applicationState != .background {
            initWindow()
        }

        return true
    }

    func initWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKey()
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()
    }

    func applicationWillEnterForeground(_: UIApplication) {
        if window == nil {
            initWindow()
        }
    }
}
