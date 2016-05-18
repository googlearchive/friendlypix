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
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.os.Parcelable;
import android.provider.MediaStore;
import android.support.annotation.NonNull;
import android.support.v4.app.FragmentManager;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;


public class NewPostActivity extends BaseActivity implements
        EasyPermissions.PermissionCallbacks,
        NewPostUploadTaskFragment.TaskCallbacks {
    public static final String TAG = "NewPostActivity";
    public static final String TAG_TASK_FRAGMENT = "newPostUploadTaskFragment";
    private static final int THUMBNAIL_MAX_DIMENSION = 640;
    private static final int FULL_SIZE_MAX_DIMENSION = 1280;
    private Button mSubmitButton;

    private ImageView mImageView;
    private Uri mFileUri;
    private Bitmap mResizedBitmap;
    private Bitmap mThumbnail;

    private NewPostUploadTaskFragment mTaskFragment;

    private static final int TC_PICK_IMAGE = 101;
    private static final int RC_CAMERA_PERMISSIONS = 102;

    private static final String[] cameraPerms = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE
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

        mImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showImagePicker();
            }
        });
        Bitmap selectedBitmap = mTaskFragment.getSelectedBitmap();
        Bitmap thumbnail = mTaskFragment.getThumbnail();
        if (selectedBitmap != null) {
            mImageView.setImageBitmap(selectedBitmap);
            mResizedBitmap = selectedBitmap;
        }
        if (thumbnail != null) {
            mThumbnail = thumbnail;
        }
        final EditText descriptionText = (EditText) findViewById(R.id.new_post_text);

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

                Long timestamp = System.currentTimeMillis();

                String bitmapPath = "/" + FirebaseUtil.getCurrentUserId() + "/full/" + timestamp.toString() + "/";
                String thumbnailPath = "/" + FirebaseUtil.getCurrentUserId() + "/thumb/" + timestamp.toString() + "/";
                mTaskFragment.uploadPost(mResizedBitmap, bitmapPath, mThumbnail, thumbnailPath, mFileUri.getLastPathSegment(),
                        postText);
            }
        });
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

                mTaskFragment.resizeBitmap(mFileUri, THUMBNAIL_MAX_DIMENSION);
                mTaskFragment.resizeBitmap(mFileUri, FULL_SIZE_MAX_DIMENSION);
            }
        }
    }

    @Override
    public void onDestroy() {
        // store the data in the fragment
        if (mResizedBitmap != null) {
            mTaskFragment.setSelectedBitmap(mResizedBitmap);
        }
        if (mThumbnail != null) {
            mTaskFragment.setThumbnail(mThumbnail);
        }
        super.onDestroy();
    }

    @Override
    public void onBitmapResized(Bitmap resizedBitmap, int mMaxDimension) {
        if (resizedBitmap == null) {
            Log.e(TAG, "Couldn't resize bitmap in background task.");
            Toast.makeText(getApplicationContext(), "Couldn't resize bitmap.",
                    Toast.LENGTH_SHORT).show();
            return;
        }
        if (mMaxDimension == THUMBNAIL_MAX_DIMENSION) {
            mThumbnail = resizedBitmap;
        } else if (mMaxDimension == FULL_SIZE_MAX_DIMENSION) {
            mResizedBitmap = resizedBitmap;
            mImageView.setImageBitmap(mResizedBitmap);
        }

        if (mThumbnail != null && mResizedBitmap != null) {
            mSubmitButton.setEnabled(true);
        }
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
    }
}
