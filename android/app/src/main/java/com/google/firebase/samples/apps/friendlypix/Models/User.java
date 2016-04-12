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
