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
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);
const mkdirp = require('mkdirp-promise');
const gcs = require('@google-cloud/storage')();
const vision = require('@google-cloud/vision')();
const exec = require('child-process-promise').exec;

const LOCAL_TMP_FOLDER = '/tmp';

/**
 * Triggers when a user gets a new follower and sends notifications if the user has enabled them.
 * Also avoids sending multiple notifications for the same user by keeping a timestamp of sent notifications.
 */
exports.sendFollowerNotification = functions.database.ref('/followers/{followedUid}/{followerUid}').onWrite(event => {
  const followerUid = event.params.followerUid;
  const followedUid = event.params.followedUid;
  // If un-follow we exit the function.
  if (!event.data.val()) {
    return console.log('User ', followerUid, 'un-followed user', followedUid);
  }
  const followedUserRef = admin.database().ref(`people/${followedUid}`);
  console.log('We have a new follower UID:', followerUid, 'for user:', followerUid);

  // Check if the user has notifications enabled.
  return followedUserRef.child('/notificationEnabled').once('value').then(enabledSnap => {
    const notificationsEnabled = enabledSnap.val();
    if (!notificationsEnabled) {
      return console.log('The user has not enabled notifications.');
    }
    console.log('User has notifications enabled.');

    // Check if we already sent that notification.
    return followedUserRef.child(`/notificationsSent/${followerUid}`).once('value').then(snap => {
      if (snap.val()) {
        return console.log('Already sent a notification to', followedUid, 'for this follower.');
      }
      console.log('Not yet sent a notification to', followedUid, 'for this follower.');

      // Get the list of device notification tokens.
      const getNotificationTokensPromise = followedUserRef.child('notificationTokens').once('value');

      // Get the follower profile.
      const getFollowerProfilePromise = admin.auth().getUser(followerUid);

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

        // Notification details.
        const payload = {
          notification: {
            title: 'You have a new follower!',
            body: `${displayName} is now following you.`,
            icon: profilePic || '/images/silhouette.jpg',
            click_action: `https://friendly-pix.com/user/${followerUid}`
          }
        };

        // Listing all device tokens of the user to notify.
        const tokens = Object.keys(tokensSnapshot.val());

        // Saves the flag that this notification has been sent.
        const setNotificationsSentTask = followedUserRef.child(`/notificationsSent/${followerUid}`)
          .set(admin.database.ServerValue.TIMESTAMP).then(() => {
            console.log('Marked notification as sent.');
          });

        // Send notifications to all tokens.
        const notificationPromise = admin.messaging().sendToDevice(tokens, payload).then(response => {
          // For each message check if there was an error.
          const tokensToRemove = {};
          response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
              console.error('Failure sending notification to', tokens[index], error);
              // Cleanup the tokens who are not registered anymore.
              if (error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered') {
                tokensToRemove[`/people/${followedUid}/notificationTokens/${tokens[index]}`] = null;
              }
            }
          });
          // If there are tokens to cleanup.
          const nbTokensToCleanup = Object.keys(tokensToRemove).length;
          if (nbTokensToCleanup > 0) {
            return admin.database.ref('/').update(tokensToRemove).then(() => {
              console.log(`Removed ${nbTokensToCleanup} unregistered tokens.`);
            });
          }
          console.log(`Successfully sent ${tokens.length - nbTokensToCleanup} notifications.`);
        });

        return Promise.all([notificationPromise, setNotificationsSentTask]);
      });
    });
  });
});

/**
 * When an image is uploaded we check if it is flagged as Adult or Violence by the Cloud Vision
 * API and if it is we blur it using ImageMagick.
 */
exports.blurOffensiveImages = functions.storage.object().onChange(event => {
  const object = event.data;
  const file = gcs.bucket(object.bucket).file(object.name);

  // Exit if this is a move or deletion event.
  if (object.resourceState === 'not_exists') {
    console.log('This is a deletion event.');
    return;
  }

  // Check the image content using the Cloud Vision API.
  return vision.detectSafeSearch(file).then(data => {
    const safeSearch = data[0];
    console.log('SafeSearch results on image', safeSearch);

    if (safeSearch.adult || safeSearch.violence) {
      return blurImage(object.name, object.bucket, object.metadata).then(() => {
        const filePathSplit = object.name.split('/');
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
 * Changes the image URL slightly (add a `&blurred` query parameter) to force a refresh.
 */
function refreshImages(uid, postId, size) {
  let app;
  try {
    // Create a Firebase app that will honor security rules for a specific user.
    const config = {
      credential: functions.config().firebase.credential,
      databaseURL: functions.config().firebase.databaseURL,
      databaseAuthVariableOverride: {
        uid: uid
      }
    };
    app = admin.initializeApp(config, uid);
  } catch (e) {
    if (e.code === 'app/duplicate-app') {
      // An app for that UID was already created so we re-use it.
      app = admin.app(uid);
    } else {
      throw e;
    }
  }

  const imageUrlRef = app.database().ref(`/posts/${postId}/${size}_url`);
  return imageUrlRef.once('value').then(snap => {
    const picUrl = snap.val();
    return imageUrlRef.set(`${picUrl}&blurred`);
  });
}
