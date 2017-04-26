# Friendly Pix Web

Friendly Pix Web is a sample app demonstrating how to build a JavaScript/Web app with the Firebase Platform.

Friendly Pix is a place where you can share photos, follow friends, comment on photos...


## Initial setup, build tools and dependencies

Friendly Pix is built using Javascript, [Firebase](https://firebase.google.com/docs/web/setup) and jQuery. The Auth flow is built using [Firebase-UI](https://github.com/firebase/firebaseui-web). Javascript dependencies are managed using [bower](http://bower.io/) and Build/Deploy tools dependencies are managed using [npm](https://www.npmjs.com/). Also Friendly Pix is written in ES2015 so for wide browser support we'll transpile the code to ES5 using [BabelJs](http://babeljs.io). Additionally server-side micro-services are built on [Cloud Functions for Firebase](https://firebase.google.com/docs/functions).

Install all Build/Deploy tools dependencies by running:

```bash
$ npm install
```


## Create and configure your Firebase Project

1. Create a Firebase project using the [Firebase Console](https://firebase.google.com/console).
2. Enable **Google** as a Sign in provider in **Firebase Console > Authentication > Sign in Method** tab.
3. Enable **Facebook** as a Sign in provider in **Firebase Console > Authentication > Sign in Method** tab. You'll need to provide your Facebook app's credentials. If you haven't yet you'll need to have created a Facebook app on [Facebook for Developers](https://developers.facebook.com)
4. At the root of the site run `firebase use --add`. When prompted select the Firebase Project you have just created. This will make sure the Firebase CLI is configured to use your particular project.


## Start a local development server

You can start a local development server by running:

```bash
npm run serve
```

This will start `firebase serve` and make sure your Javascript files are transpiled automatically to ES5.

> This is currently broken on Windows. On Windows please run the following commands separately instead: `bower install`, `babel -w scripts -s --retain-lines -d lib` and `firebase serve`.

Then open [http://localhost:5000](http://localhost:5000)

> Note: Cloud Functions cannot yet be ran locally. Deploy the app to deploy and enable the Cloud Functions.


## Deploy the app

Before deploying your code you need to build it for production. Run:

```bash
npm run build
```

This will install all runtime dependencies and transpile the Javascript code to ES5 and install Cloud Functions dependencies.
Then run:

```bash
firebase deploy
```

Then this deploys a new version of your code that will be served from `https://<PROJECT_ID>.firebaseapp.com`


## Contributing

We'd love that you contribute to the project. Before doing so please read our [Contributor guide](../CONTRIBUTING.md).


## License

© Google, 2011. Licensed under an [Apache-2](../LICENSE) license.
