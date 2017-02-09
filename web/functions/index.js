/**
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for t`he specific language governing permissions and
 * limitations under the License.
 */
'use strict';

const functions = require('firebase-functions');
const firebaseAdmin = require('firebase-admin');
var serviceAccount = require('./service-account-credentials.json');
firebaseAdmin.initializeApp({
  credential: firebaseAdmin.credential.cert(serviceAccount),
  databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
});
const mkdirp = require('mkdirp-promise');
const gcs = require('@google-cloud/storage')();
const vision = require('@google-cloud/vision')();
const exec = require('child-process-promise').exec;
const rp = require('request-promise-native');

const LOCAL_TMP_FOLDER = '/tmp';

/**
 * Triggers when a user gets a new follower and sends notifications if the user has enabled them.
 * Also avoids sending multiple notifications for the same user by keeping a timestamp of sent notifications.
 */
exports.sendFollowerNotification = functions.database().path('followers/{followedUid}/{followerUid}').onWrite(event => {
  const followerUid = event.params.followerUid;
  const followedUid = event.params.followedUid;
  // If un-follow we exit the function.
  if (!event.data.val()) {
    return console.log('User ', followerUid, 'un-followed user', followedUid);
  }
  const followedUserRef = firebaseAdmin.database().ref(`people/${followedUid}`);
  console.log('We have a new follower UID:', followerUid, 'for user:', followerUid);

  // Check if the user has notifications enabled.
  return followedUserRef.child('notificationEnabled').once('value').then(enabledSnap => {
    const notificationsEnabled = enabledSnap.val();
    if (!notificationsEnabled) {
      return console.log('The user has not enabled notifications.');
    }
    console.log('User has notifications enabled.');

    // Check if we already sent that notification.
    return followedUserRef.child(`notificationsSent/${followerUid}`).once('value').then(snap => {
      if (snap.val()) {
        return console.log('Already sent a notification to', followedUid, 'for this follower.');
      }
      console.log('Not yet sent a notification to', followedUid, 'for this follower.');

      // Get the list of device notification tokens.
      const getNotificationTokensPromise = followedUserRef.child('notificationTokens').once('value');

      // Get the follower profile.
      const getFollowerProfilePromise = firebaseAdmin.auth().getUser(followerUid);

      return Promise.all([getNotificationTokensPromise, getFollowerProfilePromise]).then(results => {
        const tokensSnapshot = results[0];
        const follower = results[1];

        // Check if there are any device tokens.
        if (!tokensSnapshot.hasChildren()) {
          return console.log('There are no notification tokens to send to.');
        }
        console.log('There are', tokensSnapshot.numChildren(), 'tokens to send notifications to.');
        console.log('Fetched follower profile', follower);
        const displayName = follower.displayName;
        const profilePic = follower.photoURL;

        // Sends notifications to all tokens.
        const notificationPromises = [];
        tokensSnapshot.forEach(tokenSnapshot => {
          const token = tokenSnapshot.key;
          const notificationPromise = sendNotification(followerUid, displayName, token,
              followedUid, profilePic);
          notificationPromises.push(notificationPromise);
        });

        // Saves the flag that this notification has been sent.
        const setNotificationsSentTask = followedUserRef.child(`notificationsSent/${followerUid}`)
            .set(firebaseAdmin.database.ServerValue.TIMESTAMP);

        return Promise.all(notificationPromises.concat([setNotificationsSentTask])).then(() => {
          console.log('Marked notification as sent.');
          console.log('Finished sending notifications.');
        });
      });
    });
  });
});

/**
 * Sends a "New follower" notification to the given `token`.
 * Removes/cleans up the token from the database if they are not registered anymore.
 */
