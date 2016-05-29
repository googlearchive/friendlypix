# Friendly Pix Web

Friendly Pix Web is a sample app demonstrating how to build a JavaScript/Web app with the Firebase Platform.

Friendly Pix is a place where you can share photos, follow friends, comment on photos...


## Initial setup, build tools and dependencies

Friendly Pix is built using Javascript and Firebase. Javascript dependencies are managed using [bower](http://bower.io/) and Build/Deploy tools dependencies are managed using [npm](https://www.npmjs.com/). Also Friendly Pix is written in ES2015 so for wide browser support we'll transpile the code to ES5 using [BabelJs](http://babeljs.io).


Install all Build/Deploy tools dependencies by running:

```bash
$> npm install
```


## Create Firebase Project
1. Create a Firebase/Google Project. Do this on the [Firebase Console](https://firebase.google.com/console)
2. Add Google as a Sign in provide via the Auth section [Firebase Console Auth Section](https://firebase.google.com/docs/auth/server#use_the_firebase_server_sdk)
3. Now click WEB SETUP button in the top right corner to copy the initialization snippet it will look like this 
```
<script src="https://www.gstatic.com/firebasejs/live/3.0/firebase.js"></script>
<script>
  // Initialize Firebase
  var config = {
    apiKey: "<YOUR API KEY>",
    authDomain: "<YOUR PROJECT>.firebaseapp.com",
    databaseURL: "https://<YOUR PROJECT>.firebaseapp.com",
    storageBucket: "<YOUR PROJECT>.firebaseapp.com",
  };
  firebase.initializeApp(config);
</script>
```
## Update the project with your firebase project
1. In the root of the site locate the __index.html__ in the root of the folder and replace the text below with the snippet you coppied above
```
   <!-- TODO(DEVELOPER): Paste the initialization snippet from: Firebase Console > Add Firebase to your web app. -->
```
2.  In the root of the site locate the file __storage.rules__ and replace the storage bucket location with the one from firebase project

```
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
