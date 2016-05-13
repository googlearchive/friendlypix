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

import android.Manifest;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.location.Location;
import android.net.Uri;
import android.os.Bundle;
import android.os.Parcelable;
import android.provider.MediaStore;
import android.support.annotation.NonNull;
import android.support.v4.app.FragmentManager;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.LocationServices;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;


public class NewPostActivity extends BaseActivity implements
        EasyPermissions.PermissionCallbacks,
        GoogleApiClient.ConnectionCallbacks,
        GoogleApiClient.OnConnectionFailedListener,
        NewPostUploadTaskFragment.TaskCallbacks {
    public static final String TAG = "NewPostActivity";
    public static final String TAG_TASK_FRAGMENT = "newPostUploadTaskFragment";
    private Button mSubmitButton;

    private ImageView mImageView;
    private TextView mLocationView;
    private GoogleApiClient mGoogleApiClient;
    private Location mUserLocation;
    private Uri mFileUri;
    private Bitmap mResizedBitmap;

    private NewPostUploadTaskFragment mTaskFragment;

    private static final int TC_PICK_IMAGE = 101;
    private static final int RC_CAMERA_PERMISSIONS = 102;
    private static final int RC_LOCATION_PERMISSIONS = 103;

    private static final String[] cameraPerms = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE
    };
    private static final String[] locationPerms = new String[]{
            Manifest.permission.ACCESS_COARSE_LOCATION
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_new_post);

        // find the retained fragment on activity restarts
        FragmentManager fm = getSupportFragmentManager();
        mTaskFragment = (NewPostUploadTaskFragment) fm.findFragmentByTag(TAG_TASK_FRAGMENT);

        // create the fragment and data the first time
        if (mTaskFragment == null) {
            // add the fragment
            mTaskFragment = new NewPostUploadTaskFragment();
            fm.beginTransaction().add(mTaskFragment, TAG_TASK_FRAGMENT).commit();
        }

        mImageView = (ImageView) findViewById(R.id.new_post_picture);
        mLocationView = (TextView) findViewById(R.id.new_post_location);
//        mLocationView.setText(R.string.new_post_location_placeholder);

        mImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showImagePicker();
            }
        });
        Bitmap selectedBitmap = mTaskFragment.getSelectedBitmap();
        if (selectedBitmap != null) {
            mImageView.setImageBitmap(selectedBitmap);
            mResizedBitmap = selectedBitmap;
        }
        final EditText descriptionText = (EditText) findViewById(R.id.new_post_text);

        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .enableAutoManage(this, this)
                .addApi(LocationServices.API)
                .build();

        mLocationView = (TextView) findViewById(R.id.new_post_location);
