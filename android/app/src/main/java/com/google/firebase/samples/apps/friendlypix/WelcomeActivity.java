/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.firebase.samples.apps.friendlypix;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;

public class WelcomeActivity extends AppCompatActivity implements View.OnClickListener {

    private static final String TAG = "WelcomeActivity";
    private FirebaseAuth mAuth;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);

        findViewById(R.id.sign_in_button).setOnClickListener(this);
        findViewById(R.id.explore_button).setOnClickListener(this);

        mAuth = FirebaseAuth.getInstance();
        if (FirebaseUtil.getCurrentUserId() != null) {
            startActivity(new Intent(this, ProfileActivity.class));
        }
    }

    @Override
    public void onClick(View v) {
        int id = v.getId();
        switch (id) {
            case R.id.explore_button:
                mAuth.signInAnonymously().addOnSuccessListener(new OnSuccessListener<AuthResult>() {
                    @Override
                    public void onSuccess(AuthResult authResult) {
                        Intent feedsIntent = new Intent(WelcomeActivity.this, FeedsActivity.class);
                        startActivity(feedsIntent);
                    }
                }).addOnFailureListener( new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        Toast.makeText(WelcomeActivity.this, "Unable to sign in anonymously.",
                                Toast.LENGTH_SHORT).show();
                            Log.e(TAG, e.getMessage());
                    }
                });
                break;
            case R.id.sign_in_button:
                Intent signInIntent = new Intent(this, ProfileActivity.class);
                startActivity(signInIntent);
                break;
        }
    }
}
