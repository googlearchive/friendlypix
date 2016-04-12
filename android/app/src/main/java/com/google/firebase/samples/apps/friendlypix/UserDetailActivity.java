package com.google.firebase.samples.apps.friendlypix;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.design.widget.CollapsingToolbarLayout;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.ValueEventListener;
import com.google.firebase.samples.apps.friendlypix.Models.Person;
import com.google.firebase.samples.apps.friendlypix.Models.Post;
import com.google.firebase.samples.apps.friendlypix.Models.User;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class UserDetailActivity extends AppCompatActivity {
    private final String TAG = "UserDetailActivity";
    public static final String USER_ID_EXTRA_NAME = "user_name";
    private RecyclerView mRecyclerGrid;
    private GridAdapter mGridAdapter;
    private ValueEventListener mFollowingListener;
    private ValueEventListener mPersonInfoListener;
    private String mUserId;
    private DatabaseReference mUsersRef;
    private DatabaseReference mPersonRef;
    private static final int GRID_NUM_COLUMNS = 2;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_user_detail);

        Intent intent = getIntent();
        mUserId = intent.getStringExtra(USER_ID_EXTRA_NAME);

        final Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        final CollapsingToolbarLayout collapsingToolbar =
                (CollapsingToolbarLayout) findViewById(R.id.collapsing_toolbar);
        // TODO: Investigate why initial toolbar title is activity name instead of blank.

        mUsersRef = FirebaseUtil.getUsersRef();
        final String currentUserId = FirebaseUtil.getCurrentUserId();

        final FloatingActionButton followUserFab = (FloatingActionButton) findViewById(R.id
                .follow_user_fab);
        mFollowingListener = new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                if (dataSnapshot.exists()) {
                    followUserFab.setImageDrawable(ContextCompat.getDrawable(
                            UserDetailActivity.this, R.drawable.ic_done_24dp));
                } else {
                    followUserFab.setImageDrawable(ContextCompat.getDrawable(
                            UserDetailActivity.this, R.drawable.ic_person_add_24dp));
                }
            }

            @Override
            public void onCancelled(DatabaseError firebaseError) {

            }
        };
        if (currentUserId != null) {
            mUsersRef.child(currentUserId).child("following").child(mUserId)
                    .addValueEventListener(mFollowingListener);
        }
        followUserFab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (currentUserId == null) {
                    Toast.makeText(UserDetailActivity.this, "You need to sign in to follow someone.",
                            Toast.LENGTH_SHORT).show();
                    return;
                }
                // TODO: Convert these to actually not be single value, for live updating when
                // current user follows.
                mUsersRef.child(mUserId).child("followers").addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        Map<String, Object> updatedUserData = new HashMap<>();
                        if (dataSnapshot.hasChild(currentUserId)) {
                            // Already following, need to unfollow
                            updatedUserData.put(mUserId + "/followers/" + currentUserId, null);
                            updatedUserData.put(currentUserId + "/following/" + mUserId, null);
                        } else {
                            updatedUserData.put(mUserId + "/followers/" + currentUserId, true);
                            updatedUserData.put(currentUserId + "/following/" + mUserId, true);
                        }
                        mUsersRef.updateChildren(updatedUserData, new DatabaseReference.CompletionListener() {
                            @Override
                            public void onComplete(DatabaseError firebaseError, DatabaseReference firebase) {
                                if (firebaseError != null) {
                                    Toast.makeText(UserDetailActivity.this, R.string
                                            .follow_user_error, Toast.LENGTH_LONG).show();
                                    Log.d(TAG, getString(R.string.follow_user_error) + "\n" +
                                            firebaseError.getMessage());
                                }
                            }
                        });
                    }

                    @Override
                    public void onCancelled(DatabaseError firebaseError) {

                    }
                });
            }
        });

        mRecyclerGrid = (RecyclerView) findViewById(R.id.user_posts_grid);
        mGridAdapter = new GridAdapter();
        mRecyclerGrid.setAdapter(mGridAdapter);
        mRecyclerGrid.setLayoutManager(new GridLayoutManager(this, GRID_NUM_COLUMNS));

        DatabaseReference userRef = FirebaseUtil.getUsersRef().child(mUserId);
        userRef.addListenerForSingleValueEvent(
                new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot dataSnapshot) {
                        final User user = dataSnapshot.getValue(User.class);
                        if (user.getFollowers() != null) {
                            int numFollowers = user.getFollowers().size();
                            ((TextView) findViewById(R.id.user_num_followers))
                                    .setText(numFollowers + " follower" + (numFollowers == 1 ? "" : "s"));
                        }
                        if (user.getFollowing() != null) {
                            int numFollowing = user.getFollowing().size();
                            ((TextView) findViewById(R.id.user_num_following))
                                    .setText(numFollowing + " following");
                        }
                        if (user.getLikes() != null) {
                            int numLikes = user.getLikes() == null ? 0 : user.getLikes().size();
                            ((TextView) findViewById(R.id.user_num_likes))
                                    .setText(numLikes + " like" + (numLikes == 1 ? "" : "s"));
                        }

                        List<String> paths = new ArrayList<String>(user.getPosts().keySet());
                        mGridAdapter.addPaths(paths);
                        String firstPostKey = paths.get(0);

                        FirebaseUtil.getPostsRef().child(firstPostKey).addListenerForSingleValueEvent(new ValueEventListener() {
                            @Override
                            public void onDataChange(DataSnapshot dataSnapshot) {
                                Post post = dataSnapshot.getValue(Post.class);

                                ImageView imageView = (ImageView) findViewById(R.id.backdrop);
                                GlideUtil.loadImage(post.getUrl(), imageView);
                            }

                            @Override
                            public void onCancelled(DatabaseError firebaseError) {

                            }
                        });
                    }

                    @Override
                    public void onCancelled(DatabaseError firebaseError) {
                        new RuntimeException("Couldn't get user.", firebaseError.toException());
                    }
                });
        mPersonRef = FirebaseUtil.getPeopleRef().child(mUserId);
        mPersonInfoListener = mPersonRef.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                Person person = dataSnapshot.getValue(Person.class);
                CircleImageView userPhoto = (CircleImageView) findViewById(R.id.user_detail_photo);
                GlideUtil.loadProfileIcon(person.getPhotoUrl(), userPhoto);
                String name = person.getDisplayName();
                if (name == null) {
                    name = getString(R.string.user_info_no_name);
                }
                collapsingToolbar.setTitle(name);
            }

            @Override
            public void onCancelled(DatabaseError firebaseError) {

            }
        });
    }

    @Override
    protected void onDestroy() {
        if (FirebaseUtil.getCurrentUserId() != null) {
            mUsersRef.child(FirebaseUtil.getCurrentUserId()).child("following").child(mUserId)
                    .removeEventListener(mFollowingListener);
        }

        mPersonRef.child(mUserId).removeEventListener(mPersonInfoListener);

        super.onDestroy();
    }

    class GridAdapter extends RecyclerView.Adapter<GridImageHolder> {
        private List<String> mPostPaths;

        public GridAdapter() {
            mPostPaths = new ArrayList<String>();
        }

        @Override
        public GridImageHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            ImageView imageView = new ImageView(UserDetailActivity.this);
            int tileDimPx = getPixelsFromDps(100);
            imageView.setLayoutParams(new GridView.LayoutParams(tileDimPx, tileDimPx));
            imageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
            imageView.setPadding(8, 8, 8, 8);

            return new GridImageHolder(imageView);
        }

        @Override
        public void onBindViewHolder(final GridImageHolder holder, int position) {
            DatabaseReference ref = FirebaseUtil.getPostsRef().child(mPostPaths.get(position));
            ref.addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot) {
                    Post post = dataSnapshot.getValue(Post.class);
                    GlideUtil.loadImage(post.getUrl(), holder.imageView);
                    holder.imageView.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            // TODO: Implement go to post view.
                            Toast.makeText(UserDetailActivity.this, "Selected: " + holder
                                    .getAdapterPosition(),
                                    Toast.LENGTH_SHORT).show();
                        }
                    });
                }

                @Override
                public void onCancelled(DatabaseError firebaseError) {
                    Log.e(TAG, "Unable to load grid image: " + firebaseError.getMessage());
                }
            });
        }

        public void addPath(String path) {
            mPostPaths.add(path);
            notifyItemInserted(mPostPaths.size());
        }

        public void addPaths(List<String> paths) {
            int startIndex = mPostPaths.size();
            mPostPaths.addAll(paths);
            notifyItemRangeInserted(startIndex, mPostPaths.size());
        }

        @Override
        public int getItemCount() {
            return mPostPaths.size();
        }

        private int getPixelsFromDps(int dps) {
            final float scale = UserDetailActivity.this.getResources().getDisplayMetrics().density;
            return (int) (dps * scale + 0.5f);
        }
    }

    private class GridImageHolder extends RecyclerView.ViewHolder {
        public ImageView imageView;

        public GridImageHolder(ImageView itemView) {
            super(itemView);
            imageView = itemView;
        }
    }

    @Override
    public boolean onSupportNavigateUp() {
        finish();
        return super.onSupportNavigateUp();
    }
}
