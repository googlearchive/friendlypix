package com.google.firebase.samples.apps.friendlypix;


import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.firebase.client.Firebase;
import com.google.android.gms.auth.api.Auth;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseError;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.FirebaseUser;
import com.google.firebase.UserProfileChangeRequest;
import com.google.firebase.UserProfileChangeResult;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.GoogleAuthProvider;

import java.util.HashMap;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class ProfileActivity extends AppCompatActivity implements
        View.OnClickListener,
        GoogleApiClient.OnConnectionFailedListener {
    private static final String TAG = "ProfileActivity";
    private ViewGroup mProfileUi;
    private ViewGroup mSignInUi;
    private FirebaseAuth mAuth;
    private CircleImageView mProfilePhoto;
    private TextView mProfileUsername;
    private GoogleApiClient mGoogleApiClient;

    private static final int RC_SIGN_IN = 103;

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        FirebaseApp firebaseApp = FirebaseApp.initializeApp(this,
                getString(R.string.google_app_id),
                new FirebaseOptions(getString(R.string.google_crash_reporting_api_key)));

        // Initialize authentication and set up callbacks
        mAuth = FirebaseAuth.getAuth();

        // GoogleApiClient with Sign In
        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .enableAutoManage(this, this)
                .addApi(Auth.GOOGLE_SIGN_IN_API,
                        new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                .requestEmail()
                                .requestIdToken(getString(R.string.server_client_id))
                                .build())
                .build();

        mSignInUi = (ViewGroup) findViewById(R.id.sign_in_ui);
        mProfileUi = (ViewGroup) findViewById(R.id.profile);

        mProfilePhoto = (CircleImageView) findViewById(R.id.profile_user_photo);
        mProfileUsername = (TextView) findViewById(R.id.profile_user_name);

        findViewById(R.id.launch_sign_in).setOnClickListener(this);
        findViewById(R.id.show_feeds_button).setOnClickListener(this);
        findViewById(R.id.sign_out_button).setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {
        int id = v.getId();
        switch(id) {
            case R.id.launch_sign_in:
                mAuth.addAuthResultCallback(new FirebaseAuth.AuthResultCallbacks() {
                    @Override
                    public void onAuthenticated(@NonNull FirebaseUser firebaseUser) {
                        Log.d(TAG, "onAuthenticated:" + firebaseUser);
                        mAuth.removeAuthResultCallback(this);
                        showSignedInUI(firebaseUser);
                    }

                    @Override
                    public void onAuthenticationError(@NonNull FirebaseError firebaseError) {
                        Log.d(TAG, "onAuthenticationError:" + firebaseError.getErrorCode());
                        Log.e(TAG, "auth error: " + firebaseError.toString());
                        mAuth.removeAuthResultCallback(this);
                        showSignedOutUI();
                    }
                });
                launchSignInIntent();
                break;
            case R.id.sign_out_button:
                mAuth.signOut(this);
                showSignedOutUI();
                break;
            case R.id.show_feeds_button:
                Intent feedsIntent = new Intent(this, FeedsActivity.class);
                startActivity(feedsIntent);
                break;
        }
    }

    private void handleGoogleSignInResult(GoogleSignInResult result) {
        Log.d(TAG, "handleGoogleSignInResult:" + result.getStatus());
        if (result.isSuccess() && result.getSignInAccount() != null) {
            GoogleSignInAccount account = result.getSignInAccount();
            String idToken = account.getIdToken();
            final Uri photoUrl = account.getPhotoUrl();
            final String displayName = account.getDisplayName();
            mAuth.signInWithCredential(
                    GoogleAuthProvider.getCredential(idToken, null))
                    .setResultCallback(new ResultCallback<AuthResult>() {
                        @Override
                        public void onResult(@NonNull AuthResult result) {
                            Log.d(TAG, "onResult:" + result);
                            final FirebaseUser firebaseUser = result.getUser();
                            boolean updateRequired = false;
                            UserProfileChangeRequest.Builder profileChangeBuilder =
                                    new UserProfileChangeRequest.Builder();
                            if (firebaseUser.getDisplayName() == null ||
                                    !firebaseUser.getDisplayName().equals(displayName)) {
                                updateRequired = true;
                                profileChangeBuilder.setDisplayName(displayName);
                            }
                            if (firebaseUser.getPhotoUrl() == null ||
                                    !firebaseUser.getPhotoUrl().equals(photoUrl)) {
                                updateRequired = true;
                                profileChangeBuilder.setPhotoUri(photoUrl);
                            }
                            if (updateRequired) {
                                firebaseUser.updateProfile(profileChangeBuilder.build())
                                        .setResultCallback(new ResultCallback<UserProfileChangeResult>() {
                                            @Override
                                            public void onResult(@NonNull UserProfileChangeResult userProfileChangeResult) {
                                                if (userProfileChangeResult.getStatus().isSuccess()) {
                                                    mProfileUsername.setText(firebaseUser.getDisplayName());
                                                    GlideUtil.loadProfileIcon(
                                                            firebaseUser.getPhotoUrl().toString(),
                                                            mProfilePhoto);
                                                }
                                            }
                                        });
                            }
                            showSignedInUI(firebaseUser);
                        }
                    });
        } else {
            showSignedOutUI();
        }
    }

    private void launchSignInIntent() {
        Intent intent = Auth.GoogleSignInApi.getSignInIntent(mGoogleApiClient);
        startActivityForResult(intent, RC_SIGN_IN);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        // Result returned from launching the Intent from GoogleSignInApi.getSignInIntent(...);
        if (requestCode == RC_SIGN_IN) {
            GoogleSignInResult result = Auth.GoogleSignInApi.getSignInResultFromIntent(data);
            handleGoogleSignInResult(result);
        }
    }

    private void showSignedInUI(FirebaseUser firebaseUser) {
        Log.d(TAG, "Showing signed in UI");
        mSignInUi.setVisibility(View.GONE);
        mProfileUi.setVisibility(View.VISIBLE);
        mProfileUsername.setVisibility(View.VISIBLE);
        mProfilePhoto.setVisibility(View.VISIBLE);
        if (firebaseUser.getDisplayName() != null) {
            mProfileUsername.setText(firebaseUser.getDisplayName());
        }

        if (firebaseUser.getPhotoUrl() != null) {
            GlideUtil.loadProfileIcon(firebaseUser.getPhotoUrl().toString(), mProfilePhoto);
        }
        Map<String, Object> updateValues = new HashMap<>();
        updateValues.put("displayName", firebaseUser.getDisplayName());
        updateValues.put("photoUrl", firebaseUser.getPhotoUrl() != null ? firebaseUser.getPhotoUrl().toString() : null);

        FirebaseUtil.getCurrentUserRef().updateChildren(
                updateValues,
                new Firebase.CompletionListener() {
                    @Override
                    public void onComplete(com.firebase.client.FirebaseError firebaseError, Firebase firebase) {
                        if (firebaseError != null) {
                            Toast.makeText(ProfileActivity.this,
                                    "Couldn't save user data: " + firebaseError.getMessage(),
                                    Toast.LENGTH_LONG).show();
                        }
                    }
                });
    }

    private void showSignedOutUI() {
        Log.d(TAG, "Showing signed out UI");
        mSignInUi.setVisibility(View.VISIBLE);
        mProfileUi.setVisibility(View.GONE);

        mProfileUsername.setText("");
//        mProfilePhoto.set
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onStart() {
        super.onStart();
        FirebaseUser currentUser = mAuth.getCurrentUser();
        if (currentUser != null) {
            showSignedInUI(currentUser);
        } else {
            showSignedOutUI();
        }
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
        Log.w(TAG, "onConnectionFailed:" + connectionResult);
    }
}
