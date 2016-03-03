package com.google.firebase.samples.apps.friendlypix.Models;

import java.util.Map;

public class User {
    private String displayName;
    private String photoUrl;
    private Map<String, Boolean> posts;
    private Map<String, Boolean> likes;
    private Map<String, Boolean> followers;
    private Map<String, Boolean> following;

    public User() {

    }

    public User(String displayName, String photoUrl) {
        this.displayName = displayName;
        this.photoUrl = photoUrl;
    }

    public String getDisplayName() {

        return displayName;
    }

    public String getPhotoUrl() {
        return photoUrl;
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
}
