package com.google.firebase.samples.apps.friendlypix;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;

public class WelcomeActivity extends AppCompatActivity implements View.OnClickListener {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);

        findViewById(R.id.sign_in_button).setOnClickListener(this);
        findViewById(R.id.explore_button).setOnClickListener(this);

        FirebaseApp firebaseApp = FirebaseApp.initializeApp(this,
                                                            getString(R.string.google_app_id),
                                                            new FirebaseOptions(getString(R.string.google_crash_reporting_api_key)));
        if (FirebaseAuth.getAuth().getCurrentUser() != null) {
            startActivity(new Intent(this, ProfileActivity.class));
        }
    }

    @Override
    public void onClick(View v) {
        int id = v.getId();
        switch (id) {
            case R.id.explore_button:
                Intent feedsIntent = new Intent(this, FeedsActivity.class);
                startActivity(feedsIntent);
                break;
            case R.id.sign_in_button:
                Intent signInIntent = new Intent(this, ProfileActivity.class);
                startActivity(signInIntent);
                break;
        }
    }
}
