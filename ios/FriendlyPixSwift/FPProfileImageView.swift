//
//  FPProfileImageView.swift
//  FriendlyPix
//
//  Created by Ibrahim Ulukaya on 11/25/15.
//  Copyright © 2015 Google Inc. All rights reserved.
//

class FPProfileImageView : UIView {
  var profileButton : UIButton!
  var profileImageView: UIImageView!
  var borderImageview : UIImageView!

  // MARK: NSObject
  override init(frame: CGRect) {
    profileImageView = UIImageView.init(frame: frame)
    borderImageview = UIImageView.init(frame: frame)
    profileButton = UIButton.init(type: .Custom)
    super.init(frame: frame)
    self.backgroundColor = UIColor.clearColor()

    self.addSubview(self.profileImageView)

    self.addSubview(self.profileButton)

    self.addSubview(self.borderImageview)
  }

  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }

  // MARK: UIView
  override func layoutSubviews() {
  super.layoutSubviews()
  self.bringSubviewToFront(self.borderImageview)

  self.profileImageView.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)
  self.borderImageview.frame = CGRectMake( 0.0, 0.0, self.frame.size.width, self.frame.size.height);
  self.profileButton.frame = CGRectMake( 0.0, 0.0, self.frame.size.width, self.frame.size.height);
  }


  // MARK: PAPProfileImageView
//  func setFile(file : String) {
//    self.profileImageView.image = UIImage.init(named: "AvatarPlaceholder.png")
//    // load this in background
//    if let data = NSData(contentsOfFile: file) {
//      self.setImage(UIImage(data: data)!)
//    }
//  }
}
