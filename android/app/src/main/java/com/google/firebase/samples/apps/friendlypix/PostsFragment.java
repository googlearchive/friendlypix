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

import com.firebase.client.DataSnapshot;
import com.firebase.client.Firebase;
import com.firebase.client.FirebaseError;
import com.firebase.client.ValueEventListener;
import com.firebase.ui.FirebaseRecyclerAdapter;
import com.google.firebase.samples.apps.friendlypix.Models.Person;
import com.google.firebase.samples.apps.friendlypix.Models.Post;

import java.util.ArrayList;
import java.util.List;

/**
 * Shows a list of posts.
 */
public class PostsFragment extends Fragment {

    public static final String TAG = "PostsFragment";
    private static final String KEY_LAYOUT_POSITION = "layoutPosition";
    private static final String KEY_TYPE = "type";
    public static final int TYPE_NEARBY = 1000;
    public static final int TYPE_RECOMMENDED = 1001;
    public static final int TYPE_HOT = 1002;
    public static final int TYPE_FOLLOWING = 1003;
    public static final int TYPE_YOUR_POSTS = 1004;
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
        mRecyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));

        if (savedInstanceState != null) {
            // Restore saved layout manager type.
            mRecyclerViewPosition = (int) savedInstanceState
                    .getSerializable(KEY_LAYOUT_POSITION);
            mRecyclerView.scrollToPosition(mRecyclerViewPosition);
            // TODO: RecyclerView only restores position properly for some tabs.
        }

        switch (getArguments().getInt(KEY_TYPE)) {
            case TYPE_RECOMMENDED:
                Log.d(TAG, "Restoring recycler view position (recommended): " + mRecyclerViewPosition);
                Firebase postsRef = new Firebase("https://friendlypix-4fa22.firebaseio.com/posts");
                mAdapter = new FirebaseRecyclerAdapter<Post, PostViewHolder>(
                        Post.class, R.layout.post_item, PostViewHolder.class, postsRef) {
                    @Override
                    public void populateViewHolder(final PostViewHolder postViewHolder,
                                                   final Post post, final int position) {
                        setupPost(postViewHolder, post, position, null);
                    }
                };
                break;
            case TYPE_NEARBY:
                Log.d(TAG, "Restoring recycler view position (nearby): " + mRecyclerViewPosition);
                // stuff
                break;
            case TYPE_FOLLOWING:
                Log.d(TAG, "Restoring recycler view position (following): " + mRecyclerViewPosition);
                mAdapter = new FirebasePostQueryAdapter(null, new FirebasePostQueryAdapter.OnSetupViewListener() {
                    @Override
                    public void onSetupView(PostViewHolder holder, Post post, int position, String postKey) {
                        setupPost(holder, post, position, postKey);
                    }
                });
                FirebaseUtil.getBaseRef().child("users").child(FirebaseUtil.getCurrentUserId()).child("following")
                        .addListenerForSingleValueEvent(new ValueEventListener() {

                            @Override
                            public void onDataChange(DataSnapshot dataSnapshot) {
                                for (DataSnapshot snapshot : dataSnapshot.getChildren()) {
                                    String userKey = snapshot.getKey();
                                    final List<String> photoPaths = new ArrayList<>();
                                    // TODO: Decide whether to duplicate post data for speed.
                                    FirebaseUtil.getBaseRef().child("users").child(userKey).child("posts")
                                            .addListenerForSingleValueEvent(new ValueEventListener() {
                                                @Override
                                                public void onDataChange(DataSnapshot dataSnapshot) {
                                                    for (DataSnapshot snapshot : dataSnapshot.getChildren()) {
                                                        photoPaths.add(snapshot.getKey());
                                                        ((FirebasePostQueryAdapter) mAdapter).addItem(snapshot.getKey());
                                                    }
                                                }

                                                @Override
                                                public void onCancelled(FirebaseError firebaseError) {

                                                }
                                            });
                                }
                            }

                            @Override
                            public void onCancelled(FirebaseError firebaseError) {

                            }
                        });
                break;
            case TYPE_HOT:
                Log.d(TAG, "Restoring recycler view position (hot): " + mRecyclerViewPosition);
                // stuff
                break;
            case TYPE_YOUR_POSTS:
                Log.d(TAG, "Restoring recycler view position (your posts): " + mRecyclerViewPosition);
                // stuff
                break;
            default:
                throw new RuntimeException("Illegal post fragment type specified.");
        }
        mRecyclerView.setAdapter(mAdapter);
    }

    private void setupPost(final PostViewHolder postViewHolder, final Post post, final int position, final String inPostKey) {
        postViewHolder.setPhoto(post.getUrl());
        postViewHolder.setText(post.getText());
        postViewHolder.setNumLikes(post.getLikes() != null ? post.getLikes().size() : 0);
        postViewHolder.setTimestamp(DateUtils.getRelativeTimeSpanString(
                (long) post.getTimestamp()).toString());
        final String postKey;
        if (mAdapter instanceof FirebaseRecyclerAdapter) {
            postKey = ((FirebaseRecyclerAdapter) mAdapter).getRef(position).getKey();
        } else {
            postKey = inPostKey;
        }
        // TODO: Fix after duplicate data decision is made.
        final Firebase authorRef = FirebaseUtil.getBaseRef().child("people").child(post.getAuthor());
        authorRef.addListenerForSingleValueEvent(
                new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        Person author = dataSnapshot.getValue(Person.class);
                        postViewHolder.setAuthor(author.getDisplayName(), authorRef.getKey());
                        postViewHolder.setIcon(author.getPhotoUrl(), authorRef.getKey());
                    }

                    @Override
                    public void onCancelled(FirebaseError firebaseError) {
                        new RuntimeException("Couldn't get comment username.", firebaseError.toException());
                    }
                }
        );
        FirebaseUtil.getCurrentUserRef().child("likes").child(postKey).addValueEventListener(
                new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                postViewHolder.setLikeStatus(
                        dataSnapshot.exists() ? PostViewHolder.LikeStatus.LIKED : PostViewHolder.LikeStatus.NOT_LIKED,
                        getActivity());
            }

            @Override
            public void onCancelled(FirebaseError firebaseError) {

            }
        });
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