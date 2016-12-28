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
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.text.format.DateUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.firebase.ui.database.FirebaseRecyclerAdapter;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.database.ChildEventListener;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.Query;
import com.google.firebase.database.ValueEventListener;
import com.google.firebase.samples.apps.friendlypix.Models.Author;
import com.google.firebase.samples.apps.friendlypix.Models.Post;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Shows a list of posts.
 */
public class PostsFragment extends Fragment {

    public static final String TAG = "PostsFragment";
    private static final String KEY_LAYOUT_POSITION = "layoutPosition";
    private static final String KEY_TYPE = "type";
    public static final int TYPE_HOME = 1001;
    public static final int TYPE_FEED = 1002;
    private int mRecyclerViewPosition = 0;
    private OnPostSelectedListener mListener;


    private RecyclerView mRecyclerView;
    private RecyclerView.Adapter<PostViewHolder> mAdapter;

    public PostsFragment() {
        // Required empty public constructor
    }

    public static PostsFragment newInstance(int type) {
        PostsFragment fragment = new PostsFragment();
        Bundle args = new Bundle();
        args.putInt(KEY_TYPE, type);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_posts, container, false);
        rootView.setTag(TAG);

        mRecyclerView = (RecyclerView) rootView.findViewById(R.id.my_recycler_view);
        return rootView;
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(getActivity());
        linearLayoutManager.setReverseLayout(true);
        linearLayoutManager.setStackFromEnd(true);
        mRecyclerView.setLayoutManager(linearLayoutManager);

        if (savedInstanceState != null) {
            // Restore saved layout manager type.
            mRecyclerViewPosition = (int) savedInstanceState
                    .getSerializable(KEY_LAYOUT_POSITION);
            mRecyclerView.scrollToPosition(mRecyclerViewPosition);
            // TODO: RecyclerView only restores position properly for some tabs.
        }

