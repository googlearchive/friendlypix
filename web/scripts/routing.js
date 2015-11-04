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

// We use Page.js for routing. This is a Micro
// client-side router inspired by the Express router
// More info: https://visionmedia.github.io/page.js/
// Middleware
'use strict';

var pagesElements = $('[id^=page-]');

// Scrolls the page to top.
function scrollToTop() {
  $('html,body').animate({scrollTop: 0},0);
}

// Pipes the given function and passes the given attribute and Page.js context.
// Set 'optContinue' to true if there are further functions to call.
function pipe(funct, attribute, optContinue) {
  return function(context, next) {
    if (funct) {
      var params = Object.keys(context.params)
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

// Potentially close the drawer.
function closeDrawer() {
  var drawerObfuscator = $('.mdl-layout__obfuscator');
  if (drawerObfuscator[0] && drawerObfuscator.css('visibility') !== 'hidden') {
    drawerObfuscator[0].click();
  }
}

// Returns a function that displays the given page and hides the other ones.
function displayPage(pageId, context) {
  setLinkAsActive(context.canonicalPath);
  pagesElements.each(function(index, element) {
    if (element.id === 'page-' + pageId) {
      $(element).show();
    } else {
      $(element).hide();
    }
  });
  closeDrawer();
  scrollToTop();
}

// Highlights the correct menu item/link.
function setLinkAsActive(canonicalPath) {
  $('.is-active').removeClass('is-active');
  $('[href="' + canonicalPath + '"]').addClass('is-active');
}

// Routes
page('/', /*pipe(TODO: load homepage pics),*/ pipe(displayPage, 'home'));
page('/recent', /*pipe(TODO: load recent pics),*/ pipe(displayPage, 'home'));
page('/popular', /*pipe(TODO: load popular pics),*/ pipe(displayPage, 'home'));
page('/users/:userid', pipe(loadUser, null, true), pipe(displayPage, 'user-info'));
page('/search/:query', /*pipe(TODO: load search query),*/ pipe(displayPage, 'home'));
page.redirect('/search/', '/');
page('/contact', pipe(displayPage, 'contact'));
page('/about', pipe(displayPage, 'about'));
page('/add', pipe(displayPage, 'add'));

// add #! before urls
page({
  hashbang: true
});
