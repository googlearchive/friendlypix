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
var addButton = $('#add');
var addButtonFloating = $('#add-floating');
var imageInput = $('#fp-mediacapture');
var newPictureContainer = $('#newPictureContainer');
var uploadButton = $('.fp-upload');
var imageCaptionInput = $('#imageCaptionInput');
var uploadPicForm = $('#uploadPicForm');


// Start taking a picture.
function initiatePictureCapture() {
  imageInput.trigger('click');
}

function displayPicture(dataUrl) {
  newPictureContainer.attr('src', dataUrl);
  page('/add');
  imageCaptionInput.focus();
}

// A picture has been uploaded. Display it.
function readPicture(event) {
  var files = event.target.files; // FileList object

  var displayPic = function(e) {
    displayPicture(e.target.result);
  };

  // Loop through the FileList and render image files as thumbnails.
  for (var i = 0, f; f = files[i]; i++) {
    // Only process image files.
    if (!f.type.match('image.*')) {
      continue;
    }
    var reader = new FileReader();
    reader.onload = displayPic;
    // Read in the image file as a data URL.
    reader.readAsDataURL(f);
  }
  uploadButton.prop('disabled', false);
}

function uploadPic() {
  uploadButton.prop('disabled', true);
  var imageDataUri = newPictureContainer.attr('src');
  var imageCaption = imageCaptionInput.val();

  var photosRef = firebase.child('photos');
  generateThumbnail(imageDataUri, 400, 200, function(thumbDataUri) {
    photosRef.push({
      imageDataUri: thumbDataUri,
      imageCaption: imageCaption,
      timestamp: Firebase.ServerValue.TIMESTAMP,
      userId: userId
    }, function(error) {
      if (error) {
        // TODO: Show toast here when it's available in MDL
        console.log('Error while uploading the photo: ' + error);
      } else {
        imageCaptionInput.val('')
          .parent()[0].MaterialTextfield.boundUpdateClassesHandler();
        page('/users/' + userId);
        // TODO: Show toast here when it's available in MDL
        console.log('Photo has been shared successfully!');
      }
      uploadButton.prop('disabled', false);
    });
  });
  return false;
}

function generateThumbnail(originalDataUri, maxWidth, maxHeight, callback) {
  var canvas = document.createElement('canvas');
  var img = new Image();
  img.onload = function() {
    var scale = Math.min(1, Math.max(maxWidth / img.width, maxHeight / img.height));
    canvas.width = img.width * scale;
    canvas.height = img.height * scale;
    var ctx = canvas.getContext('2d');
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    callback(canvas.toDataURL('image/jpeg'));
  };
  img.src = originalDataUri;
}

// Bindings on load.
$(document).ready(function() {
  addButton.click(initiatePictureCapture);
  addButtonFloating.click(initiatePictureCapture);
  imageInput.change(readPicture);
  uploadPicForm.submit(uploadPic);
  // Make sure /add is never opened on website load.
  if (window.location.href.indexOf('/add') !== -1) {
    page('/');
  }
});
