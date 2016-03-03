package com.google.firebase.samples.apps.friendlypix.Models;

public class Post {
    private String author;
    private String url;
    private String text;
    private Object timestamp;
    private long likes;

    public Post() {
        // empty default constructor, necessary for Firebase to be able to deserialize blog posts
    }

    public Post(String author, String url, String text, Object timestamp) {
        this.author = author;
        this.url = url;
        this.text = text;
        this.timestamp = timestamp;
    }

    public String getAuthor() {
        return author;
    }

    public String getUrl() {
        return url;
    }

    public String getText() {
        return text;
    }

    public Object getTimestamp() {
        return timestamp;
    }

    public long getLikes() {
        return likes;
    }
}