function sendNotification(followerUid, displayName, token, followedUid, profilePic) {
  // Prepare the REST request to the Firebase Cloud Messaging API.
  var options = {
    method: 'POST',
    uri: 'https://fcm.googleapis.com/fcm/send',
    headers: {
      Authorization: `key=${functions.env.firebase.apiKey}`
    },
    body: {
      notification: {
        title: 'You have a new follower!',
        body: `${displayName} is now following you.`,
        icon: profilePic || '/images/silhouette.jpg',
        click_action: `https://friendly-pix.com/user/${followerUid}`
      },
      to: token
    },
    json: true
  };

  // Send the REST request to the Firebase Cloud Messaging API.
  return rp(options).then(resp => {
    console.log('Sent a notification.', resp.success ? 'Success' : 'Failure');

    // Cleanup the tokens who are not registered anymore.
    if (resp.failure && resp.results[0].error === 'NotRegistered') {
      return firebaseAdmin.database().ref(`people/${followedUid}/notificationTokens/${token}`).remove().then(() => {
        console.log('Removed unregistered token.');
      });
    }
  });
}

/**
 * When an image is uploaded we check if it is flagged as Adult or Violence by the Cloud Vision
 * API and if it is we blur it using ImageMagick.
 */
exports.blurOffensiveImages = functions.storage().onChange(event => {
  const file = gcs.bucket(event.data.bucket).file(event.data.name);

  // Exit if this is a move or deletion event.
  if (event.data.resourceState === 'not_exists') {
    console.log('This is a deletion event.');
    return;
  }

  // Check the image content using the Cloud Vision API.
  return vision.detectSafeSearch(file).then(data => {
    const safeSearch = data[0];
    console.log('SafeSearch results on image', safeSearch);

    if (safeSearch.adult || safeSearch.violence) {
      return blurImage(event.data.name, event.data.bucket, event.data.metadata).then(() => {
        const filePathSplit = event.data.name.split('/');
        const uid = filePathSplit[0];
        const size = filePathSplit[1]; // 'thumb' or 'full'
        const postId = filePathSplit[2];

        return refreshImages(uid, postId, size);
      });
    }
  });
});

/**
 * Blurs the given image located in the given bucket using ImageMagick.
 */
function blurImage(filePath, bucketName, metadata) {
  const filePathSplit = filePath.split('/');
  filePathSplit.pop();
  const fileDir = filePathSplit.join('/');
  const tempLocalDir = `${LOCAL_TMP_FOLDER}/${fileDir}`;
  const tempLocalFile = `${LOCAL_TMP_FOLDER}/${filePath}`;

  // Create the temp directory where the storage file will be downloaded.
  return mkdirp(tempLocalDir).then(() => {
    // Download file from bucket.
    const bucket = gcs.bucket(bucketName);
    return bucket.file(filePath).download({
      destination: tempLocalFile
    }).then(() => {
      console.log('The file has been downloaded to', tempLocalFile);
      // Blur the image using ImageMagick.
      return exec(`convert ${tempLocalFile} -channel RGBA -blur 0x24 ${tempLocalFile}`).then(() => {
        console.log('Blurred image created at', tempLocalFile);
        // Uploading the Blurred image.
        return bucket.upload(tempLocalFile, {
          destination: filePath,
          metadata: {metadata: metadata} // Keeping custom metadata.
        }).then(() => {
          console.log('Blurred image uploaded to Storage at', filePath);
        });
      });
    });
  });
}

/**
 * Changes the image URL slightly (add a `blurred` query parameter) to force a refresh.
 */
function refreshImages(uid, postId, size) {
  let app;
  try {
    app = firebaseAdmin.initializeApp({
      credential: firebaseAdmin.credential.applicationDefault(),
      databaseURL: `https://${process.env.GCLOUD_PROJECT}.firebaseio.com`,
      databaseAuthVariableOverride: {
        uid: uid
      }
    }, uid);
  } catch (e) {
    app = firebaseAdmin.app(uid);
  }

  const imageUrlRef = app.database().ref(`/posts/${postId}/${size}_url`);
  return imageUrlRef.once('value').then(snap => {
    const picUrl = snap.val();
    return imageUrlRef.set(`${picUrl}&blurred`);
  });
}
