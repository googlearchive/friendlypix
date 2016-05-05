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
import android.graphics.BitmapFactory;
import android.location.Location;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Parcelable;
import android.provider.MediaStore;
import android.support.annotation.NonNull;
import android.support.v4.app.Fragment;
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

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.crash.FirebaseCrash;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ServerValue;
import com.google.firebase.samples.apps.friendlypix.Models.Post;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;


public class NewPostActivity extends AppCompatActivity implements
        EasyPermissions.PermissionCallbacks,
        GoogleApiClient.ConnectionCallbacks,
        GoogleApiClient.OnConnectionFailedListener {
    public static final String TAG = "NewPostActivity";
    private ProgressDialog mProgressDialog;
    private Button mSubmitButton;

    private ImageView mImageView;
    private TextView mLocationView;
    private GoogleApiClient mGoogleApiClient;
    private StorageReference mStorageRef;
    private Location mUserLocation;
    private Uri mFileUri;
    private Bitmap mResizedBitmap;

    private RetainedFragment retainedFragment;

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
        retainedFragment = (RetainedFragment) fm.findFragmentByTag("savedBitmapFragment");

        // create the fragment and data the first time
        if (retainedFragment == null) {
            // add the fragment
            retainedFragment = new RetainedFragment();
            fm.beginTransaction().add(retainedFragment, "savedBitmapFragment").commit();
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
        Bitmap selectedBitmap = retainedFragment.getSelectedBitmap();
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

        mStorageRef = FirebaseStorage.getInstance()
                .getReference(getString(R.string.google_storage_bucket));

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
                UploadImageTask uploadTask = new UploadImageTask(mResizedBitmap, mFileUri.getLastPathSegment(),
                        postText);
                uploadTask.execute();
            }
        });
    }


    class UploadImageTask extends AsyncTask<Void, Void, Void> {
        private WeakReference<Bitmap> bitmapReference;
        private String postText;
        private String fileName;

        public UploadImageTask(Bitmap bitmap, String inFileName, String inPostText) {
            bitmapReference = new WeakReference<Bitmap>(bitmap);
            postText = inPostText;
            fileName = inFileName;
        }

        @Override
        protected void onPreExecute() {
            showProgressDialog();
            mSubmitButton.setEnabled(false);
        }

        @Override
        protected Void doInBackground(Void... params) {
                Bitmap bitmap = bitmapReference.get();
                if (bitmap == null) {
                    return null;
                }
                final StorageReference photoRef = mStorageRef.child("photos")
                    .child(fileName + ".jpg");
                // TODO: Temporary code to randomly select one of three SDK upload methods for
                // testing. Choose one before release.
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream);
                byte[] bytes = stream.toByteArray();
                UploadTask uploadTask = null;
                int randomChoice = new Random().nextInt(3);
                switch(randomChoice) {
                    case 0:
                        uploadTask = photoRef.putBytes(bytes);
                        break;
                    case 1:
                        uploadTask = photoRef.putStream(new ByteArrayInputStream(bytes));
                        break;
                    case 2:
                        File tmpImageFile = new File(getCacheDir(), "tmpimg.jpg");
                        try {
                            FileOutputStream fileOutputStream = new FileOutputStream(tmpImageFile);
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 70, fileOutputStream);
                            fileOutputStream.flush();
                            fileOutputStream.close();
                            Uri tmpImgUri = Uri.fromFile(tmpImageFile);
                            uploadTask = photoRef.putFile(tmpImgUri);
                        }
                        catch (FileNotFoundException e ) {
                            Log.e(TAG, "Can't access temp image file");
                            FirebaseCrash.report(e);
                            exitFail("Unable to post.");
                        } catch (IOException e) {
                            Log.e(TAG, "Can't create temp image file");
                            FirebaseCrash.report(e);
                            exitFail("Unable to post.");
                        }
                }
                if (uploadTask == null) {
                    FirebaseCrash.log("Couldn't create upload task.");
                    return null;
                }
                uploadTask.addOnSuccessListener(new OnSuccessListener<UploadTask.TaskSnapshot>() {
                    @Override
                    public void onSuccess(UploadTask.TaskSnapshot taskSnapshot) {
                        Uri url = taskSnapshot.getDownloadUrl();

                        final DatabaseReference ref = FirebaseUtil.getBaseRef();
                        DatabaseReference postsRef = FirebaseUtil.getPostsRef();
                        final String newPostKey = postsRef.push().getKey();

                        String userId = FirebaseUtil.getCurrentUserId();
                        Post newPost = new Post(userId, url.toString(), postText, ServerValue.TIMESTAMP);

                        Map<String, Object> updatedUserData = new HashMap<>();
                        updatedUserData.put(FirebaseUtil.getUsersPath() + userId + "/posts/" + newPostKey, true);
                        updatedUserData.put(FirebaseUtil.getPostsPath() + newPostKey,
                                new ObjectMapper().convertValue(newPost, Map.class));
                        ref.updateChildren(updatedUserData, new DatabaseReference.CompletionListener() {
                            @Override
                            public void onComplete(DatabaseError firebaseError, DatabaseReference databaseReference) {
                                if (firebaseError == null) {
                                    if (mUserLocation != null) {
                                      //  TODO: Temporarily removing geofire until I fork it to include Firebase class name changes.
//                                        GeoFire geoFire = new GeoFire(FirebaseUtil.getBaseRef());
//                                        geoFire.setLocation(newPostKey,
//                                                new GeoLocation(mUserLocation.getLatitude(), mUserLocation.getLongitude()));
                                    } else {
                                        Log.d(TAG, "Not tagging post because location data was not provided.");
                                    }
                                    exitSuccess();
                                } else {
                                    Log.e(TAG, "Unable to create new post: " + firebaseError.getMessage());
                                    FirebaseCrash.report(firebaseError.toException());
                                    exitFail("Unable to post.");
                                }
                            }
                        });
                    }
                }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Throwable throwable) {
                        FirebaseCrash.report(throwable);
                        exitFail("Failed to upload post.");
                    }
                });
            // TODO: Refactor these insanely nested callbacks.
            return null;
        }

        private void exitSuccess() {
            NewPostActivity.this.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(NewPostActivity.this, "Post created!", Toast.LENGTH_SHORT).show();
                    mSubmitButton.setEnabled(true);
                    dismissProgressDialog();
                    finish();
                }
            });
        }

        private void exitFail(final String error) {
            NewPostActivity.this.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(NewPostActivity.this, error, Toast.LENGTH_SHORT).show();
                    mSubmitButton.setEnabled(true);
                    dismissProgressDialog();
                }
            });
        }
    }

    // TODO: Centralize showProgressDialog and hideProgressDialog as they are shared with
    // ProfileActivity.
    public void showProgressDialog() {
        if (mProgressDialog == null) {
            mProgressDialog = new ProgressDialog(this);
            mProgressDialog.setMessage("Uploading...");
            mProgressDialog.setIndeterminate(true);
            mProgressDialog.setCancelable(false);
            mProgressDialog.setCanceledOnTouchOutside(false);
        }
        if (!mProgressDialog.isShowing()) {
            mProgressDialog.show();
        }
    }

    public void dismissProgressDialog() {
        if (mProgressDialog != null && mProgressDialog.isShowing()) {
            Context context = ((ContextWrapper) mProgressDialog.getContext()).getBaseContext();

            // Dismiss only if launching activity hasn't been finished or destroyed.
            if(context instanceof Activity &&
                    ((Activity)context).isFinishing() || ((Activity)context).isDestroyed()) {
                    return;
            } else
                mProgressDialog.dismiss();
        }
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

                LoadResizedBitmapTask task = new LoadResizedBitmapTask(mImageView);
                task.execute(mFileUri);
            }
        }
    }

    public static int calculateInSampleSize(
            BitmapFactory.Options options, int reqWidth, int reqHeight) {
        // Raw height and width of image
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {

            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width.
            while ((halfHeight / inSampleSize) > reqHeight
                    && (halfWidth / inSampleSize) > reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    public Bitmap decodeSampledBitmapFromUri(Uri fileUri, int reqWidth, int reqHeight)
            throws IOException {
            InputStream stream = new BufferedInputStream(this.getContentResolver().openInputStream(fileUri));
            stream.mark(stream.available());
            BitmapFactory.Options options = new BitmapFactory.Options();
            // First decode with inJustDecodeBounds=true to check dimensions
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeStream(stream, null, options);
            stream.reset();
            options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight);
            options.inJustDecodeBounds = false;
            BitmapFactory.decodeStream(stream, null, options);
            // Decode bitmap with inSampleSize set
            stream.reset();
            return BitmapFactory.decodeStream(stream, null, options);
    }

    class LoadResizedBitmapTask extends AsyncTask<Uri, Void, Bitmap> {
        private final WeakReference<ImageView> imageViewReference;

        public LoadResizedBitmapTask(ImageView imageView) {
            imageViewReference = new WeakReference<ImageView>(imageView);
        }

        // Decode image in background.
        @Override
        protected Bitmap doInBackground(Uri... params) {
            Uri uri = params[0];
            if (uri != null) {
                // TODO: Currently making these very small to investigate modulefood bug.
                // Implement thumbnail + fullsize later.
                Bitmap bitmap = null;
                try {
                    bitmap = decodeSampledBitmapFromUri(uri, 640, 480);
                } catch (FileNotFoundException e) {
                    Log.e(TAG, "Can't find file to resize: " + e.getMessage());
                    e.printStackTrace();
                } catch (IOException e) {
                    Log.e(TAG, "Error occurred during resize: " + e.getMessage());
                    e.printStackTrace();
                }
                return bitmap;
            }
            return null;
        }

        @Override
        protected void onPostExecute(Bitmap bitmap) {
            if (bitmap == null) {
                Log.e(TAG, "Couldn't resize bitmap in background task.");
                Toast.makeText(getApplicationContext(), "Couldn't resize bitmap.",
                        Toast.LENGTH_SHORT).show();
                return;
            }
            mResizedBitmap = bitmap;

            Log.d(TAG, "resized bitmap: " + mResizedBitmap.toString());

            final ImageView imageView = imageViewReference.get();
            if (imageView != null) {
                imageView.setImageBitmap(mResizedBitmap);
            }
            Log.d(TAG, "Resized bitmap bytes: " + mResizedBitmap.getByteCount());
            mSubmitButton.setEnabled(true);
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        // store the data in the fragment
        if (mResizedBitmap != null) {
            retainedFragment.setSelectedBitmap(mResizedBitmap);
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
        mLocationView.setText("Need location permissions to tag this post.");
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
        Log.w(TAG, "onConnectionFailed:" + connectionResult);
        mLocationView.setText("Failed to get location.");
    }

    // TODO: Move this into own class, and use this to launch both async tasks.
    /**
     * Used to keep selected picture through orientation changes.
     */
    public static class RetainedFragment extends Fragment {

        // data object we want to retain
        private Bitmap selectedBitmap;

        // this method is only called once for this fragment
        @Override
        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            // retain this fragment
            setRetainInstance(true);
        }

        public void setSelectedBitmap(Bitmap bitmap) {
            this.selectedBitmap = bitmap;
        }

        public Bitmap getSelectedBitmap() {
            return selectedBitmap;
        }
    }
}
