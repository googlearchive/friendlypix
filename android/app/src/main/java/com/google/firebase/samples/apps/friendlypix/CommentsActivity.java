package com.google.firebase.samples.apps.friendlypix;

import android.os.Bundle;
import android.support.v4.app.FragmentManager;
import android.support.v7.app.AppCompatActivity;

public class CommentsActivity extends AppCompatActivity {
    public static final String POST_KEY_EXTRA = "post_key";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_comments);

        String postKey = getIntent().getStringExtra(POST_KEY_EXTRA);
        if (postKey == null) {
            finish();
        }

        FragmentManager fm = getSupportFragmentManager();
        fm.beginTransaction().add(R.id.comments_fragment, CommentsFragment.newInstance(postKey))
                .commit();
    }

}
