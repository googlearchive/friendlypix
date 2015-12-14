//
//  FPPhotoTimelineViewController.swift
//  FriendlyPix
//
//  Created by Ibrahim Ulukaya on 11/30/15.
//  Copyright © 2015 Google Inc. All rights reserved.
//

import FirebaseDatabase
import Firebase.Core

class FPPhotoTimelineViewController: UITableViewController, FPPhotoHeaderViewDelegate {

  @IBOutlet var clientTable: UITableView!
  var shouldReloadOnAppear = false
  // Whether the built-in pagination is enabled
  var paginationEnabled = false
  // Improve scrolling performance by reusing UITableView section headers
  var reusableSectionHeaderViews : Set<FPPhotoHeaderView> = Set.init(minimumCapacity: 3)
  var ref: Firebase!
  var feed: [FDataSnapshot]! = []
  var feedAuthors = [String : FDataSnapshot]()
  private var _feedHandle: FirebaseHandle!
  private var _authorHandle: FirebaseHandle!


  override init(style: UITableViewStyle) {
    super.init(style: style)

    // Whether the built-in pull-to-refresh is enabled
//    self.pullToRefreshEnabled = true

    // The number of objects to show per page
    // self.objectsPerPage = 10;

    // The Loading text clashes with the dark Anypic design
    //self.loadingViewEnabled = NO;
  }

  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }

  // MARK: UIViewController
  override func viewDidLoad() {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    super.viewDidLoad()

    let texturedBackgroundView = UIView.init(frame: self.view.bounds)
    texturedBackgroundView.backgroundColor = UIColor.init(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    self.tableView.backgroundView = texturedBackgroundView

    self.ref = Firebase(url: FIRContext.sharedInstance().serviceInfo.databaseURL)

//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidPublishPhoto:) name:PAPTabBarControllerDidFinishEditingPhotoNotification object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userFollowingChanged:) name:PAPUtilityUserFollowingChangedNotification object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidDeletePhoto:) name:PAPPhotoDetailsViewControllerUserDeletedPhotoNotification object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLikeOrUnlikePhoto:) name:PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLikeOrUnlikePhoto:) name:PAPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:nil];
//  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidCommentOnPhoto:) name:PAPPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:nil];
  }

  override func viewWillAppear(animated: Bool) {
    self.feed.removeAll()
    // Listen for new messages in the Firebase database
    _feedHandle = self.ref.childByAppendingPath("photos").observeEventType(.ChildAdded, withBlock: { (photoSnapshot) -> Void in
      let photo = photoSnapshot.value as! Dictionary<String, String>
      let authorId = photo[FPConstants.PhotoFields.author] as String!
      self._authorHandle = self.ref.childByAppendingPath("people/\(authorId)").observeEventType(.Value, withBlock: { (peopleSnapshot) -> Void in
        if !self.feedAuthors.keys.contains(authorId) {
          self.feedAuthors[authorId] = peopleSnapshot
        }
        self.feed.append(photoSnapshot)
        self.clientTable.insertRowsAtIndexPaths([NSIndexPath(forRow: (self.feed.count-1)*2, inSection: 0), NSIndexPath(forRow: self.feed.count*2-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)

      })
    })
  }

  override func viewWillDisappear(animated: Bool) {
    self.ref.removeObserverWithHandle(_feedHandle)
    self.ref.removeObserverWithHandle(_authorHandle)
  }

//  override func viewDidAppear(animated: Bool) {
//    super.viewDidAppear(animated)
//
//    if self.shouldReloadOnAppear {
//      self.shouldReloadOnAppear = false
//    //  self.loadObjects()
//    }
//  }

  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }

  // MARK: UITableViewDataSource
//  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//    return 1
//  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.feed.count * 2// + (self.paginationEnabled ? 1 : 0)
  }

//  // MARK: UITableViewDelegate
//  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//    return nil
//  }

//  override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//    return 0.0
//  }
//
//  override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//    return 0.0
//  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//    if (self.paginationEnabled && (self.feed.count * 2) == indexPath.row) {
//      // Load More Section
//      return 44.0;
//    } else

      if (indexPath.row % 2 == 0) {
      return 44.0;
    }

    return 320.0;
  }

  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    // Handle selection of the next page row
