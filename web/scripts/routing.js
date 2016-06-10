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
 * Handles the pages/routing.
 */
friendlyPix.Router = class {

  /**
   * Initializes the Friendly Pix controller/router.
   * @constructor
   */
  constructor() {
    $(document).ready(() => {
      friendlyPix.auth.waitForAuth.then(() => {
        // Dom elements.
        this.pagesElements = $('[id^=page-]');
        this.splashLogin = $('#login', '#page-splash');

        // Make sure /add is never opened on website load.
        if (window.location.pathname === '/add') {
          page('/');
        }

        // Configuring routes.
        const pipe = friendlyPix.Router.pipe;
        const displayPage = this.displayPage.bind(this);
        const loadUser = userId => friendlyPix.userPage.loadUser(userId);
        const showHomeFeed = () => friendlyPix.feed.showHomeFeed();
        const showGeneralFeed = () => friendlyPix.feed.showGeneralFeed();
        const clearFeed = () => friendlyPix.feed.clear();
        const showPost = postId => friendlyPix.post.loadPost(postId);

        page('/', pipe(showHomeFeed, null, true),
            pipe(displayPage, {pageId: 'feed', onlyAuthed: true}));
        page('/feed', pipe(showGeneralFeed, null, true), pipe(displayPage, {pageId: 'feed'}));
        page('/post/:postId', pipe(showPost, null, true), pipe(displayPage, {pageId: 'post'}));
        page('/user/:userId', pipe(loadUser, null, true), pipe(displayPage, {pageId: 'user-info'}));
        page('/about', pipe(clearFeed, null, true), pipe(displayPage, {pageId: 'about'}));
        page('/add', pipe(displayPage, {pageId: 'add', onlyAuthed: true}));
        page('*', () => page('/'));

        // Start routing.
        page();
      });
    });
  }

  /**
   * Returns a function that displays the given page and hides the other ones.
   * if `onlyAuthed` is set to true then the splash page will be displayed instead of the page if
   * the user is not signed-in.
   */
  displayPage(attributes, context) {
    const onlyAuthed = attributes.onlyAuthed;
    let pageId = attributes.pageId;

    if (onlyAuthed && !firebase.app().auth().currentUser) {
      pageId = 'splash';
      this.splashLogin.show();
    }
    friendlyPix.Router.setLinkAsActive(context.canonicalPath);
    this.pagesElements.each(function(index, element) {
      if (element.id === 'page-' + pageId) {
        $(element).show();
      } else if (element.id === 'page-splash') {
        $(element).fadeOut(1000);
      } else {
        $(element).hide();
      }
    });
    friendlyPix.MaterialUtils.closeDrawer();
    friendlyPix.Router.scrollToTop();
  }

  /**
   * Reloads the current page.
   */
  reloadPage() {
    let path = window.location.pathname;
    if (path === '') {
      path = '/';
    }
    page(path);
  }

  /**
   * Scrolls the page to top.
   */
  static scrollToTop() {
    $('html,body').animate({scrollTop: 0}, 0);
  }

  /**
   * Pipes the given function and passes the given attribute and Page.js context.
   * Set 'optContinue' to true if there are further functions to call.
   */
  static pipe(funct, attribute, optContinue) {
    return (context, next) => {
      if (funct) {
        const params = Object.keys(context.params);
        if (!attribute && params.length > 0) {
          funct(context.params[params[0]], context);
        } else {
          funct(attribute, context);
        }
      }
      if (optContinue) {
        next();
      }
    };
  }

  /**
   * Highlights the correct menu item/link.
   */
  static setLinkAsActive(canonicalPath) {
    if (canonicalPath === '') {
      canonicalPath = '/';
    }
    $('.is-active').removeClass('is-active');
    $(`[href="${canonicalPath}"]`).addClass('is-active');
  }
};

friendlyPix.router = new friendlyPix.Router();
