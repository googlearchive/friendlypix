package com.google.firebase.samples.apps.friendlypix.Models;

public class Comment {
    private String author;
    private String text;
    private Object timestamp;

    public Comment() {
        // empty default constructor, necessary for Firebase to be able to deserialize comments
    }

    public Comment(String author, String text, Object timestamp) {
        this.author = author;
        this.text = text;
        this.timestamp = timestamp;
    }

    public String getAuthor() {
        return author;
    }

    public String getText() {
        return text;
    }

    public Object getTimestamp() {
        return timestamp;
    }
}
