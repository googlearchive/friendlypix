/**
 * Copyright 2015 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
'use strict';

//Firebase.INTERNAL.setAuthenticationServer('https://staging-auth.firebase.com');
//var firebase = new Firebase('https://friendlypix-js-dev-44faa.firebaseio-staging.com');
var firebase = new Firebase('https://fborange.firebaseio.com');
var userId;

// DOM Elements
var signInButton = $('.fp-sign-in-button');
var signedInUserContainer = $('.fp-signed-in-user-container');
var signedInUserAvatar = $('.fp-avatar', signedInUserContainer);
var signedInUsername = $('.fp-username', signedInUserContainer);
var signOutButton = $('.fp-sign-out');
var signedOutOnlyElements = $('.fp-signed-out-only');
var signedInOnlyElements = $('.fp-signed-in-only');
var usernameLink = $('.fp-usernamelink');

// Starts the auth popup flow.
function startAuth() {
  firebase.authWithOAuthPopup('google', function(error) {
    if (error) {
      console.log('Login Failed!', error);
    }
  });
}

// Displays the User information in the UI or hides it and displays the
// "Sign-In" button if the user isn't signed-in.
function displayUserInfo(authData) {
  if (!authData) {
    signedOutOnlyElements.show();
    signedInOnlyElements.hide();
    userId = undefined;
    signedInUserAvatar.css('background-image', '');
  } else {
    signedOutOnlyElements.hide();
    signedInOnlyElements.show();
    userId = authData.uid;
    signedInUserAvatar.css('background-image', 'url("' +
      fixGoogleProfileImageUrl(authData.google.profileImageURL, 50) + '")');
    signedInUsername.text(authData.google.displayName);
    usernameLink.attr('href', '/users/' + authData.uid);
    saveUserData(fixGoogleProfileImageUrl(authData.google.profileImageURL, 30),
      fixGoogleProfileImageUrl(authData.google.profileImageURL, 300),
      authData.google.displayName, authData.uid);
  }
}

// Trick to fix the Google profile Image URL so that it displays properly
// instead of showing a negative of the image.
function fixGoogleProfileImageUrl(url, size) {
  var splittedUrl = url.split('/');
  splittedUrl.splice(splittedUrl.length - 1, 0, 's' + size);
  return splittedUrl.join('/');
}

// Saves or Update user data to Firebase.
function saveUserData(smallAvatarUrl, largeAvatarUrl, displayName, userid) {
  var usersRef = firebase.child('users');
  usersRef.child(userid).update({
    smallAvatarUrl: smallAvatarUrl,
    largeAvatarUrl: largeAvatarUrl,
    displayName: displayName
  });
}

// Bindings on load.
$(document).ready(function() {
  signInButton.click(startAuth);
  firebase.onAuth(displayUserInfo);
  signOutButton.click(function() {firebase.unauth(function() {});});
});
