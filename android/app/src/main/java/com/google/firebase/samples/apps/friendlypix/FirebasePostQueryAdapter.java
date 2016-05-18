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

import android.net.Uri;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.ValueEventListener;
import com.google.firebase.samples.apps.friendlypix.Models.Post;

import java.util.ArrayList;
import java.util.List;

public class FirebasePostQueryAdapter extends RecyclerView.Adapter<PostViewHolder> {
    private final String TAG = "PostQueryAdapter";
    private List<String> mPostPaths;
    private OnSetupViewListener mOnSetupViewListener;

    public FirebasePostQueryAdapter(List<String> paths, OnSetupViewListener onSetupViewListener) {
        if (paths == null || paths.isEmpty()) {
            mPostPaths = new ArrayList<>();
        } else {
            mPostPaths = paths;
        }
        mOnSetupViewListener = onSetupViewListener;
    }

    @Override
    public PostViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        // create a new view
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.post_item, parent, false);
        return new PostViewHolder(v);
    }

    public void setPaths(List<String> postPaths) {
        mPostPaths = postPaths;
        notifyDataSetChanged();
    }

    public void addItem(String path) {
        mPostPaths.add(path);
        notifyItemInserted(mPostPaths.size());
    }

    @Override
    public void onBindViewHolder(final PostViewHolder holder, int position) {
        DatabaseReference ref = FirebaseUtil.getPostsRef().child(mPostPaths.get(position));
        // TODO: Fix this so async event won't bind the wrong view post recycle.
        ValueEventListener postListener = new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                Post post = dataSnapshot.getValue(Post.class);
                Log.d(TAG, "post key: " + dataSnapshot.getKey());
                mOnSetupViewListener.onSetupView(holder, post, holder.getAdapterPosition(),
                        dataSnapshot.getKey());
            }

            @Override
            public void onCancelled(DatabaseError firebaseError) {
                Log.e(TAG, "Error occurred: " + firebaseError.getMessage());
            }
        };
        ref.addValueEventListener(postListener);
        holder.mPostRef = ref;
        holder.mPostListener = postListener;
    }

    @Override
    public void onViewRecycled(PostViewHolder holder) {
        super.onViewRecycled(holder);
        holder.mPostRef.removeEventListener(holder.mPostListener);
    }

    @Override
    public int getItemCount() {
        return mPostPaths.size();
    }

    public interface OnSetupViewListener {
        void onSetupView(PostViewHolder holder, Post post, int position, String postKey);
    }
}