//    if (!_firstLoad &&
//      self.paginationEnabled &&
//      [indexPath isEqual:[self _indexPathForPaginationCell]]) {
//        [self loadNextPage];
//    }
    super.tableView.deselectRowAtIndexPath(indexPath, animated: true)

    if (self.objectAtIndexPath(indexPath) == nil) {
      // Load More Cell
   //   self.loadNextPage()
    }
  }

  /*
  For each object in self.objects, we display two cells. If pagination is enabled, there will be an extra cell at the end.
  NSIndexPath     index self.objects
  0 0 HEADER      0
  0 1 PHOTO       0
  0 2 HEADER      1
  0 3 PHOTO       1
  0 4 LOAD MORE
  */

  func indexPathForObjectAtIndex(index: Int, header:Bool) -> NSIndexPath {
    return  NSIndexPath.init(forItem: index * 2 + (header ? 0 : 1), inSection: 0)
  }

  func indexForObjectAtIndexPath(indexPath: NSIndexPath) -> Int {
    return indexPath.row / 2;
  }

  func objectAtIndex(index: Int) -> FDataSnapshot? {
    if (index < self.feed.count) {
      return self.feed[index]
    }
    return nil
  }

  func objectAtIndexPath(indexPath: NSIndexPath) -> FDataSnapshot? {
    return objectAtIndex(indexForObjectAtIndexPath(indexPath))
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let CellIdentifier = "Cell"
    let index = self.indexForObjectAtIndexPath(indexPath)

    if (indexPath.row % 2 == 0) {
      // Header
      return self.detailPhotoCellForRowAtIndexPath(indexPath)!
    } else {
      // Photo
      var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as! FPPhotoCell?

      if (cell == nil) {
        cell = FPPhotoCell.init(style: .Default, reuseIdentifier: CellIdentifier)
        cell!.photoButton.addTarget(self, action: "didTapOnPhotoAction:", forControlEvents: .TouchDragInside)
      }

      cell!.photoButton.tag = index;
      cell!.imageView!.image = UIImage.init(named: "PlaceholderPhoto.png")

      let object = objectAtIndexPath(indexPath)

      if ((object) != nil) {
        let photo = object!.value as! Dictionary<String, String>
        let photoUrl = photo[FPConstants.PhotoFields.url] as String!
        if let url = NSURL(string:photoUrl) {
          if let data = NSData(contentsOfURL: url) {
            cell!.imageView?.image = UIImage(data: data)
          }
        }

        // PFQTVC will take care of asynchronously downloading files, but will only load them when the tableview is not moving. If the data is there, let's load it right away.
//        if ([cell.imageView.fil   e isDataAvailable]) {
//          [cell.imageView loadInBackground];
//        }
      }

      return cell!;
    }
  }

  // MARK - ()

  func detailPhotoCellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell? {
    let CellIdentifier = "DetailPhotoCell";

//    if (self.paginationEnabled && (indexPath.row == self.feed.count * 2)) {
//      // Load More section
//      return nil;
//    }

    let index = indexForObjectAtIndexPath(indexPath)

    var headerView = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as! FPPhotoHeaderView!
    if ((headerView == nil)) {
      headerView = FPPhotoHeaderView.init(framex: CGRectMake( 0.0, 0.0, self.view.bounds.size.width, 44.0), otherButtons: .Default)
      headerView.delegate = self
      headerView.selectionStyle = .None
    }

    let photoSnapshot = objectAtIndexPath(indexPath)
    headerView.photo = photoSnapshot!.value as? [String : String]
    let authorId = headerView.photo![FPConstants.PhotoFields.author] as String!
    headerView.author = self.feedAuthors[authorId]!.value as? [String : String]

    headerView.tag = index
    headerView.likeButton.tag = index

//  NSDictionary *attributesForPhoto = [[PAPCache sharedCache] attributesForPhoto:object];
//
//  if (attributesForPhoto) {
//  [headerView setLikeStatus:[[PAPCache sharedCache] isPhotoLikedByCurrentUser:object]];
//  [headerView.likeButton setTitle:[[[PAPCache sharedCache] likeCountForPhoto:object] description] forState:UIControlStateNormal];
//  [headerView.commentButton setTitle:[[[PAPCache sharedCache] commentCountForPhoto:object] description] forState:UIControlStateNormal];

//  if (headerView!.likeButton.alpha < 1.0 || headerView!.commentButton.alpha < 1.0) {
//  [UIView animateWithDuration:0.200f animations:^{
//  headerView.likeButton.alpha = 1.0f;
//  headerView.commentButton.alpha = 1.0f;
//  }];
//  }
//  } else {
//  headerView.likeButton.alpha = 0.0f;
//  headerView.commentButton.alpha = 0.0f;
//
//  @synchronized(self) {
//  // check if we can update the cache
//  NSNumber *outstandingSectionHeaderQueryStatus = [self.outstandingSectionHeaderQueries objectForKey:@(index)];
//  if (!outstandingSectionHeaderQueryStatus) {
//  PFQuery *query = [PAPUtility queryForActivitiesOnPhoto:object cachePolicy:kPFCachePolicyNetworkOnly];
//  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//  @synchronized(self) {
//  [self.outstandingSectionHeaderQueries removeObjectForKey:@(index)];
//
//  if (error) {
//  return;
//  }
//
//  NSMutableArray *likers = [NSMutableArray array];
//  NSMutableArray *commenters = [NSMutableArray array];
//
//  BOOL isLikedByCurrentUser = NO;
//
//  for (PFObject *activity in objects) {
//  if ([[activity objectForKey:kPAPActivityTypeKey] isEqualToString:kPAPActivityTypeLike] && [activity objectForKey:kPAPActivityFromUserKey]) {
//  [likers addObject:[activity objectForKey:kPAPActivityFromUserKey]];
//  } else if ([[activity objectForKey:kPAPActivityTypeKey] isEqualToString:kPAPActivityTypeComment] && [activity objectForKey:kPAPActivityFromUserKey]) {
//  [commenters addObject:[activity objectForKey:kPAPActivityFromUserKey]];
//  }
//
//  if ([[[activity objectForKey:kPAPActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
//  if ([[activity objectForKey:kPAPActivityTypeKey] isEqualToString:kPAPActivityTypeLike]) {
//  isLikedByCurrentUser = YES;
//  }
//  }
//  }
//
//  [[PAPCache sharedCache] setAttributesForPhoto:object likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
//
//  if (headerView.tag != index) {
//  return;
//  }
//
//  [headerView setLikeStatus:[[PAPCache sharedCache] isPhotoLikedByCurrentUser:object]];
//  [headerView.likeButton setTitle:[[[PAPCache sharedCache] likeCountForPhoto:object] description] forState:UIControlStateNormal];
//  [headerView.commentButton setTitle:[[[PAPCache sharedCache] commentCountForPhoto:object] description] forState:UIControlStateNormal];
//
//  if (headerView.likeButton.alpha < 1.0f || headerView.commentButton.alpha < 1.0f) {
//  [UIView animateWithDuration:0.200f animations:^{
//  headerView.likeButton.alpha = 1.0f;
//  headerView.commentButton.alpha = 1.0f;
//  }];
//  }
//  }
//  }];
//  }
//  }
//  }

  return headerView;
  }


