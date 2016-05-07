# Friendly Pix Web

Friendly Pix Web is a sample app demonstrating how to build a JavaScript/Web app with the Firebase Platform.

Friendly Pix is a place where you can share photos, follow friends, comment on photos...


## Initial setup, build tools and dependencies

Friendly Pix is built using Javascript and Firebase. Javascript dependencies are managed using [bower](http://bower.io/) and Build/Deploy tools dependencies are managed using [npm](https://www.npmjs.com/). Also Friendly Pix is written in ES2015 so for wide browser support we'll transpile the code to ES5 using [BabelJs](http://babeljs.io).


Install all Build/Deploy tools dependencies by running:

```bash
$> npm install
```

Now you need to create a Firebase/Google Project. Do this on the [Firebase Console](https://firebase.google.com/console)

Once you project is created copy the initialization snippet from: **Overview > Add Firebase to your web app** into the bottom of the `index.html` file where the `TODO` placeholder is.

Also copy the value of the `storageBucket` attribute that's in the initialization snippet (e.g. `my-project-12345.appspot.com`) into the `storage.rules` file where the `<STORAGE_BUCKET>` placeholder is, below the `TODO`.


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
