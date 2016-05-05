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

window.friendlyPix = window.friendlyPix || {};

/**
 * Handles uploads of new pics.
 */
friendlyPix.Uploader = class {

  /**
   * Inititializes the pics uploader/post creator.
   * @constructor
   */
  constructor() {
    // Firebase SDK
    this.database = firebase.app().database();
    this.auth = firebase.app().auth();
    this.storage = firebase.app().storage();

    $(document).ready(() => {
      // DOM Elements
      this.addButton = $('#add');
      this.addButtonFloating = $('#add-floating');
      this.imageInput = $('#fp-mediacapture');
      this.overlay = $('#page-add .fp-overlay');
      this.newPictureContainer = $('#newPictureContainer');
      this.uploadButton = $('.fp-upload');
      this.imageCaptionInput = $('#imageCaptionInput');
      this.uploadPicForm = $('#uploadPicForm');
      this.toast = $('.mdl-js-snackbar');

      // Event bindings
      this.addButton.click(() => this.initiatePictureCapture());
      this.addButtonFloating.click(() => this.initiatePictureCapture());
      this.imageInput.change(e => this.readPicture(e));
      this.uploadPicForm.submit(e => this.uploadPic(e));
    });
  }

  /**
   * Start taking a picture.
   */
  initiatePictureCapture() {
    this.imageInput.trigger('click');
  }

  /**
   * Displays the given pic in the New Pic Upload dialog.
   */
  displayPicture(url) {
    this.newPictureContainer.attr('src', url);
    page('/add');
    this.imageCaptionInput.focus();
  }

  /**
   * Enables or disables the UI. Typically while the image is uploading.
   */
  disableUploadUi(disabled) {
    this.uploadButton.prop('disabled', disabled);
    this.addButton.prop('disabled', disabled);
    this.addButtonFloating.prop('disabled', disabled);
    this.imageCaptionInput.prop('disabled', disabled);
    this.overlay.toggle(disabled);
  }

  /**
   * Reads the picture the has been selected by the file picker.
   */
  readPicture(event) {
    this.clear();

    var file = event.target.files[0]; // FileList object
    this.currentFile = file;

    // Clear the selection in the file picker input.
    this.imageInput.wrap('<form>').closest('form').get(0).reset();
    this.imageInput.unwrap();

    // Only process image files.
    if (file.type.match('image.*')) {
      var reader = new FileReader();
      reader.onload = e => this.displayPicture(e.target.result);
      // Read in the image file as a data URL.
      reader.readAsDataURL(file);
      this.disableUploadUi(false);
    }
  }

  /**
   * Uploads the pic to Firebase Storage and add a new post into the Firebase Database.
   */
  uploadPic(e) {
    e.preventDefault();
    this.disableUploadUi(true);
    var imageCaption = this.imageCaptionInput.val();

    // Upload the File upload to Firebase Storage and create new post.
    friendlyPix.firebase.uploadNewPic(this.currentFile, imageCaption).then(postId => {
      page(`/users/${this.auth.currentUser.uid}`);
      var data = {
        message: 'New pic has been posted!',
        actionHandler: () => page(`/post/${postId}`),
        actionText: 'View',
        timeout: 10000
      };
      this.toast[0].MaterialSnackbar.showSnackbar(data);
      this.disableUploadUi(false);
    }, () => {
      var data = {
        message: `There was an error while posting your pic. Sorry!`,
        timeout: 5000
      };
      this.toast[0].MaterialSnackbar.showSnackbar(data);
      this.disableUploadUi(false);
    });
  }

  /**
   * Clear the uploader.
   */
  clear() {
    this.currentFile = null;

    // Cancel all Firebase listeners.
    friendlyPix.firebase.cancelAllSubscriptions();

    // Clear previously displayed pic.
    this.newPictureContainer.attr('src', '');

    // Clear the text field.
    friendlyPix.MaterialUtils.clearTextField(this.imageCaptionInput[0]);

    // Make sure UI is not disabled.
    this.disableUploadUi(false);
  }
};

friendlyPix.uploader = new friendlyPix.Uploader();
