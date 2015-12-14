import UIKit

struct FPPhotoHeaderButtons : OptionSetType {
  let rawValue: Int

  static let None = FPPhotoHeaderButtons(rawValue: 0)
  static let Like = FPPhotoHeaderButtons(rawValue: 1 << 0)
  static let Comment = FPPhotoHeaderButtons(rawValue: 1 << 1)
  static let User  = FPPhotoHeaderButtons(rawValue: 1 << 2)
  static let Default = FPPhotoHeaderButtons(rawValue: Like.rawValue | Comment.rawValue | User.rawValue)
}

@objc protocol FPPhotoHeaderViewDelegate {
}

class FPPhotoHeaderView: UITableViewCell {
  var containerView : UIView?
  var avatarImageView: FPProfileImageView = FPProfileImageView.init(frame: CGRectMake( 4.0, 4.0, 35.0, 35.0))
  var userButton : UIButton!
  var timestampLabel: UILabel!
  //property (nonatomic, strong) TTTTimeIntervalFormatter *timeIntervalFormatter;
  /// The photo associated with this view
  var photo: [String: String]? {
    didSet {
      self.superview?.clipsToBounds = false
    }
  }

  var author : [String: String]? {
    didSet {
      self.avatarImageView.profileImageView.image = UIImage(named: "ic_account_circle")
      if let pic = author![FPConstants.PeopleFields.pic] {
        if let url = NSURL(string:pic) {
          if let data = NSData(contentsOfURL: url) {
            self.avatarImageView.profileImageView.image = UIImage(data: data)
          }
        }
      }
      //      if ([PAPUtility userHasProfilePictures:user]) {
      //        PFFile *profilePictureSmall = [user objectForKey:kPAPUserProfilePicSmallKey];
      //        [self.avatarImageView setFile:profilePictureSmall];
      //      } else {
      //        [self.avatarImageView setImage:[PAPUtility defaultProfilePicture]];
      //      }
      //
            self.avatarImageView.contentMode = .ScaleAspectFill
            self.avatarImageView.layer.cornerRadius = 17.5
            self.avatarImageView.layer.masksToBounds = true

      if let name = author![FPConstants.PeopleFields.displayName] {
        self.userButton.setTitle(name, forState: .Normal)
      }
      var constrainWidth = containerView!.bounds.size.width

      if (self.buttons.contains(.User)) {
        self.userButton.addTarget(self, action: "didTapUserButtonAction:", forControlEvents: .TouchUpInside)
      }

      if (self.buttons.contains(.Comment)) {
        constrainWidth = self.commentButton.frame.origin.x
        self.commentButton.addTarget(self, action: "didTapCommentOnPhotoButtonAction:", forControlEvents: .TouchUpInside)
      }

      if (self.buttons.contains(.Like)) {
        constrainWidth = self.likeButton.frame.origin.x
        self.likeButton.addTarget(self, action: "didTapLikePhotoButtonAction:", forControlEvents: .TouchUpInside)
      }

      // we resize the button to fit the user's name to avoid having a huge touch area
      let userButtonPoint = CGPointMake(50.0, 6.0)
      constrainWidth -= userButtonPoint.x
      let constrainSize = CGSizeMake(constrainWidth, containerView!.bounds.size.height - userButtonPoint.y*2.0)

      let userButtonSize = ((self.userButton.titleLabel?.text)! as NSString).boundingRectWithSize(constrainSize, options: [.TruncatesLastVisibleLine, .UsesLineFragmentOrigin], attributes: [NSFontAttributeName: self.userButton.titleLabel!.font], context: nil).size

      
            let userButtonFrame = CGRectMake(userButtonPoint.x, userButtonPoint.y, userButtonSize.width, userButtonSize.height)
            self.userButton.frame = userButtonFrame

      //      let timeInterval = [[self.photo createdAt] timeIntervalSinceNow];
      //      NSString *timestamp = [self.timeIntervalFormatter stringForTimeInterval:timeInterval];
      //      [self.timestampLabel setText:timestamp];
      
            self.setNeedsDisplay()


    }
  }

  /// The bitmask which specifies the enabled interaction elements in the view
  var buttons: FPPhotoHeaderButtons!

  /*! @name Accessing Interaction Elements */

  /// The Like Photo button
  var likeButton : UIButton! {
    didSet {

    }
  }

  /// The Comment On Photo button
  var commentButton : UIButton!

  /*! @name Delegate */
  weak var delegate: FPPhotoHeaderViewDelegate?

