package com.google.firebase.samples.apps.friendlypix;

import android.Manifest;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.location.Location;
import android.net.Uri;
import android.os.Bundle;
import android.os.Parcelable;
import android.provider.MediaStore;
import android.support.annotation.NonNull;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.tasks.OnFailureListener;
import com.google.android.gms.common.tasks.OnSuccessListener;
import com.google.android.gms.location.LocationServices;
import com.google.firebase.FirebaseError;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ServerValue;
import com.google.firebase.samples.apps.friendlypix.Models.Post;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageException;
import com.google.firebase.storage.StorageMetadata;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import pub.devrel.easypermissions.AfterPermissionGranted;
import pub.devrel.easypermissions.EasyPermissions;


public class NewPostActivity extends AppCompatActivity implements
        EasyPermissions.PermissionCallbacks,
        GoogleApiClient.ConnectionCallbacks,
        GoogleApiClient.OnConnectionFailedListener {
    public static final String TAG = "NewPostActivity";
    private ProgressDialog mProgressDialog;

    private TextView mLocationView;
    private GoogleApiClient mGoogleApiClient;
    private StorageReference mStorageRef;
    private Location mUserLocation;
    private Uri mFileUri;

    private static final int TC_PICK_IMAGE = 101;
    private static final int RC_CAMERA_PERMISSIONS = 102;
    private static final int RC_LOCATION_PERMISSIONS = 103;

    private static final String KEY_FILE_URI = "key_file_uri";
    private static final String[] cameraPerms = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE,
    };
    private static final String[] locationPerms = new String[]{
            Manifest.permission.ACCESS_COARSE_LOCATION
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_new_post);
        final ImageView postPhotoView = (ImageView) findViewById(R.id.new_post_picture);
        postPhotoView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showImagePicker();
            }
        });
        final EditText descriptionText = (EditText) findViewById(R.id.new_post_text);

        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .enableAutoManage(this, this)
                .addApi(LocationServices.API)
                .build();

        mLocationView = (TextView) findViewById(R.id.new_post_location);
//        mLocationView.setText(R.string.new_post_location_placeholder);

        mStorageRef = FirebaseStorage.getInstance()
                .getReference(getString(R.string.google_storage_bucket));

        // Restore instance state
        if (savedInstanceState != null) {
            mFileUri = savedInstanceState.getParcelable(KEY_FILE_URI);
            if (mFileUri != null) {
                GlideUtil.loadImage(mFileUri.toString(), postPhotoView);
            }
        }

        Button submitButton = (Button) findViewById(R.id.new_post_submit);
        submitButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(final View v) {
                v.setEnabled(false);
                showProgressDialog();
                if (mFileUri == null) {
                    return;
                }

                final StorageReference photoRef = mStorageRef.child("photos")
                        .child(mFileUri.getLastPathSegment());

                photoRef.putFile(mFileUri)
                        .addOnSuccessListener(new OnSuccessListener<UploadTask.TaskSnapshot>() {
                    @Override
                    public void onSuccess(UploadTask.TaskSnapshot taskSnapshot) {
                        Uri url = taskSnapshot.getMetadata().getDownloadUrl();

                        final DatabaseReference ref = FirebaseUtil.getBaseRef();
                        DatabaseReference postsRef = FirebaseUtil.getPostsRef();
                        final String newPostKey = postsRef.push().getKey();

                        String userId = FirebaseUtil.getCurrentUserId();
                        Post newPost = new Post(userId, url.toString(),
                                descriptionText.getText().toString(), ServerValue.TIMESTAMP);

                        Map<String, Object> updatedUserData = new HashMap<>();
                        updatedUserData.put(FirebaseUtil.getUsersPath() + userId + "/posts/" + newPostKey, true);
                        updatedUserData.put(FirebaseUtil.getPostsPath() + newPostKey,
                                new ObjectMapper().convertValue(newPost, Map.class));

                        ref.updateChildren(updatedUserData, new DatabaseReference.CompletionListener() {
                            @Override
                            public void onComplete(DatabaseError firebaseError, DatabaseReference databaseReference) {
                                if (firebaseError == null) {
                                    Toast.makeText(NewPostActivity.this, "Post created!", Toast.LENGTH_SHORT).show();
                                    if (mUserLocation != null) {
                                      //  TODO: Temporarily removing geofire until I fork it to include Firebase class name changes.
//                                        GeoFire geoFire = new GeoFire(FirebaseUtil.getBaseRef());
//                                        geoFire.setLocation(newPostKey,
//                                                new GeoLocation(mUserLocation.getLatitude(), mUserLocation.getLongitude()));
                                    } else {
                                        Log.d(TAG, "Not tagging post because location data was not provided.");
                                    }
                                    finish();
                                } else {
                                    Log.e(TAG, "Unable to create new post: " + firebaseError.getMessage());
                                    Toast.makeText(NewPostActivity.this, "Unable to post.", Toast.LENGTH_SHORT).show();
                                    v.setEnabled(true);
                                }
                                dismissProgressDialog();
                            }
                        });
                    }
                }).addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Throwable throwable) {
                        Toast.makeText(NewPostActivity.this, "Failed to upload post.", Toast.LENGTH_SHORT).show();
                        dismissProgressDialog();
                        v.setEnabled(true);
                    }
                });
            }
        });
        // TODO: Refactor these insanely nested callbacks.
    }

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
        File file = new File(getExternalCacheDir(), UUID.randomUUID().toString() + ".jpg");
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
                Bitmap bitmap = null;
                if (isCamera) {
                    BitmapFactory.Options options = new BitmapFactory.Options();
                    options.inSampleSize = 8;
                    bitmap = BitmapFactory.decodeFile(mFileUri.getPath(), options);
                } else {
                    mFileUri = data.getData();
                    // TODO: Implement bitmap resizing for fetch performance.
                    try {
                        bitmap = MediaStore.Images.Media.getBitmap(this.getContentResolver(), mFileUri);
                    } catch (IOException e) {
                        Log.e(TAG, "Counldn't fetch bitmap." + e.getMessage());
                    }
                }
                ImageView imageView = (ImageView) findViewById(R.id.new_post_picture);
                Glide.with(imageView.getContext())
                .load(bitmap)
                .crossFade()
                .centerCrop()
                .into(imageView);
            }
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

    @Override
    public void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        out.putParcelable(KEY_FILE_URI, mFileUri);
    }
}
