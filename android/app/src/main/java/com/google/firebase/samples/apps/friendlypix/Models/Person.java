package com.google.firebase.samples.apps.friendlypix.Models;

public class Person {
    private String displayName;
    private String photoUrl;

    public Person() {

    }

    public Person(String displayName, String photoUrl) {
        this.displayName = displayName;
        this.photoUrl = photoUrl;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }
}
