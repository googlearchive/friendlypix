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

// DOM Elements
var userAvatar = $('.fp-user-avatar');
var userUsername = $('.fp-user-username');
var userContainer = $('.fp-user-container');
var userInfoPageImageContainer = $('.fp-image-container', $('#page-user-info'));

// Displays the User information in the UI or hides it and displays the
// "Sign-In" button if the user isn't signed-in.
function loadUser(userid) {
  clearImages(userInfoPageImageContainer);
  firebase.child('users').orderByKey().equalTo(userid).once('value', function(snapshot) {
    var userInfo = snapshot.val()[userid];
    if (userInfo) {
      userAvatar.css('background-image', 'url("' + userInfo.largeAvatarUrl + '")');
      userUsername.text(userInfo.displayName);
    }
  });
  firebase.child('photos').orderByChild('userId').equalTo(userid).on('child_added', function(val) {
    var image = val.val();
    userContainer.after(createImageCard(image.imageDataUri, image.userId));
  });
}





function clearImages(element) {
  $('.fp-image', element).remove();
}

function createImageCard(imageUrl, userId) {
  var newElement = $(imageTemplate.replace('{imageUrl}', imageUrl));

  return newElement;
}

var imageTemplate =
  '<div class="fp-image mdl-cell mdl-cell--12-col mdl-cell--4-col-tablet mdl-cell--4-col-desktop mdl-grid mdl-grid--no-spacing">' +
  '  <div style="background-image: url({imageUrl})" class="mdl-card mdl-shadow--2dp mdl-cell mdl-cell--12-col mdl-cell--12-col-tablet mdl-cell--12-col-desktop">' +
  '</div></div>';
