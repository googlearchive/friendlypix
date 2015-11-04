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

var searchForm = $('#searchForm');
var searchField = $('#searchQuery');

// Open the search page.
function searchSubmit() {
  page('/search/' + encodeURIComponent(searchField.val()));
  return false;
}

// Bindings on load.
$(document).ready(function() {
  searchForm.submit(searchSubmit);
});
