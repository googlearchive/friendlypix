package com.google.firebase.samples.apps.friendlypix.Models;

public class Comment {
    private String author;
    private String content;
    private Object timestamp;

    public Comment() {
        // empty default constructor, necessary for Firebase to be able to deserialize comments
    }

    public Comment(String author, String content, Object timestamp) {
        this.author = author;
        this.content = content;
        this.timestamp = timestamp;
    }

    public String getAuthor() {
        return author;
    }

    public String getContent() {
        return content;
    }

    public Object getTimestamp() {
        return timestamp;
    }
}