  init(framex: CGRect, otherButtons: FPPhotoHeaderButtons) {
    super.init(style: .Default, reuseIdentifier: nil)
    //FPPhotoHeaderView.validateButtons(otherButtons)
    buttons = otherButtons;

    self.clipsToBounds = false
//    self.superview!.clipsToBounds = false
    self.backgroundColor = UIColor.clearColor()

    // translucent portion
    self.containerView = UIView.init(frame: CGRectMake( 0.0, 0.0, self.bounds.size.width, self.bounds.size.height))
    self.addSubview(self.containerView!)
    self.containerView!.backgroundColor = UIColor.whiteColor()
    self.containerView!.clipsToBounds = false

    self.avatarImageView.profileButton.addTarget(self, action: "didTapUserButtonAction:", forControlEvents: .TouchUpInside)
    self.containerView!.addSubview(self.avatarImageView)

    if (buttons.contains(.Comment)) {
      // comments button
      commentButton = UIButton(type: .Custom)
      containerView!.addSubview(self.commentButton)
      commentButton.frame = (CGRectMake( 282.0, 10.0, 29.0, 29.0))
      commentButton.backgroundColor = UIColor.clearColor()
      commentButton.setTitle("", forState: .Normal)
      commentButton .setTitleColor(UIColor.init(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0), forState: .Normal)
      commentButton.titleEdgeInsets = UIEdgeInsetsMake(-6.0, 0.0, 0.0, 0.0)
      commentButton.titleLabel?.font = UIFont.systemFontOfSize(12.0)
      commentButton.titleLabel?.minimumScaleFactor = 0.8
      commentButton.titleLabel?.adjustsFontSizeToFitWidth = true
      commentButton.setBackgroundImage(UIImage.init(named: "IconComment.png"), forState: .Normal)
      commentButton.selected = false
    }

    if (buttons.contains(.Like)) {
      // like button
      likeButton = UIButton.init(type: .Custom)
      containerView!.addSubview(self.likeButton)
      likeButton.frame = CGRectMake(246.0, 9.0, 29.0, 29.0)
      likeButton.backgroundColor = UIColor.clearColor()
      likeButton.setTitle("", forState: .Normal)
      likeButton.setTitleColor(UIColor.init(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0), forState: .Normal)
      likeButton.setTitleColor(UIColor.whiteColor(), forState: .Selected)
      self.likeButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
      self.likeButton.titleLabel?.font = UIFont.systemFontOfSize(12.0)
      self.likeButton.titleLabel?.minimumScaleFactor = 0.8
      self.likeButton.titleLabel?.adjustsFontSizeToFitWidth = true
      likeButton.adjustsImageWhenDisabled = false
      likeButton.adjustsImageWhenHighlighted = false
      self.likeButton.setBackgroundImage(UIImage.init(named: "ButtonLike.png"), forState: .Normal)
      self.likeButton.setBackgroundImage(UIImage.init(named: "ButtonLikeSelected.png"), forState: .Selected)
      self.likeButton.selected = false
    }

    if (self.buttons.contains(.User)) {
      // This is the user's display name, on a button so that we can tap on it
      userButton = UIButton.init(type: .Custom)
      containerView!.addSubview(self.userButton)
      userButton.backgroundColor = UIColor.clearColor()
      userButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
      userButton.setTitleColor(UIColor.init(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0), forState: .Normal)
      userButton.setTitleColor(UIColor.blackColor(), forState: .Highlighted)
      userButton.titleLabel?.lineBreakMode = .ByTruncatingTail
    }

    //self.timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];

      // timestamp
      self.timestampLabel = UILabel.init(frame: CGRectMake( 50.0, 24.0, containerView!.bounds.size.width - 50.0 - 72.0, 18.0))
      containerView!.addSubview(self.timestampLabel)
timestampLabel.textColor = UIColor.init(red: 114.0/255.0, green: 114.0/255.0, blue: 114.0/255.0, alpha: 1.0)
      timestampLabel.font =  UIFont.systemFontOfSize(11.0)
      timestampLabel.backgroundColor = UIColor.clearColor()
  }

  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }

  // MARK: - FPPhotoHeaderView
//
//  - (void)setLikeStatus:(BOOL)liked {
//    [self.likeButton setSelected:liked];
//
//    if (liked) {
//      [self.likeButton setTitleEdgeInsets:UIEdgeInsetsMake(-3.0f, 0.0f, 0.0f, 0.0f)];
//    } else {
//      [self.likeButton setTitleEdgeInsets:UIEdgeInsetsMake(-3.0f, 0.0f, 0.0f, 0.0f)];
//    }
//    }
//
//    - (void)shouldEnableLikeButton:(BOOL)enable {
//      if (enable) {
//        [self.likeButton removeTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//      } else {
//        [self.likeButton addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//      }
//}
//
//func validateButtons(buttons: FPPhotoHeaderButtons) {
//  if (buttons == FPPhotoHeaderButtons.None) {
//  //  [NSException raise:NSInvalidArgumentException format:@"Buttons must be set before initializing PAPPhotoHeaderView."];
//  }
//  }
//
//  - (void)didTapUserButtonAction:(UIButton *)sender {
//    if (delegate && [delegate respondsToSelector:@selector(photoHeaderView:didTapUserButton:user:)]) {
//      [delegate photoHeaderView:self didTapUserButton:sender user:[self.photo objectForKey:kPAPPhotoUserKey]];
//    }
//    }
//
//    - (void)didTapLikePhotoButtonAction:(UIButton *)button {
//      if (delegate && [delegate respondsToSelector:@selector(photoHeaderView:didTapLikePhotoButton:photo:)]) {
//        [delegate photoHeaderView:self didTapLikePhotoButton:button photo:self.photo];
//      }
//      }
//
//      - (void)didTapCommentOnPhotoButtonAction:(UIButton *)sender {
//        if (delegate && [delegate respondsToSelector:@selector(photoHeaderView:didTapCommentOnPhotoButton:photo:)]) {
//          [delegate photoHeaderView:self didTapCommentOnPhotoButton:sender photo:self.photo];
//        }
//}
}
