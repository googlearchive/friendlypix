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
 * Handles the single post UI.
 */
friendlyPix.Post = class {
  /**
   * Initializes the single post's UI.
   * @constructor
   */
  constructor() {
    // List of all times running on the page.
    this.timers = [];

    // Firebase SDK.
    this.database = firebase.app().database();
    this.storage = firebase.app().storage();
    this.auth = firebase.app().auth();

    $(document).ready(() => {
      // Pointers to DOM elements.
      this.postPage = $('#page-post');
      this.postElement = $('.fp-post', this.postPage);
      this.toast = $('.mdl-js-snackbar');
      this.theatre = $('.fp-theatre');
    });
  }

  /**
   * Creates an unattached clone of the single post element.
   * @return friendlyPix.Post
   */
  clone() {
    const clone = new friendlyPix.Post();
    $(document).ready(() => {
      clone.postElement = friendlyPix.MaterialUtils.cloneElementWithTextField(clone.postElement);
    });
    return clone;
  }

  /**
   * Loads the given post's details.
   */
  loadPost(postId) {
    // Load the posts information.
    friendlyPix.firebase.getPostData(postId).then(snapshot => {
      const post = snapshot.val();
      // Clear listeners and previous post data.
      this.clear();
      if (!post) {
        var data = {
          message: 'This post does not exists.',
          timeout: 5000
        };
        this.toast[0].MaterialSnackbar.showSnackbar(data);
        if (this.auth.currentUser) {
          page(`/user/${this.auth.currentUser.uid}`);
        } else {
          page(`/feed`);
        }
      } else {
        this.fillPostData(snapshot.key, post.thumb_url || post.url, post.text, post.author,
            post.timestamp, post.thumb_storage_uri, post.full_storage_uri, post.full_url);
      }
    });
  }

  /**
   * Clears all listeners and times in the given element.
   */
  clear() {
    // Stops all timers if any.
    this.timers.forEach(timer => clearInterval(timer));
    this.timers = [];

    const newElement = friendlyPix.MaterialUtils.cloneElementWithTextField(this.postElement);
    if (this.postElement.parent()) {
      this.postElement.parent().append(newElement);
      this.postElement.detach();
    }
    this.postElement = newElement;

    // Remove Firebase listeners.
    friendlyPix.firebase.cancelAllSubscriptions();
  }

  /**
   * Displays the given list of `comments` in the post.
   */
  displayComments(comments) {
    const commentsIds = Object.keys(comments);
    for (let i = commentsIds.length - 1; i >= 0; i--) {
      $('.fp-comments', this.postElement).prepend(
          friendlyPix.Post.createCommentHtml(comments[commentsIds[i]].author,
              comments[commentsIds[i]].text));
    }
  }

  /**
   * Shows the "show more comments" button and binds it the `nextPage` callback. If `nextPage` is
   * `null` then the button is hidden.
   */
  displayNextPageButton(nextPage) {
    const nextPageButton = $('.fp-morecomments', this.postElement);
    if (nextPage) {
      nextPageButton.show();
      nextPageButton.unbind('click');
      nextPageButton.prop('disabled', false);
      nextPageButton.click(() => nextPage().then(data => {
        nextPageButton.prop('disabled', true);
        this.displayComments(data.entries);
        this.displayNextPageButton(data.nextPage);
      }));
    } else {
      nextPageButton.hide();
    }
  }

  /**
   * Fills the post's Card with the given details.
   * Also sets all auto updates and listeners on the UI elements of the post.
   */
  fillPostData(postId, thumbUrl, imageText, author, timestamp, thumbStorageUri, picStorageUri, picUrl) {
    const post = this.postElement;

    // Fills element's author profile.
    $('.fp-usernamelink', post).attr('href', `/user/${author.uid}`);
    $('.fp-avatar', post).css('background-image',
        `url(${author.profile_picture || '/images/silhouette.jpg'})`);
    $('.fp-username', post).text(author.full_name || 'Anonymous');

    // Shows the pic's thumbnail.
    $('.fp-image', post).css('background-image', `url("${thumbUrl.replace(/"/g, '\\"')}")`);
    $('.fp-image', post).unbind('click');
    $('.fp-image', post).click(() => this.enterTheatreMode(picUrl || thumbUrl));

    this._setupDate(postId, timestamp);
    this._setupDeleteButton(postId, author, picStorageUri, thumbStorageUri);
    this._setupLikeCountAndStatus(postId);
    this._setupComments(postId, author, imageText);
    return post;
  }

  /**
   * Leaves the theatre mode.
   */
  leaveTheatreMode() {
    this.theatre.hide();
    this.theatre.unbind('click');
    $(document).unbind('keydown');
  }

  /**
   * Leaves the theatre mode.
   */
  enterTheatreMode(picUrl) {
    $('.fp-fullpic', this.theatre).prop('src', picUrl);
    this.theatre.css('display', 'flex');
    // Leave theatre mode if click or ESC key down.
    this.theatre.click(() => this.leaveTheatreMode());
    $(document).keydown(e => {
      if (e.which === 27) {
        this.leaveTheatreMode();
      }
    });
  }

  /**
   * Shows the publishing date of the post and updates this date live.
   * @private
   */
  _setupDate(postId, timestamp) {
    const post = this.postElement;

    $('.fp-time', post).attr('href', `/post/${postId}`);
    $('.fp-time', post).text(friendlyPix.Post.getTimeText(timestamp));
    // Update the time counter every minutes.
    this.timers.push(setInterval(
      () => $('.fp-time', post).text(friendlyPix.Post.getTimeText(timestamp)), 60000));
  }

  /**
   * Shows comments and binds actions to the comments form.
   * @private
   */
  _setupComments(postId, author, imageText) {
    const post = this.postElement;

    // Creates the initial comment with the post's text.
    $('.fp-first-comment', post).empty();
    $('.fp-first-comment', post).append(friendlyPix.Post.createCommentHtml(author, imageText));

    // Load first page of comments and listen to new comments.
    $('.fp-comments', post).empty();
    friendlyPix.firebase.getComments(postId).then(data => {
      this.displayComments(data.entries);
      this.displayNextPageButton(data.nextPage);

      // Display any new comments.
      const commentIds = Object.keys(data.entries);
      friendlyPix.firebase.subscribeToComments(postId, (commentId, commentData) => {
        $('.fp-comments', post).append(
          friendlyPix.Post.createCommentHtml(commentData.author, commentData.text));
      }, commentIds ? commentIds[commentIds.length - 1] : 0);
    });

    if (this.auth.currentUser) {
      // Bind comments form posting.
      $('.fp-add-comment', post).submit(e => {
        e.preventDefault();
        const commentText = $(`.mdl-textfield__input`, post).val();
        friendlyPix.firebase.addComment(postId, commentText);
        $(`.mdl-textfield__input`, post).val('');
      });
      const ran = Math.floor(Math.random() * 10000000);
      $('.mdl-textfield__input', post).attr('id', `${postId}-${ran}-comment`);
      $('.mdl-textfield__label', post).attr('for', `${postId}-${ran}-comment`);
      // Show comments form.
      $('.fp-action', post).css('display', 'flex');
    }
  }

  /**
   * Shows/Hode and binds actions to the Delete button.
   * @private
   */
  _setupDeleteButton(postId, author, picStorageUri, thumbStorageUri) {
    const post = this.postElement;

    if (this.auth.currentUser && this.auth.currentUser.uid === author.uid && picStorageUri) {
      $('.fp-delete-post', post).show();
      $('.fp-delete-post', post).click(() => {
        swal({
          title: 'Are you sure?',
          text: 'You will not be able to recover this post!',
          type: 'warning',
          showCancelButton: true,
          confirmButtonColor: '#DD6B55',
          confirmButtonText: 'Yes, delete it!',
          closeOnConfirm: false,
          showLoaderOnConfirm: true,
          allowEscapeKey: true
        }, () => {
          $('.fp-delete-post', post).prop('disabled', true);
          friendlyPix.firebase.deletePost(postId, picStorageUri, thumbStorageUri).then(() => {
            swal({
              title: 'Deleted!',
              text: 'Your post has been deleted.',
              type: 'success',
              timer: 2000
            });
            $('.fp-delete-post', post).prop('disabled', false);
            page(`/user/${this.auth.currentUser.uid}`);
          }).catch(error => {
            swal.close();
            $('.fp-delete-post', post).prop('disabled', false);
            const data = {
              message: `There was an error deleting your post: ${error}`,
              timeout: 5000
            };
            this.toast[0].MaterialSnackbar.showSnackbar(data);
          });
        });
      });
    } else {
      $('.fp-delete-post', post).hide();
    }
  }

  /**
   * Starts Likes count listener and on/off like status.
   * @private
   */
  _setupLikeCountAndStatus(postId) {
    const post = this.postElement;

    if (this.auth.currentUser) {
      // Listen to like status.
      friendlyPix.firebase.registerToUserLike(postId, isliked => {
        if (isliked) {
          $('.fp-liked', post).show();
          $('.fp-not-liked', post).hide();
        } else {
          $('.fp-liked', post).hide();
          $('.fp-not-liked', post).show();
        }
      });

      // Add event listeners.
      $('.fp-liked', post).click(() => friendlyPix.firebase.updateLike(postId, false));
      $('.fp-not-liked', post).click(() => friendlyPix.firebase.updateLike(postId, true));
    } else {
      $('.fp-liked', post).hide();
      $('.fp-not-liked', post).hide();
      $('.fp-action', post).hide();
    }

    // Listen to number of Likes.
    friendlyPix.firebase.registerForLikesCount(postId, nbLikes => {
      if (nbLikes > 0) {
        $('.fp-likes', post).show();
        $('.fp-likes', post).text(nbLikes + ' like' + (nbLikes === 1 ? '' : 's'));
      } else {
        $('.fp-likes', post).hide();
      }
    });
  }

  /**
   * Returns the HTML for a post's comment.
   */
  static createCommentHtml(author, text) {
    return `
        <div class="fp-comment">
            <a class="fp-author" href="/user/${author.uid}">${author.full_name || 'Anonymous'}</a>:
            <span class="fp-text">${text}</span>
        </div>`;
  }

  /**
   * Given the time of creation of a post returns how long since the creation of the post in text
   * format. e.g. 5d, 10h, now...
   */
  static getTimeText(postCreationTimestamp) {
    let millis = Date.now() - postCreationTimestamp;
    const ms = millis % 1000;
    millis = (millis - ms) / 1000;
    const secs = millis % 60;
    millis = (millis - secs) / 60;
    const mins = millis % 60;
    millis = (millis - mins) / 60;
    const hrs = millis % 24;
    const days = (millis - hrs) / 24;
    var timeSinceCreation = [days, hrs, mins, secs, ms];

    let timeText = 'Now';
    if (timeSinceCreation[0] !== 0) {
      timeText = timeSinceCreation[0] + 'd';
    } else if (timeSinceCreation[1] !== 0) {
      timeText = timeSinceCreation[1] + 'h';
    } else if (timeSinceCreation[2] !== 0) {
      timeText = timeSinceCreation[2] + 'm';
    }
    return timeText;
  }
};

friendlyPix.post = new friendlyPix.Post();
