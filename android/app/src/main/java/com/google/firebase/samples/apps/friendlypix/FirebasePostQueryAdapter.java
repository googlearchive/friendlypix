package com.google.firebase.samples.apps.friendlypix;

import android.net.Uri;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.firebase.client.DataSnapshot;
import com.firebase.client.Firebase;
import com.firebase.client.FirebaseError;
import com.firebase.client.ValueEventListener;
import com.google.firebase.samples.apps.friendlypix.Models.Post;

import java.util.ArrayList;
import java.util.List;

public class FirebasePostQueryAdapter extends RecyclerView.Adapter<PostViewHolder> {
    private final String TAG = "PostQueryAdapter";
    private final String mPrefix = FirebaseUtil.getFirebaseUrl().concat("/posts");
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
        Uri prefixUri = Uri.parse(mPrefix);
        String refString = Uri.withAppendedPath(prefixUri, mPostPaths.get(position)).toString();
        Log.d(TAG, "url: " + refString);
        Firebase ref = new Firebase(refString);
        // TODO: Fix this so async event won't bind the wrong view post recycle.
        ref.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                Post post = dataSnapshot.getValue(Post.class);
                mOnSetupViewListener.onSetupView(holder, post, holder.getAdapterPosition(),
                        dataSnapshot.getKey());
            }

            @Override
            public void onCancelled(FirebaseError firebaseError) {
                Log.e(TAG, "Error occurred: " + firebaseError.getMessage());
            }
        });
    }

    @Override
    public int getItemCount() {
        return mPostPaths.size();
    }

    public interface OnSetupViewListener {
        void onSetupView(PostViewHolder holder, Post post, int position, String postKey);
    }
}