//        mLocationView.setText(R.string.new_post_location_placeholder);

        mSubmitButton = (Button) findViewById(R.id.new_post_submit);
        mSubmitButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View v) {
                if (mResizedBitmap == null) {
                    Toast.makeText(NewPostActivity.this, "Select an image first.",
                            Toast.LENGTH_SHORT).show();
                    return;
                }
                String postText = descriptionText.getText().toString();
                if (TextUtils.isEmpty(postText)) {
                    descriptionText.setError(getString(R.string.error_required_field));
                    return;
                }
                showProgressDialog(getString(R.string.post_upload_progress_message));
                mSubmitButton.setEnabled(false);

                mTaskFragment.uploadPost(mResizedBitmap, mFileUri.getLastPathSegment(), postText);
            }
        });
    }

    @AfterPermissionGranted(RC_LOCATION_PERMISSIONS)
    private void setCurrentUserLocation() {
        // Check for location permissions
        if (!EasyPermissions.hasPermissions(this, locationPerms)) {
            EasyPermissions.requestPermissions(this,
                    "This will allow your post to be geotagged.",
                    RC_LOCATION_PERMISSIONS, locationPerms);
            return;
        }
        Log.d(TAG, "google api client is connected? " + mGoogleApiClient.isConnected());
        mUserLocation = LocationServices.FusedLocationApi.getLastLocation(mGoogleApiClient);

        mLocationView.setText(String.format("(Lat %f) (Lon %f)",
                mUserLocation.getLatitude(), mUserLocation.getLongitude()));
    }

    @Override
    public void onPostUploaded(final String error) {
        NewPostActivity.this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mSubmitButton.setEnabled(true);
                dismissProgressDialog();
                if (error == null) {
                    Toast.makeText(NewPostActivity.this, "Post created!", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    Toast.makeText(NewPostActivity.this, error, Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    @AfterPermissionGranted(RC_CAMERA_PERMISSIONS)
    private void showImagePicker() {
        // Check for camera permissions
        if (!EasyPermissions.hasPermissions(this, cameraPerms)) {
            EasyPermissions.requestPermissions(this,
                    "This sample will upload a picture from your Camera",
                    RC_CAMERA_PERMISSIONS, cameraPerms);
            return;
        }

        // Choose file storage location
        File file = new File(getExternalCacheDir(), UUID.randomUUID().toString());
        mFileUri = Uri.fromFile(file);

        // Camera
        final List<Intent> cameraIntents = new ArrayList<Intent>();
        final Intent captureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        final PackageManager packageManager = getPackageManager();
        final List<ResolveInfo> listCam = packageManager.queryIntentActivities(captureIntent, 0);
        for (ResolveInfo res : listCam){
            final String packageName = res.activityInfo.packageName;
            final Intent intent = new Intent(captureIntent);
            intent.setComponent(new ComponentName(packageName, res.activityInfo.name));
            intent.setPackage(packageName);
            intent.putExtra(MediaStore.EXTRA_OUTPUT, mFileUri);
            cameraIntents.add(intent);
        }

        // Image Picker
        Intent pickerIntent = new Intent(Intent.ACTION_PICK,
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI);

        Intent chooserIntent = Intent.createChooser(pickerIntent,
                getString(R.string.picture_chooser_title));
        chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, cameraIntents.toArray(new
                Parcelable[cameraIntents.size()]));
        startActivityForResult(chooserIntent, TC_PICK_IMAGE);
    }

    @Override
    public void onConnected(Bundle bundle) {
        setCurrentUserLocation();
    }

    @Override
    public void onConnectionSuspended(int i) {
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == TC_PICK_IMAGE) {
            if (resultCode == Activity.RESULT_OK) {
                final boolean isCamera;
                if (data.getData() == null) {
                    isCamera = true;
                } else {
                    isCamera = MediaStore.ACTION_IMAGE_CAPTURE.equals(data.getAction());
                }
                if (!isCamera) {
                    mFileUri = data.getData();
                }
                Log.d(TAG, "Received file uri: " + mFileUri.getPath());

                mTaskFragment.resizeBitmap(mFileUri);
            }
        }
    }

    @Override
    public void onDestroy() {
        // store the data in the fragment
        if (mResizedBitmap != null) {
            mTaskFragment.setSelectedBitmap(mResizedBitmap);
        }
        super.onDestroy();
    }

    @Override
    public void onBitmapResized(Bitmap resizedBitmap) {
        if (resizedBitmap == null) {
            Log.e(TAG, "Couldn't resize bitmap in background task.");
            Toast.makeText(getApplicationContext(), "Couldn't resize bitmap.",
                    Toast.LENGTH_SHORT).show();
            return;
        }
        mResizedBitmap = resizedBitmap;

        Log.d(TAG, "resized bitmap: " + mResizedBitmap.toString());

        mImageView.setImageBitmap(mResizedBitmap);
        Log.d(TAG, "Resized bitmap bytes: " + mResizedBitmap.getByteCount());
        mSubmitButton.setEnabled(true);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, List<String> perms) {}

    @Override
    public void onPermissionsDenied(int requestCode, List<String> perms) {
        mLocationView.setText("Need location permissions to tag this post.");
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
        Log.w(TAG, "onConnectionFailed:" + connectionResult);
        mLocationView.setText("Failed to get location.");
    }
}
