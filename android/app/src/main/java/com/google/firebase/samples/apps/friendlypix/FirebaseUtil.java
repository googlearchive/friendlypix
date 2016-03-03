package com.google.firebase.samples.apps.friendlypix;

import com.firebase.client.Firebase;
import com.google.firebase.auth.FirebaseAuth;

class FirebaseUtil {
    // TODO: Decide to standardize on one of getFirebaseUrl or GetBaseRef
    // TODO: Add getPostsRef, getUsersRef, etc.
    public static String getFirebaseUrl() {
        return  "https://friendlypix-4fa22.firebaseio.com";
    }

    public static Firebase getBaseRef() {
        return new Firebase(getFirebaseUrl());
    }

    public static String getCurrentUserId() {
        return FirebaseAuth.getAuth().getCurrentUser().getUserId();
    }

    public static Firebase getCurrentUserRef() {
        return getBaseRef().child("users").child(getCurrentUserId());
    }
}
