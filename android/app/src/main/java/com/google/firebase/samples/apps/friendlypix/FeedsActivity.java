package com.google.firebase.samples.apps.friendlypix;

import android.content.Intent;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.TabLayout;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;

import android.support.v4.app.Fragment;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FeedsActivity extends AppCompatActivity implements PostsFragment.OnPostSelectedListener {
    private static final String TAG = "FeedsActivity";
    private FloatingActionButton mFab;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_feeds);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        ViewPager viewPager = (ViewPager) findViewById(R.id.feeds_view_pager);
        FeedsPagerAdapter adapter = new FeedsPagerAdapter(getSupportFragmentManager());
        adapter.addFragment(PostsFragment.newInstance(PostsFragment.TYPE_RECOMMENDED), "RECOMMENDED");
        adapter.addFragment(PostsFragment.newInstance(PostsFragment.TYPE_HOT), "HOT");
        adapter.addFragment(PostsFragment.newInstance(PostsFragment.TYPE_NEARBY), "NEARBY");
        adapter.addFragment(PostsFragment.newInstance(PostsFragment.TYPE_FOLLOWING), "FOLLOWING");
        viewPager.setAdapter(adapter);

        TabLayout tabLayout = (TabLayout) findViewById(R.id.feeds_tab_layout);
        tabLayout.setupWithViewPager(viewPager);

        mFab = (FloatingActionButton) findViewById(R.id.fab);
        mFab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent newPostIntent = new Intent(FeedsActivity.this, NewPostActivity.class);
                startActivity(newPostIntent);
            }
        });
    }

    @Override
    public void onPostComment(String postKey) {
        Intent intent = new Intent(this, CommentsActivity.class);
        intent.putExtra(CommentsActivity.POST_KEY_EXTRA, postKey);
        startActivity(intent);
    }

    @Override
    public void onPostLike(final String postKey) {
        final DatabaseReference ref = FirebaseUtil.getBaseRef();
        final String userKey = FirebaseUtil.getCurrentUserId();
        final DatabaseReference postLikesRef = FirebaseUtil.getPostsRef().child(postKey).child("likes");
        postLikesRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                if (dataSnapshot.hasChild(userKey)) {
                    // User already liked this post, so we toggle like off.
                    Map<String, Object> updatedUserData = new HashMap<>();
                    updatedUserData.put(FirebaseUtil.getUsersPath() + userKey + "/likes/" + postKey, null);
                    updatedUserData.put(FirebaseUtil.getPostsPath() + postKey + "/likes/" + userKey, null);
                    ref.updateChildren(updatedUserData, new DatabaseReference.CompletionListener() {
                        @Override
                        public void onComplete(DatabaseError firebaseError, DatabaseReference firebase) {
                            if (firebaseError != null) {
                                Toast.makeText(FeedsActivity.this, "Error unliking post.", Toast.LENGTH_SHORT).show();
                            }
                        }
                    });
                } else {
                    Map<String, Object> updatedUserData = new HashMap<>();
                    updatedUserData.put(FirebaseUtil.getUsersPath() + userKey + "/likes/" + postKey, true);
                    updatedUserData.put(FirebaseUtil.getPostsPath() + postKey + "/likes/" + userKey, true);
                    ref.updateChildren(updatedUserData, new DatabaseReference.CompletionListener() {
                        @Override
                        public void onComplete(DatabaseError firebaseError, DatabaseReference firebase) {
                            if (firebaseError != null) {
                                Toast.makeText(FeedsActivity.this, "Error liking post.", Toast.LENGTH_SHORT).show();

                            }
                        }
                    });
                }
            }

            @Override
            public void onCancelled(DatabaseError firebaseError) {

            }
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_feeds, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            // TODO: Add settings screen.
            return true;
        } else if (id == R.id.action_profile) {
            startActivity(new Intent(this, ProfileActivity.class));
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    class FeedsPagerAdapter extends FragmentPagerAdapter {
        private final List<Fragment> mFragmentList = new ArrayList<>();
        private final List<String> mFragmentTitleList = new ArrayList<>();

        public FeedsPagerAdapter(FragmentManager manager) {
            super(manager);
        }

        @Override
        public Fragment getItem(int position) {
            return mFragmentList.get(position);
        }

        @Override
        public int getCount() {
            return mFragmentList.size();
        }

        public void addFragment(Fragment fragment, String title) {
            mFragmentList.add(fragment);
            mFragmentTitleList.add(title);
        }

        @Override
        public CharSequence getPageTitle(int position) {
            return mFragmentTitleList.get(position);
        }
    }
}
