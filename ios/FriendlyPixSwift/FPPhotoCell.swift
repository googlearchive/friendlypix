//
//  FPPhotoCell.swift
//  FriendlyPix
//
//  Created by Ibrahim Ulukaya on 11/26/15.
//  Copyright © 2015 Google Inc. All rights reserved.
//

class FPPhotoCell: UITableViewCell {
  var photoButton: UIButton!

  // pragma mark - NSObject

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.opaque = false
    self.selectionStyle = UITableViewCellSelectionStyle.None
    self.accessoryType = UITableViewCellAccessoryType.None
    self.clipsToBounds = false

  self.backgroundColor = UIColor.clearColor()

  self.imageView!.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.width)
  self.imageView!.backgroundColor = UIColor.blackColor()
  self.imageView!.contentMode = UIViewContentMode.ScaleAspectFit

  self.photoButton = UIButton.init(type: .Custom)
  self.photoButton.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.width)
  self.photoButton.backgroundColor = UIColor.clearColor()
  self.contentView.addSubview(self.photoButton)

  self.contentView.bringSubviewToFront(self.imageView!)
  }

  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }

  //pragma mark - UIView

  override func layoutSubviews() {
    super.layoutSubviews()
    self.imageView!.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.width)
    self.photoButton.frame = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.width)
  }

}
