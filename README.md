# CrowdNotifierSDK for iOS
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-%E2%9C%93-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://github.com/CrowdNotifier/crowdnotifier-sdk-ios/blob/develop/LICENSE)
![build](https://github.com/CrowdNotifier/crowdnotifier-sdk-ios/workflows/build/badge.svg)

## CrowdNotifier
This repository implements a secure, decentralized, privacy-preserving presence tracing system. The proposal aims to simplify and accelerate the process of notifying individuals that shared a semi-public location with a SARS-CoV-2-positive person for a prolonged time without introducing new risks for users and locations. Existing proximity tracing systems (apps for contact tracing such as SwissCovid, Corona Warn App, and Immuni) notify only a subset of these people: those that were close enough for long enough. Current events have shown the need to notify all people that shared a space with a SARS-CoV-2-positive person. The proposed system aims to provide an alternative to increasing use of apps with similar intentions based on invasive collection or that are prone to abuse by authorities. The preliminary design aims to minimize privacy and security risks for individuals and communities, while guaranteeing the highest level of data protection and good usability and deployability.

The white paper this implementation is based on can be found here: [CrowdNotifier White Paper](https://github.com/CrowdNotifier/documents)

## Repositories
* Android SDK: [crowdnotifier-sdk-android](https://github.com/CrowdNotifier/crowdnotifier-sdk-android)
* iOS SDK: [crowdnotifier-sdk-ios](https://github.com/CrowdNotifier/crowdnotifier-sdk-ios)
* Android Demo App: [notifyme-app-android](https://github.com/notifyme-app/notifyme-app-android)
* iOS Demo App: [notifyme-app-ios](https://github.com/notifyme-app/notifyme-app-ios)
* Backend SDK: [notifyme-sdk-backend](https://github.com/notifyme-app/notifyme-sdk-backend)
* QR Generator Web App: [notifyme-qrgenerator-web](https://github.com/notifyme-app/notifyme-qrgenerator-web)
* QR Landing Page Web App: [notifyme-qrlandingpage-web](https://github.com/notifyme-app/notifyme-qrlandingpage-web)
* QR Trace Upload Web App: [notifyme-upload-web](https://github.com/notifyme-app/notifyme-upload-web)

## Work in Progress
The CrowdNotifierSDK for iOS contains alpha-quality code only and is not yet complete. It has not yet been reviewed or audited for security and compatibility. We are both continuing the development and have started a security review. This project is truly open-source and we welcome any feedback on the code regarding both the implementation and security aspects.
This repository contains the open prototype SDK, so please focus your feedback for this repository on implementation issues.

## Further Documentation
The full set of documents for CrowdNotifier is at https://github.com/CrowdNotifier/documents. Please refer to the technical documents and whitepapers for a description of the implementation.

## Function overview

### Initialization
Name | Description | Function Name
---- | ----------- | -------------
init | Initializes the SDK and configures it | `func initialize()`

### Methods 
Name | Description | Function Name
---- | ----------- | -------------
getVenueInfo | Returns information about the data contained in a QR code, or an error if the QR code does not have a valid format or does not match the expected base URL | `getVenueInfo(qrCode: String, baseUrl: String) -> Result<VenueInfo, CrowdNotifierError>`
addCheckin | Stores a check-in given arrival time, departure time, notification key and the venue's public key. Returns the id of the stored entry. | `addCheckin(arrivalTime: Date, departureTime: Date, notificationKey: Bytes, venuePublicKey: Bytes) -> Result<String, CrowdNotifierError>`
updateCheckin | Updates a checkin that has previously been stored | `updateCheckin(checkinId: String, newArrivalTime: Date, newDepartureTime: Date, notificationKey: Bytes, venuePublicKey: Bytes) -> Result<String, CrowdNotifierError>`
checkForMatches | Given a set of published events with a known infected visitor, stores and returns those locally stored check-ins that overlap with one of the problematic events | `func checkForMatches(publishedSKs: [ProblematicEventInfo]) -> [ExposureEvent]`
getExposureEvents | Returns all currently stored check-ins that have previously matched a problematic event | `getExposureEvents() -> [ExposureEvent]`
cleanUpOldData | Removes all check-ins that are older than the specified number of days | `func cleanUpOldData(maxDaysToKeep: Int)`

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
switch CrowdNotifier.addCheckin(arrivalTime: arrivalDate, departureTime: departureDate, notificationKey: venueInfo.notificationKey, venuePublicKey: venueInfo.publicKey) {
 case .success(let id):
    // Store id to keep reference of check-in together with public key & notification key, e.g. to update arrival/departure times later
case .failure(let error):
    // Check why adding check-in failed
 }

// Update a check-in
switch CrowdNotifier.updateCheckin(checkinId: id, arrivalTime: arrivalDate, departureTime: departureDate, notificationKey: venueInfo.notificationKey, venuePublicKey: venueInfo.publicKey) {
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

## License

This project is licensed under the terms of the MPL 2 license. See the [LICENSE](LICENSE) file.