//  - (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
//  static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
//
//  PAPLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
//  if (!cell) {
//  cell = [[PAPLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
//  cell.selectionStyle =UITableViewCellSelectionStyleNone;
//  cell.hideSeparatorBottom = YES;
//  cell.mainView.backgroundColor = [UIColor clearColor];
//  }
//  return cell;
//  }

  // MARK: FPPhotoTimelineViewController

  func dequeueReusableSectionHeaderView() -> FPPhotoHeaderView? {
    for sectionHeaderView in reusableSectionHeaderViews {
      if ((sectionHeaderView.superview == nil)) {
        // we found a section header that is no longer visible
        return sectionHeaderView
      }
    }
    return nil
  }

  // MARK: PAPPhotoHeaderViewDelegate

  func photoHeaderView(photoHeaderView: FPPhotoHeaderView, didTapUserButton button: UIButton, user: FIRUser) {
//    if let avc = self as? FPAccountViewController {
//      CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
//      anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
//      anim.autoreverses = YES ;
//      anim.repeatCount = 2.0f ;
//      anim.duration = 0.07f ;
//      [self.view.layer addAnimation:anim forKey:nil];
//    } else {
//      PAPAccountViewController *accountViewController = [[PAPAccountViewController alloc] initWithUser:user];
//      [accountViewController setUser:user];
//      self.navigationController.pushViewController(accountViewController, animated:true)
//    }
  }

  func photoHeaderView(photoHeaderView: FPPhotoHeaderView, didTapLikePhotoButton button: UIButton, photo: FDataSnapshot) {
//  [photoHeaderView shouldEnableLikeButton:NO];
//
//  BOOL liked = !button.selected;
//  [photoHeaderView setLikeStatus:liked];
//
//  NSString *originalButtonTitle = button.titleLabel.text;
//
//  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//  [numberFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
//
//  NSNumber *likeCount = [numberFormatter numberFromString:button.titleLabel.text];
//  if (liked) {
//  likeCount = [NSNumber numberWithInt:[likeCount intValue] + 1];
//  [[PAPCache sharedCache] incrementLikerCountForPhoto:photo];
//  } else {
//  if ([likeCount intValue] > 0) {
//  likeCount = [NSNumber numberWithInt:[likeCount intValue] - 1];
//  }
//  [[PAPCache sharedCache] decrementLikerCountForPhoto:photo];
//  }
//
//  [[PAPCache sharedCache] setPhotoIsLikedByCurrentUser:photo liked:liked];
//
//  [button setTitle:[numberFormatter stringFromNumber:likeCount] forState:UIControlStateNormal];
//
//  if (liked) {
//  [PAPUtility likePhotoInBackground:photo block:^(BOOL succeeded, NSError *error) {
//  PAPPhotoHeaderView *actualHeaderView = (PAPPhotoHeaderView *)[self tableView:self.tableView viewForHeaderInSection:button.tag];
//  [actualHeaderView shouldEnableLikeButton:YES];
//  [actualHeaderView setLikeStatus:succeeded];
//
//  if (!succeeded) {
//  [actualHeaderView.likeButton setTitle:originalButtonTitle forState:UIControlStateNormal];
//  }
//  }];
//  } else {
//  [PAPUtility unlikePhotoInBackground:photo block:^(BOOL succeeded, NSError *error) {
//  PAPPhotoHeaderView *actualHeaderView = (PAPPhotoHeaderView *)[self tableView:self.tableView viewForHeaderInSection:button.tag];
//  [actualHeaderView shouldEnableLikeButton:YES];
//  [actualHeaderView setLikeStatus:!succeeded];
//
//  if (!succeeded) {
//  [actualHeaderView.likeButton setTitle:originalButtonTitle forState:UIControlStateNormal];
//  }
//  }];
//  }
  }

//  - (void)photoHeaderView:(PAPPhotoHeaderView *)photoHeaderView didTapCommentOnPhotoButton:(UIButton *)button  photo:(PFObject *)photo {
//  PAPPhotoDetailsViewController *photoDetailsVC = [[PAPPhotoDetailsViewController alloc] initWithPhoto:photo];
//  [self.navigationController pushViewController:photoDetailsVC animated:YES];
//  }
//
//  
//
//  func userFollowingChanged(note: NSNotification) {
//    print("User following changed.")
//    self.shouldReloadOnAppear = true
//  }
//
  func didTapOnPhotoAction(sender: UIButton) {
    let photo = self.objectAtIndex(sender.tag)
    if ((photo) != nil) {
//      FPPhotoDetailsViewController *photoDetailsVC = [[PAPPhotoDetailsViewController alloc] initWithPhoto:photo];
//      [self.navigationController pushViewController:photoDetailsVC animated:YES];

//      photoHeaderView(nil, didTapLikePhotoButton: nil, photo: photo)
    }
  }




}
