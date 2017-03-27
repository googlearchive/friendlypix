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
1. Download the generated `GoogleService-Info.plist` file, and copy it to the root directory of this app.

### Google Sign In Setup
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Google** and turn on the **Enable** switch, then click **Save**.
- In XCode, add a custom URL scheme for your reversed client ID.
  - You can find this in the `GoogleService-Info.plist`
- Run the app on your device or simulator.
    - Select **Sign In** and select Google to begin.

### Facebook Login Setup
- Go to the [Facebook Developers Site](https://developers.facebook.com) and follow all
  instructions to set up a new iOS app. When asked for a bundle ID, use
  `com.google.firebase.quickstart.AuthenticationExample`.
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Facebook** and turn on the **Enable** switch, then click **Save**.
  - Enter your Facebook **App Id** and **App Secret** and click **Save**.
- Open your regular `Info.plist` and replace the value of the `FacebookAppID` with the ID of the
  Facebook app you just created, e.g 124567. Save that file.
- In the *Info* tab of your target settings add a *URL Type* with a *URL Scheme* of 'fb' + the ID
  of your Facebook app, e.g. fb1234567.
- Run the app on your device or simulator.
    - Select **Sign In** and select Facebook to begin.

### Twitter Login Setup
- Go to the [Twitter Developers Site](https://apps.twitter.com/) and follow all
  instructions to set up a new iOS app.
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Twitter** and turn on the **Enable** switch, then click **Save**.
  - Enter your Twitter **API Key** and **App Secret** and click **Save**.
- Open your regular `Info.plist` and replace the value of the `consumerKey` and `consumerSecret` values with the keys from the Twitter app you just created.
- Run the app on your device or simulator.
    - Select **Sign In** and select Twitter to begin.
- Note: you can also integrate with Twitter via Fabric using `[Fabric with:@[ [Twitter class] ]];`


## Contributing

We'd love that you contribute to the project. Before doing so please read our [Contributor guide](../CONTRIBUTING.md).


## License

© Google, 2011. Licensed under an [Apache-2](../LICENSE) license.
