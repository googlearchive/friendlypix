# Friendly Pix iOS

Friendly Pix iOS is a sample app demonstrating how to build an iOS app with the Firebase Platform.

Friendly Pix is a place where you can share photos, follow friends, comment on photos...


## Initial setup, build tools and dependencies

Friendly Pix iOS is built using Objective-C and [Firebase](https://firebase.google.com/docs/ios/setup). The Auth flow is built using [Firebase-UI](https://github.com/firebase/firebaseui-ios). Dependencies are managed using [CocoaPods](https://cocoapods.org/). Additionally server-side micro-services are built on [Cloud Functions for Firebase](https://firebase.google.com/docs/functions).

Simply install the pods and open the .xcworkspace file to see the project in Xcode.

```
$ pod install
$ open your-project.xcworkspace
```

## Create Firebase Project

1. Create a Firebase project using the [Firebase Console](https://firebase.google.com/console).
1. To add the FriendlyPix app to a Firebase project, use the bundleID `com.google.firebase.friendlypix`.
1. Enable **Google** as a Sign in provider in **Firebase Console > Authentication > Sign in Method** tab.
1. Enable **Facebook** as a Sign in provider in **Firebase Console > Authentication > Sign in Method** tab. You'll need to provide your Facebook app's credentials. If you haven't yet you'll need to have created a Facebook app on [Facebook for Developers](https://developers.facebook.com)
1. Download the generated `GoogleService-Info.plist` file, and copy it to the root
directory of this app.
1. Copy the value of REVERSED_CLIENT_ID from `GoogleService-info.plist` into the `URL scheme` for the app.


## Contributing

We'd love that you contribute to the project. Before doing so please read our [Contributor guide](../CONTRIBUTING.md).


## License

© Google, 2011. Licensed under an [Apache-2](../LICENSE) license.
