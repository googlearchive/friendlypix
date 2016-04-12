package com.google.firebase.samples.apps.friendlypix;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

class FirebaseUtil {
    // TODO: Decide to standardize on one of getFirebaseUrl or GetBaseRef
    // TODO: Add getPostsRef, getUsersRef, etc.
    public static String getFirebaseUrl() {
        return  "https://friendlypix-4fa22.firebaseio.com";
    }

    public static DatabaseReference getBaseRef() {
        return FirebaseDatabase.getInstance().getReference();
    }

    public static String getCurrentUserId() {
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user != null) {
            return user.getUid();
        }
        return null;
    }

    public static DatabaseReference getCurrentUserRef() {
        return getBaseRef().child("users").child(getCurrentUserId());
    }
}
