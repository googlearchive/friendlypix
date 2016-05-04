/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.firebase.samples.apps.friendlypix.Models;

import java.util.Map;

public class User {
    private Map<String, Boolean> posts;
    private Map<String, Boolean> likes;
    private Map<String, Boolean> followers;
    private Map<String, Boolean> following;
    private Map<String, Boolean> feed;
    private String displayName;
    private String photoUrl;

    public User() {

    }

    public Map<String, Boolean> getPosts() {
        return posts;
    }

    public Map<String, Boolean> getLikes() {
        return likes;
    }

    public Map<String, Boolean> getFollowers() {
        return followers;
    }

    public Map<String, Boolean> getFollowing() {
        return following;
    }

    public Map<String, Boolean> getFeed() { return feed; }
}
