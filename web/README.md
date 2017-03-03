# Friendly Pix Web

Friendly Pix Web is a sample app demonstrating how to build a JavaScript/Web app with the Firebase Platform.

Friendly Pix is a place where you can share photos, follow friends, comment on photos...


## Initial setup, build tools and dependencies

Friendly Pix is built using Javascript, [Firebase](https://firebase.google.com/docs/web/setup) and jQuery. The Auth flow is built using [Firebase-UI](https://github.com/firebase/firebaseui-web). Javascript dependencies are managed using [bower](http://bower.io/) and Build/Deploy tools dependencies are managed using [npm](https://www.npmjs.com/). Also Friendly Pix is written in ES2015 so for wide browser support we'll transpile the code to ES5 using [BabelJs](http://babeljs.io).

Install all Build/Deploy tools dependencies by running:

```bash
$> npm install
```


## Create Firebase Project

1. Create a Firebase project using the [Firebase Console](https://firebase.google.com/console).
2. Enable **Google** as a Sign in provider in **Firebase Console > Authentication > Sign in Method** tab.
3. Enable **Facebook** as a Sign in provider in **Firebase Console > Authentication > Sign in Method** tab. You'll need to provide your Facebook app's credentials. If you haven't yet you'll need to have created a Facebook app on [Facebook for Developers](https://developers.facebook.com)
4. Now navigate to the **Overview** on the top left and click **Add Firebase to your web app** to get the initialization snippet to copy. The snippet will look like this:

  ```html
  <script src="https://www.gstatic.com/firebasejs/<VERSION>/firebase.js"></script>
  <script>
    // Initialize Firebase
    var config = {
      apiKey: "<YOUR_API_KEY>",
      authDomain: "<YOUR_PROJECT_ID>.firebaseapp.com",
      databaseURL: "https://<YOUR_PROJECT_ID>.firebaseapp.com",
      storageBucket: "<YOUR_PROJECT_ID>.appspot.com",
      messagingSenderId: "<YOUR_MESSAGING_SENDER_ID>"
    };
    firebase.initializeApp(config);
  </script>
  ```

> If the `storageBucket` value is empty you've hit a bug. Just close the window and click the  **WEB SETUP** button again and you should get it.


## Update the app with your firebase project

1. In root of the site, locate the **index.html** file and replace the text below with the snippet you copied above:

  ```html
  <!-- TODO(DEVELOPER): Paste the initialization snippet from: Firebase Console > Add Firebase to your web app. -->
  ```

2. In the web directory, locate the **storage.rules** file and replace the storage bucket location with the one from firebase project. The location is the storageBucket parameter in the initialization snippet:

  ```javascript
  // TODO: Change the <STORAGE_BUCKET> placeholder below
  match /b/<STORAGE_BUCKET>/o {
  ```

## Start a local development server

You need to have installed the Firebase CLI by running `npm install`.

You can start a local development server by running:

```bash
$> npm run serve
```

This will start `firebase serve` and make sure your Javascript files are transpiled automatically to ES5.

> This is currently broken on Windows. On Windows please run the following commands separately instead: `bower install`, `babel -w scripts -s --retain-lines -d lib` and `firebase serve`.

Then open [http://localhost:5000](http://localhost:5000)


## Deploy the app

Deploy to Firebase using the following command:

```bash
$> npm run build
$> firebase deploy --project <PROJECT_ID>
```

This will install all runtime dependencies and transpile the Javascript code to ES5.
Then this deploys a new version of your code that will be served from `https://<PROJECT_ID>.firebaseapp.com`


## Contributing

We'd love that you contribute to the project. Before doing so please read our [Contributor guide](../CONTRIBUTING.md).


## License

© Google, 2011. Licensed under an [Apache-2](../LICENSE) license.