        switch (getArguments().getInt(KEY_TYPE)) {
            case TYPE_FEED:
                Log.d(TAG, "Restoring recycler view position (all): " + mRecyclerViewPosition);
                Query allPostsQuery = FirebaseUtil.getPostsRef();
                mAdapter = getFirebaseRecyclerAdapter(allPostsQuery);
                mAdapter.registerAdapterDataObserver(new RecyclerView.AdapterDataObserver() {
                    @Override
                    public void onItemRangeInserted(int positionStart, int itemCount) {
                        super.onItemRangeInserted(positionStart, itemCount);
                        // TODO: Refresh feed view.
                    }
                });
                mRecyclerView.setAdapter(mAdapter);
                break;
            case TYPE_HOME:
                Log.d(TAG, "Restoring recycler view position (following): " + mRecyclerViewPosition);

                FirebaseUtil.getCurrentUserRef().child("following").addChildEventListener(new ChildEventListener() {
                    @Override
                    public void onChildAdded(final DataSnapshot followedUserSnapshot, String s) {
                        String followedUserId = followedUserSnapshot.getKey();
                        String lastKey = "";
                        if (followedUserSnapshot.getValue() instanceof String) {
                            lastKey = followedUserSnapshot.getValue().toString();
                        }
                        Log.d(TAG, "followed user id: " + followedUserId);
                        Log.d(TAG, "last key: " + lastKey);
                        FirebaseUtil.getPeopleRef().child(followedUserId).child("posts")
                                .orderByKey().startAt(lastKey).addChildEventListener(new ChildEventListener() {
                            @Override
                            public void onChildAdded(final DataSnapshot postSnapshot, String s) {
                                HashMap<String, Object> addedPost = new HashMap<String, Object>();
                                addedPost.put(postSnapshot.getKey(), true);
                                FirebaseUtil.getFeedRef().child(FirebaseUtil.getCurrentUserId())
                                        .updateChildren(addedPost).addOnSuccessListener(new OnSuccessListener<Void>() {
                                    @Override
                                    public void onSuccess(Void aVoid) {
                                        FirebaseUtil.getCurrentUserRef().child("following")
                                                .child(followedUserSnapshot.getKey())
                                                .setValue(postSnapshot.getKey());
                                    }
                                });
                            }

                            @Override
                            public void onChildChanged(DataSnapshot dataSnapshot, String s) {

                            }

                            @Override
                            public void onChildRemoved(DataSnapshot dataSnapshot) {

                            }

                            @Override
                            public void onChildMoved(DataSnapshot dataSnapshot, String s) {

                            }

                            @Override
                            public void onCancelled(DatabaseError databaseError) {

                            }
                        });
                    }

                    @Override
                    public void onChildChanged(DataSnapshot dataSnapshot, String s) {

                    }

                    @Override
                    public void onChildRemoved(DataSnapshot dataSnapshot) {

                    }

                    @Override
                    public void onChildMoved(DataSnapshot dataSnapshot, String s) {

                    }

                    @Override
                    public void onCancelled(DatabaseError databaseError) {

                    }
                });

                FirebaseUtil.getFeedRef().child(FirebaseUtil.getCurrentUserId())
                        .addListenerForSingleValueEvent(new ValueEventListener() {
                            @Override
                            public void onDataChange(DataSnapshot dataSnapshot) {
                                final List<String> postPaths = new ArrayList<>();
                                for (DataSnapshot snapshot : dataSnapshot.getChildren()) {
                                    Log.d(TAG, "adding post key: " + snapshot.getKey());
                                    postPaths.add(snapshot.getKey());
                                }
                                mAdapter = new FirebasePostQueryAdapter(postPaths,
                                        new FirebasePostQueryAdapter.OnSetupViewListener() {
                                    @Override
                                    public void onSetupView(PostViewHolder holder, Post post, int position, String postKey) {
                                        setupPost(holder, post, position, postKey);
                                    }
                                });
                                mRecyclerView.setAdapter(mAdapter);
                            }
                            @Override
                            public void onCancelled(DatabaseError firebaseError) {

                            }
                        });
                break;
            default:
                throw new RuntimeException("Illegal post fragment type specified.");
        }

    }

    private FirebaseRecyclerAdapter<Post, PostViewHolder> getFirebaseRecyclerAdapter(Query query) {
        return new FirebaseRecyclerAdapter<Post, PostViewHolder>(
                Post.class, R.layout.post_item, PostViewHolder.class, query) {
            @Override
            public void populateViewHolder(final PostViewHolder postViewHolder,
                                           final Post post, final int position) {
                setupPost(postViewHolder, post, position, null);
            }

            @Override
            public void onViewRecycled(PostViewHolder holder) {
                super.onViewRecycled(holder);
//                FirebaseUtil.getLikesRef().child(holder.mPostKey).removeEventListener(holder.mLikeListener);
            }
        };
    }

    private void setupPost(final PostViewHolder postViewHolder, final Post post, final int position, final String inPostKey) {
        postViewHolder.setPhoto(post.getThumb_url());
        postViewHolder.setText(post.getText());
        postViewHolder.setTimestamp(DateUtils.getRelativeTimeSpanString(
                (long) post.getTimestamp()).toString());
        final String postKey;
        if (mAdapter instanceof FirebaseRecyclerAdapter) {
            postKey = ((FirebaseRecyclerAdapter) mAdapter).getRef(position).getKey();
        } else {
            postKey = inPostKey;
        }

        Author author = post.getAuthor();
        postViewHolder.setAuthor(author.getFull_name(), author.getUid());
        postViewHolder.setIcon(author.getProfile_picture(), author.getUid());

        ValueEventListener likeListener = new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                postViewHolder.setNumLikes(dataSnapshot.getChildrenCount());
                if (dataSnapshot.hasChild(FirebaseUtil.getCurrentUserId())) {
                    postViewHolder.setLikeStatus(PostViewHolder.LikeStatus.LIKED, getActivity());
                } else {
                    postViewHolder.setLikeStatus(PostViewHolder.LikeStatus.NOT_LIKED, getActivity());
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {

            }
        };
        FirebaseUtil.getLikesRef().child(postKey).addValueEventListener(likeListener);
        postViewHolder.mLikeListener = likeListener;

        postViewHolder.setPostClickListener(new PostViewHolder.PostClickListener() {
            @Override
            public void showComments() {
                Log.d(TAG, "Comment position: " + position);
                mListener.onPostComment(postKey);
            }

            @Override
            public void toggleLike() {
                Log.d(TAG, "Like position: " + position);
                mListener.onPostLike(postKey);
            }
        });
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (mAdapter != null && mAdapter instanceof FirebaseRecyclerAdapter) {
            ((FirebaseRecyclerAdapter) mAdapter).cleanup();
        }
    }


    @Override
    public void onSaveInstanceState(Bundle savedInstanceState) {
        // Save currently selected layout manager.
        int recyclerViewScrollPosition = getRecyclerViewScrollPosition();
        Log.d(TAG, "Recycler view scroll position: " + recyclerViewScrollPosition);
        savedInstanceState.putSerializable(KEY_LAYOUT_POSITION, recyclerViewScrollPosition);
        super.onSaveInstanceState(savedInstanceState);
    }

    private int getRecyclerViewScrollPosition() {
        int scrollPosition = 0;
        // TODO: Is null check necessary?
        if (mRecyclerView != null && mRecyclerView.getLayoutManager() != null) {
            scrollPosition = ((LinearLayoutManager) mRecyclerView.getLayoutManager())
                    .findFirstCompletelyVisibleItemPosition();
        }
        return scrollPosition;
    }
    /**
     * This interface must be implemented by activities that contain this
     * fragment to allow an interaction in this fragment to be communicated
     * to the activity and potentially other fragments contained in that
     * activity.
     * <p/>
     */
    public interface OnPostSelectedListener {
        void onPostComment(String postKey);
        void onPostLike(String postKey);
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof OnPostSelectedListener) {
            mListener = (OnPostSelectedListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnPostSelectedListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }
}
