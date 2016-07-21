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
   * @return {number}
   */
  static get FULL_IMAGE_SPECS() {
    return {
      maxDimension: 1280,
      quality: 0.9
    };
  }

  /**
   * @return {number}
   */
  static get THUMB_IMAGE_SPECS() {
    return {
      maxDimension: 640,
      quality: 0.7
    };
  }

  /**
   * Inititializes the pics uploader/post creator.
   * @constructor
   */
  constructor() {
    // Firebase SDK
    this.database = firebase.app().database();
    this.auth = firebase.app().auth();
    this.storage = firebase.app().storage();

    this.addPolyfills();

    $(document).ready(() => {
      // DOM Elements
      this.addButton = $('#add');
      this.addButtonFloating = $('#add-floating');
      this.imageInput = $('#fp-mediacapture');
      this.overlay = $('.fp-overlay', '#page-add');
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
      this.imageCaptionInput.keyup(() => this.uploadButton.prop('disabled', !this.imageCaptionInput.val()));
    });
  }

  // Adds polyfills requireed for the Uploader.
  addPolyfills() {
    // Polyfill for canvas.toBlob().
    if (!HTMLCanvasElement.prototype.toBlob) {
      Object.defineProperty(HTMLCanvasElement.prototype, 'toBlob', {
        value: function(callback, type, quality) {
          var binStr = atob(this.toDataURL(type, quality).split(',')[1]);
          var len = binStr.length;
          var arr = new Uint8Array(len);

          for (var i = 0; i < len; i++) {
            arr[i] = binStr.charCodeAt(i);
          }

          callback(new Blob([arr], {type: type || 'image/png'}));
        }
      });
    }
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
    this.uploadButton.prop('disabled', true);
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
   * Returns a Canvas containing the given image scaled down to the given max dimension.
   * @private
   * @static
   */
  static _getScaledCanvas(image, maxDimension) {
    const thumbCanvas = document.createElement('canvas');
    if (image.width > maxDimension ||
      image.height > maxDimension) {
      if (image.width > image.height) {
        thumbCanvas.width = maxDimension;
        thumbCanvas.height = maxDimension * image.height / image.width;
      } else {
        thumbCanvas.width = maxDimension * image.width / image.height;
        thumbCanvas.height = maxDimension;
      }
    } else {
      thumbCanvas.width = image.width;
      thumbCanvas.height = image.height;
    }
    thumbCanvas.getContext('2d').drawImage(image, 0, 0, image.width, image.height,
      0, 0, thumbCanvas.width, thumbCanvas.height);
    return thumbCanvas;
  }

  /**
   * Generates the full size image and image thumb using canvas and returns them in a promise.
   */
  generateImages() {
    const fullDeferred = new $.Deferred();
    const thumbDeferred = new $.Deferred();

    const resolveFullBlob = blob => fullDeferred.resolve(blob);
    const resolveThumbBlob = blob => thumbDeferred.resolve(blob);

    const displayPicture = url => {
      const image = new Image();
      image.src = url;

      // Generate thumb.
      const maxThumbDimension = friendlyPix.Uploader.THUMB_IMAGE_SPECS.maxDimension;
      const thumbCanvas = friendlyPix.Uploader._getScaledCanvas(image, maxThumbDimension);
      thumbCanvas.toBlob(resolveThumbBlob, 'image/jpeg', friendlyPix.Uploader.THUMB_IMAGE_SPECS.quality);

      // Generate full sized image.
      const maxFullDimension = friendlyPix.Uploader.FULL_IMAGE_SPECS.maxDimension;
      const fullCanvas = friendlyPix.Uploader._getScaledCanvas(image, maxFullDimension);
      fullCanvas.toBlob(resolveFullBlob, 'image/jpeg', friendlyPix.Uploader.FULL_IMAGE_SPECS.quality);
    };

    const reader = new FileReader();
    reader.onload = e => displayPicture(e.target.result);
    reader.readAsDataURL(this.currentFile);

    return Promise.all([fullDeferred.promise(), thumbDeferred.promise()]).then(results => {
      return {
        full: results[0],
        thumb: results[1]
      };
    });
  }

  /**
   * Uploads the pic to Firebase Storage and add a new post into the Firebase Database.
   */
  uploadPic(e) {
    e.preventDefault();
    this.disableUploadUi(true);
    var imageCaption = this.imageCaptionInput.val();

    this.generateImages().then(pics => {
      // Upload the File upload to Firebase Storage and create new post.
      friendlyPix.firebase.uploadNewPic(pics.full, pics.thumb, this.currentFile.name, imageCaption)
          .then(postId => {
            page(`/user/${this.auth.currentUser.uid}`);
            var data = {
              message: 'New pic has been posted!',
              actionHandler: () => page(`/post/${postId}`),
              actionText: 'View',
              timeout: 10000
            };
            this.toast[0].MaterialSnackbar.showSnackbar(data);
            this.disableUploadUi(false);
          }, error => {
            console.error(error);
            var data = {
              message: `There was an error while posting your pic. Sorry!`,
              timeout: 5000
            };
            this.toast[0].MaterialSnackbar.showSnackbar(data);
            this.disableUploadUi(false);
          });
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
