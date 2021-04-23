# CrowdNotifierSDK for iOS

[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-%E2%9C%93-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://github.com/CrowdNotifier/crowdnotifier-sdk-ios/blob/develop/LICENSE)

This repository contains a work-in-progress SDK for presence tracing based on the [CrowdNotifier protocol](https://github.com/CrowdNotifier/documents). The API and the underlying protocols are subject to change.

CrowdNotifier proposes a protocol for building secure, decentralized, privacy-preserving presence tracing systems. It simplifies and accelerates the process of notifying individuals that shared a semi-public location with a SARS-CoV-2-positive person for a prolonged time without introducing new risks for users and locations. Existing proximity tracing systems (apps for contact tracing such as SwissCovid, Corona Warn App, and Immuni) notify only a subset of these people: those that were close enough for long enough. Current events have shown the need to notify all people that shared a space with a SARS-CoV-2-positive person. The proposed system provides an alternative to other presence-tracing systems that are based on invasive collection or that are prone to abuse by authorities.

The CrowdNotifier design aims to minimize privacy and security risks for individuals and communities, while guaranteeing the highest level of data protection and good usability and deployability. For further details on the design, see the [CrowdNotifier White Paper](https://github.com/CrowdNotifier/documents).

### Work in Progress

The CrowdNotifier protocol is undergoing changes to improve its security and privacy properties. See [CrowdNotifier](https://github.com/CrowdNotifier/documents) for updates on the design. This SDK will be updated to reflect these changes.

The CrowdNotifierSDK for iOS contains alpha-quality code only and is not yet complete. We are continuing the development of this library, and the API is likely to change. The library has not yet been reviewed or audited for security and compatibility.


## Repositories

* Android SDK: [crowdnotifier-sdk-android](https://github.com/CrowdNotifier/crowdnotifier-sdk-android)
* iOS SDK: [crowdnotifier-sdk-ios](https://github.com/CrowdNotifier/crowdnotifier-sdk-ios)
* TypeScript Reference Implementation: [crowdnotifier-ts](https://github.com/CrowdNotifier/crowdnotifier-ts)
* Android Demo App: [notifyme-app-android](https://github.com/notifyme-app/notifyme-app-android)
* iOS Demo App: [notifyme-app-ios](https://github.com/notifyme-app/notifyme-app-ios)
* Backend SDK: [notifyme-sdk-backend](https://github.com/notifyme-app/notifyme-sdk-backend)
* Web Apps: [notifyme-webpages](https://github.com/notifyme-app/notifyme-webpages)

You can find further information on the CrowdNotifier protocol in the [CrowdNotifier white paper](https://github.com/CrowdNotifier/documents).


## Installation

### Swift Package Manager

CrowdNotifierSDK is available through [Swift Package Manager](https://swift.org/package-manager)

1. Add the following to your `Package.swift` file:

  ```swift

  dependencies: [
      .package(url: "https://github.com/CrowdNotifier/crowdnotifier-sdk-ios.git", .branch("develop"))
  ]

  ```

This version points to the HEAD of the `develop` branch and will always fetch the latest development status. Future releases will be made available using semantic versioning to ensure stability for depending projects.


## Using the SDK

### Initialization

In your AppDelegate in the `didFinishLaunchingWithOptions` function you have to initialize the SDK, before you can use any of the other methods:

```swift
CrowdNotifier.initialize()
```

### Usage

```swift
// Get VenueInfo
switch CrowdNotifier.getVenueInfo(qrCode, baseUrl) {
case .success(let venueInfo):
    // venueInfo contains all information contained in the QR code
case .failure(let error):
    // Check why getting venue failed
}

// Store a check-in
switch CrowdNotifier.addCheckin(venueInfo: venueInfo, arrivalTime: arrivalDate, departureTime: departureDate) {
 case .success(let id):
    // Store id to keep reference of check-in together with public key & notification key, e.g. to update arrival/departure times later
case .failure(let error):
    // Check why adding check-in failed
 }

// Update a check-in
switch CrowdNotifier.updateCheckin(checkinId: id, venueInfo: venueInfo, arrivalTime: arrivalDate, departureTime: departureDate) {
 case .success(let id):
    // Store id to keep reference of check-in together with public key & notification key, e.g. to update arrival/departure times later
case .failure(let error):
    // Check why updating check-in failed
 }

// Match published SKs against stored encrypted venue visits
let newExposures = CrowdNotifier.checkForMatches(publishedSKs: publishedSKs)

// Get all exposure events
let allExposures = CrowdNotifier.getExposureEvents()

// Clean up old entries
CrowdNotifier.cleanUpOldData(maxDaysToKeep: 10)
```
### Build and Distribute

You need to modify the Xcode build settings to build the application using CrowdNotfier:

- Set `ENABLE_BITCODE` to: `NO`

There is a known bug in the current Xcode SPM integration with static `binaryTargets`. Xcode copies the .a files into the resulting product in the `/Frameworks` folder (in addition to linking them to the binary). So if you are using SPM, it will be necessary to remove .a-Files from the package before it is distributed. It can be done by adding a post action to the scheme with the following commands:
```
rm -rf "${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app/Frameworks/*.a"
```

## Static methods of CrowdNotifier

The `CrowdNotifier` enum implements the following static methods that can be used to interact with the system. The SDK only stores encrypted entries of check-ins as well as exposure matches. Any additional storage of data needs to
be handled by the app itself.

Name | Description | Function Name
---- | ----------- | -------------
init | Initializes the SDK and configures it | `func initialize()`
getVenueInfo | Returns information about the data contained in a QR code, or an error if the QR code does not have a valid format or does not match the expected base URL | `getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError>`
addCheckin | Stores a check-in given arrival time, departure time and the venue information. Returns the id of the stored entry. | `addCheckin(venueInfo: VenueInfo, arrivalTime: Date, departureTime: Date) -> Result<String, CrowdNotifierError>`
updateCheckin | Updates a checkin that has previously been stored | `updateCheckin(checkinId: String, venueInfo: VenueInfo, newArrivalTime: Date, newDepartureTime: Date) -> Result<String, CrowdNotifierError>`
checkForMatches | Given a set of published events with a known infected visitor, stores and returns those locally stored check-ins that overlap with one of the problematic events | `func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent]`
getExposureEvents | Returns all currently stored check-ins that have previously matched a problematic event | `getExposureEvents() -> [ExposureEvent]`
removeExposure | Remove a exposure from the exposure storage | `removeExposure(exposure: ExposureEvent)`
cleanUpOldData | Removes all check-ins that are older than the specified number of days | `func cleanUpOldData(maxDaysToKeep: Int)`


## Contributing

This project is truly open-source and we welcome any feedback on the code regarding both the implementation and security aspects. This repository contains the iOS prototype SDK, so please focus your feedback for this repository on implementation issues.

Before proceeding, please read the [Code of Conduct](CODE_OF_CONDUCT.txt) to ensure positive and constructive interactions with the community.


## License

This project is licensed under the terms of the MPL 2 license. See the [LICENSE](LICENSE) file.
