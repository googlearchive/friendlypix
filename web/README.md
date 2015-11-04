# Friendly Pix JS

Friendly Pix JS is a sample application demonstrating how to build a JavaScript/Web application with the Firebase Platform.

Friendly Pix is where you can share photos by theme, follow posters, comment on photos and find photos near me.


## Initial setup, build tools and dependencies

Friendly Pix JS is build using JavaScript and Firebase and hosted on Firebase static hosting. JavaScript dependencies are managed using [bower](http://bower.io/) and Build/Deploy tools dependencies are managed using [npm](https://www.npmjs.com/).

Install [bower](http://bower.io/) and [npm](https://www.npmjs.com/) on your system.

Install all JavaScript dependencies by running:

```bash
bower install
```

Install all Build/Deploy tools dependencies by running:

```bash
npm install
```

This will install the Firebase CLI.

Now you need to create a Firebase/Google Project. Do this on the [App Manager (Staging)](https://pantheon-staging-sso.corp.google.com/mobilesdk/console/)

> PS: If this give you an error you need to initially follow a small process to enable the experiment on [this doc](https://docs.google.com/document/d/18iI_4uG6uh_AcewWD9OVTQbq_xNZRNAUzgcf7QML2Ek/edit#heading=h.36bxeqj15c70)

Note your App ID. You can find the App ID in the URL of the App Manager:
`https://pantheon-staging-sso.corp.google.com/mobilesdk/console/project/<APP_ID>/overview`

Example: for `https://pantheon-staging-sso.corp.google.com/mobilesdk/console/project/friendlypix-92420/overview` then `friendlypix-92420` is your App ID.


## Start a local development server

You need to have installed the Firebase CLI by running `npm install`.

You can start a local development server by running:

```bash
firebase serve
```

Then open [http://localhost:5000](http://localhost:5000)


## Deploy the app to prod

Deploy to Firebase using the following command:

```bash
firebase deploy -m "Cool new deploy"
```

This deploys a new version of your code that will be served from `https://<APP_ID>.firebaseapp-staging.com`


## Contributing

We'd love that you contribute to the project. Before doing so please read our [Contributor guide](CONTRIBUTING.md).


## License

© Google, 2011. Licensed under an [Apache-2](LICENSE) license.
