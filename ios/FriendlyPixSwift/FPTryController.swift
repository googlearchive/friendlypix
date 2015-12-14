//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import FirebaseDatabase
import Firebase.SignIn
import Firebase.Core

@objc(FPTryController)
class FPTryController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, GINInviteDelegate {

  // Instance variables
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var sendButton: UIButton!
  var ref: Firebase!
  var feed: [FDataSnapshot]! = []
  var msglength: NSNumber = 10
  private var _refHandle: FirebaseHandle!
  private var userInt: UInt32 = arc4random()

  @IBOutlet weak var banner: GADBannerView!
  @IBOutlet weak var clientTable: UITableView!

  @IBAction func didSendMessage(sender: UIButton) {
    textFieldShouldReturn(textField)
  }

  @IBAction func didInvite(sender: UIButton) {
    let invite = GINInvite.inviteDialog()
    invite.setMessage("Message")
    invite.setTitle("Title")
    invite.setDeepLink("/invite")

    invite.open()
  }

  // [START invite_finished]
  func inviteFinishedWithInvitations(invitationIds: [AnyObject]!, error: NSError!) {
    if (error != nil) {
      print("Failed: " + error.localizedDescription)
    } else {
      print("Invitations sent")
    }
  }
  // [END invite_finished]

  override func viewDidLoad() {
    super.viewDidLoad()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "showReceivedMessage:",
      name:FPConstants.NotificationKeys.Message, object: nil)

    self.ref = Firebase(url: FIRContext.sharedInstance().serviceInfo.databaseURL)
    loadAd()
    self.clientTable.registerClass(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
    fetchConfig()
  }

  func loadAd() {
    self.banner.adUnitID = FIRContext.sharedInstance().adUnitIDForBannerTest
    self.banner.rootViewController = self
    self.banner.loadRequest(GADRequest())
  }

  func fetchConfig() {
    // [START completion_handler]
    let completion:RCNDefaultConfigCompletion = {(config:RCNConfig!, status:RCNConfigStatus, error:NSError!) -> Void in
      if (error != nil) {
        // There has been an error fetching the config
        print("Error fetching config: \(error.localizedDescription)")
      } else {
        // Parse your config data
        // [START_EXCLUDE]
        // [START read_data]
        self.msglength = config.numberForKey("friendly_msg_length", defaultValue: 10)
        print("Friendly msg length config: \(self.msglength)")
        // [END read_data]
        // [END_EXCLUDE]
      }
    }
    // [END completion_handler]

    // [START fetch_config]
    let customVariables = ["build": "dev"]
    // 43200 secs = 12 hours
    RCNConfig.fetchDefaultConfigWithExpirationDuration(43200, customVariables: customVariables,
      completionHandler: completion)
    // [END fetch_config]
  }

  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text else { return true }

    let newLength = text.utf16.count + string.utf16.count - range.length
    return newLength <= self.msglength.integerValue // Bool
  }

  override func viewWillAppear(animated: Bool) {
    self.feed.removeAll()
    // Listen for new messages in the Firebase database
    _refHandle = self.ref.childByAppendingPath("photos").observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
      self.feed.append(snapshot)
      self.clientTable.insertRowsAtIndexPaths([NSIndexPath(forRow: self.feed.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
    })
  }

  override func viewWillDisappear(animated: Bool) {
    self.ref.removeObserverWithHandle(_refHandle)
  }

  // UITableViewDataSource protocol methods
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return feed.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    // Dequeue cell
    let cell: UITableViewCell! = self.clientTable .dequeueReusableCellWithIdentifier("tableViewCell", forIndexPath: indexPath)

    // Unpack message from Firebase DataSnapshot
    let photoSnapshot: FDataSnapshot! = self.feed[indexPath.row]
    let photo = photoSnapshot.value as! Dictionary<String, String>
    let text = photo[FPConstants.PhotoFields.text] as String!
    let photoUrl = photo[FPConstants.PhotoFields.url] as String!
    let authorId = photo[FPConstants.PhotoFields.author] as String!
    self.ref.childByAppendingPath("people/\(authorId)").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
      let author = snapshot.value as! Dictionary<String, String>
      let displayName = author[FPConstants.PeopleFields.displayName] as String!
      let pic = author[FPConstants.PeopleFields.pic] as String!
      print(pic)

      cell!.textLabel?.text = "\(displayName) says \(text)"
      cell!.imageView?.image = UIImage(named: "ic_account_circle")
      if let url = NSURL(string:photoUrl) {
        if let data = NSData(contentsOfURL: url) {
          cell!.imageView?.image = UIImage(data: data)
        }
      }
    })
    return cell!
  }

  // UITextViewDelegate protocol methods
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    var data = [FPConstants.MessageFields.text: textField.text as String!, FPConstants.MessageFields.name: "User\(self.userInt)"]
    if let user = FPAppState.sharedInstance.displayName {
      data[FPConstants.MessageFields.name] = user
    } else {
      data[FPConstants.MessageFields.name] = "User\(self.userInt)"
    }
    if let photoUrl = FPAppState.sharedInstance.photoUrl {
      data[FPConstants.MessageFields.photoUrl] = photoUrl.absoluteString
    }

    // Push data to Firebase Database
    //self.ref.childByAppendingPath("messages").childByAutoId().setValue(data)
    let photo : Firebase! = self.ref.childByAppendingPath("photos").childByAutoId()
    photo.setValue(data)
    let photoId = photo.key
    self.ref.childByAppendingPath("users/123/posts/\(photoId)").setValue(true)
    self.ref.childByAppendingPath("users/123/followers/").observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
      for follower in snapshot.children {
        self.ref.childByAppendingPath("users/\(follower.key as String!)/feed").setValue(true, forKey: photoId)
      }
    })

    self.ref.childByAppendingPath("users/123/feed/\(textField.text as String!)").setValue(true)
    textField.text = ""
    return true
  }

  func showReceivedMessage(notification: NSNotification) {
    if let info = notification.userInfo as? Dictionary<String,AnyObject> {
      if let aps = info["aps"] as? Dictionary<String, String> {
        showAlert("Message received", message: aps["alert"]!)
      }
    } else {
      print("Software failure. Guru meditation.")
    }
  }

  @IBAction func signOut(sender: UIButton) {
    let firebaseAuth = FIRAuth.init(forApp:FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID)!)
    firebaseAuth?.signOut()
    FPAppState.sharedInstance.signedIn = false
    performSegueWithIdentifier(FPConstants.Segues.FpToSignIn, sender: nil)
  }

  func showAlert(title:String, message:String) {
    dispatch_async(dispatch_get_main_queue()) {
      if #available(iOS 8.0, *) {
        let alert = UIAlertController(title: title,
            message: message, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Destructive, handler: nil)
        alert.addAction(dismissAction)
        self.presentViewController(alert, animated: true, completion: nil)
      } else {
          // Fallback on earlier versions
      }
    }
  }

  func guruMeditation() {
    let error = "Software failure. Guru meditation."
    showAlert("Error", message: error)
    print(error)
  }
}
