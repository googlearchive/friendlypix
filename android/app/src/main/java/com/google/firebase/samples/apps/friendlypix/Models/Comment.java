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

public class Comment {
    private Author author;
    private String text;
    private Object timestamp;

    public Comment() {
        // empty default constructor, necessary for Firebase to be able to deserialize comments
    }

    public Comment(Author author, String text, Object timestamp) {
        this.author = author;
        this.text = text;
        this.timestamp = timestamp;
    }

    public Author getAuthor() {
        return author;
    }

    public String getText() {
        return text;
    }

    public Object getTimestamp() {
        return timestamp;
    }
}
