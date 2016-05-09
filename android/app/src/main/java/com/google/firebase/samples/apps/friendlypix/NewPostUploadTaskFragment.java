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

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.Fragment;
import android.util.Log;

import com.fasterxml.jackson.databind.ObjectMapper;
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
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class NewPostUploadTaskFragment extends Fragment {
    private static final String TAG = "NewPostTaskFragment";

    public interface TaskCallbacks {
        void onBitmapResized(Bitmap resizedBitmap);
        void onPostUploaded(String error);
    }
    private Context mApplicationContext;
    private TaskCallbacks mCallbacks;
    private Bitmap selectedBitmap;

    public NewPostUploadTaskFragment() {
        // Required empty public constructor
    }

    public static NewPostUploadTaskFragment newInstance() {
        return new NewPostUploadTaskFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Retain this fragment across config changes.
        setRetainInstance(true);
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof TaskCallbacks) {
            mCallbacks = (TaskCallbacks) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement TaskCallbacks");
        }
        mApplicationContext = context.getApplicationContext();
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mCallbacks = null;
    }

    public void setSelectedBitmap(Bitmap bitmap) {
        this.selectedBitmap = bitmap;
    }

    public Bitmap getSelectedBitmap() {
        return selectedBitmap;
    }

    public void resizeBitmap(Uri uri) {
        LoadResizedBitmapTask task = new LoadResizedBitmapTask();
        task.execute(uri);
    }

    public void uploadPost(Bitmap bitmap, String fileName, String postText) {
        UploadPostTask uploadTask = new UploadPostTask(bitmap, fileName, postText);
        uploadTask.execute();
    }

    class UploadPostTask extends AsyncTask<Void, Void, Void> {
        private WeakReference<Bitmap> bitmapReference;
        private String postText;
        private String fileName;

        public UploadPostTask(Bitmap bitmap, String inFileName, String inPostText) {
            bitmapReference = new WeakReference<Bitmap>(bitmap);
            postText = inPostText;
            fileName = inFileName;
        }

        @Override
        protected void onPreExecute() {

        }

        @Override
        protected Void doInBackground(Void... params) {
            Bitmap bitmap = bitmapReference.get();
            if (bitmap == null) {
                return null;
            }
            StorageReference storageRef = FirebaseStorage.getInstance()
                    .getReference(getString(R.string.google_storage_bucket));
            final StorageReference photoRef = storageRef.child("photos")
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
                    File tmpImageFile = new File(mApplicationContext.getCacheDir(), "tmpimg.jpg");
                    try {
                        FileOutputStream fileOutputStream = new FileOutputStream(tmpImageFile);
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 70, fileOutputStream);
                        fileOutputStream.flush();
                        fileOutputStream.close();
                        Uri tmpImgUri = Uri.fromFile(tmpImageFile);
                        uploadTask = photoRef.putFile(tmpImgUri);
                    } catch (FileNotFoundException e ) {
                        FirebaseCrash.logcat(Log.ERROR, TAG, "Can't access temp image file");
                        FirebaseCrash.report(e);
                    } catch (IOException e) {
                        FirebaseCrash.logcat(Log.ERROR, TAG, "Can't create temp image file");
                        FirebaseCrash.report(e);
                    }
            }
            if (uploadTask == null) {
                FirebaseCrash.log(mApplicationContext.getString(R.string.error_upload_task_create));
                mCallbacks.onPostUploaded(mApplicationContext.getString(
                        R.string.error_upload_task_create));
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
                                mCallbacks.onPostUploaded(null);
                            } else {
                                Log.e(TAG, "Unable to create new post: " + firebaseError.getMessage());
                                FirebaseCrash.report(firebaseError.toException());
                                mCallbacks.onPostUploaded(mApplicationContext.getString(
                                        R.string.error_upload_task_create));
                            }
                        }
                    });
                }
            }).addOnFailureListener(new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Throwable throwable) {
                    FirebaseCrash.logcat(Log.ERROR, TAG, "Failed to upload post to database.");
                    FirebaseCrash.report(throwable);
                    mCallbacks.onPostUploaded(mApplicationContext.getString(
                            R.string.error_upload_task_create));
                }
            });
            // TODO: Refactor these insanely nested callbacks.
            return null;
        }
    }

    class LoadResizedBitmapTask extends AsyncTask<Uri, Void, Bitmap> {
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
                    FirebaseCrash.report(e);
                } catch (IOException e) {
                    Log.e(TAG, "Error occurred during resize: " + e.getMessage());
                    FirebaseCrash.report(e);
                }
                return bitmap;
            }
            return null;
        }

        @Override
        protected void onPostExecute(Bitmap bitmap) {
            mCallbacks.onBitmapResized(bitmap);
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
        InputStream stream = new BufferedInputStream(
                mApplicationContext.getContentResolver().openInputStream(fileUri));
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
}
