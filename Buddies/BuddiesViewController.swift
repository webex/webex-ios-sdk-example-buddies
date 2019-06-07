// Copyright 2016-2019 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Cartography
import FontAwesome_swift
import WebexSDK

class BuddiesViewController: HomeViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {

    // MARK: - UI variables
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    private var collectionView:UICollectionView?
    private var spaceVC : SpaceViewController?
    private var callVC : BuddiesCallViewController?
    private var isEditMode = false {
        didSet {
            self.updateNavigationItems()
            self.collectionView?.reloadData()
        }
    }
    
    override init(mainViewController: MainViewController) {
        super.init(mainViewController : mainViewController)
    }
    
    // MARK: - Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Buddies"
        self.updateNavigationItems()
        self.setUpSubViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.spaceVC = nil
    }

    // MARK: - Webex Call / Message Function Implementation
    public func callActionTo( _ spaceModel: SpaceModel){
        spaceModel.unReadedCount = 0
        self.collectionView?.reloadData()
        self.callVC = BuddiesCallViewController(space: spaceModel)
        self.present(self.callVC!, animated: true) {
            self.callVC?.beginCall(isVideo: true)
        }
    }
    
    public func messageActionTo(_ spaceModel: SpaceModel){
        spaceModel.unReadedCount = 0
        self.collectionView?.reloadData()
        self.spaceVC = SpaceViewController(space: spaceModel)
        self.navigationController?.pushViewController(self.spaceVC!, animated: true)
    }
    
    public func receiveNewMessage( _ messageModel: Message){
        if let spaceVC = self.spaceVC, let spaceModel = self.spaceVC?.spaceModel{
            if messageModel.personEmail == spaceModel.localSpaceId{
                spaceVC.receiveNewMessage(message: messageModel)
                return
            } else{
                if let space = User.CurrentUser[messageModel.personEmail!]{
                    space.unReadedCount += 1
                    self.collectionView?.reloadData()
                }
            }
        }
        else if let callVC = self.callVC, let spaceModel = self.callVC?.spaceModel{
            if messageModel.personEmail == spaceModel.localSpaceId{
                callVC.receiveNewMessage(message: messageModel)
                return
            } else{
                if let space = User.CurrentUser[messageModel.personEmail!]{
                    space.unReadedCount += 1
                    self.collectionView?.reloadData()
                }
            }
        }
        else{
            if let space = User.CurrentUser[messageModel.personEmail!]{
                space.unReadedCount += 1
                self.collectionView?.reloadData()
            }
        }
    }

    // MARK: - UI Implementation
    private func setUpSubViews(){
        let layout = UICollectionViewFlowLayout();
        layout.scrollDirection = UICollectionViewScrollDirection.vertical;
        layout.minimumLineSpacing = 30;
        layout.minimumInteritemSpacing = 30;
        layout.sectionInset = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30);
        
        self.collectionView = UICollectionView(frame:CGRect.zero, collectionViewLayout: layout);
        self.collectionView?.register(SpaceCollcetionViewCell.self, forCellWithReuseIdentifier: "SpaceCell");
        self.collectionView?.delegate = self;
        self.collectionView?.dataSource = self;
        self.collectionView?.backgroundColor = Constants.Color.Theme.Background;
        self.collectionView?.allowsMultipleSelection = true
        self.collectionView?.alwaysBounceVertical = true
        self.view.addSubview(self.collectionView!);
        
        constrain(self.collectionView!) { view in
            view.height == view.superview!.height;
            view.width == view.superview!.width;
            view.bottom == view.superview!.bottom;
            view.left == view.superview!.left;
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = 0.5
        self.collectionView?.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func addContactBtnClicked(sender: UIBarButtonItem) {
        let peopleListVC = PeopleListViewController(pageType: .People)
        peopleListVC.completionHandler = { dataChanged in
            if(dataChanged){
                self.collectionView?.reloadData()
            }
        }
        let peopleNavVC = UINavigationController(rootViewController: peopleListVC)
        self.navigationController?.present(peopleNavVC, animated: true, completion: {
            
        })
    }
    
    @objc private func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state == .began {
            let p = gesture.location(in: self.collectionView)
            if let indexPath = self.collectionView?.indexPathForItem(at: p), let _: SpaceCollcetionViewCell = self.collectionView?.cellForItem(at: indexPath) as? SpaceCollcetionViewCell {
                self.isEditMode = true
            }
        }
    }
    
    @objc private func exitEditMode(sender: UIBarButtonItem) {
        self.isEditMode = false
    }
    
    // MARK: - BaseViewController Functions Override
    override func updateViewController() {
        self.updateNavigationItems()
        self.collectionView?.reloadData()
    }
    
    override func updateNavigationItems() {
        super.updateNavigationItems()
        if (User.CurrentUser.loginType == .User) {
            if self.isEditMode {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitEditMode(sender:)))
            }
            else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addContactBtnClicked(sender:)))
            }
        }
    }
    
    // MARK: - CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(140, 140);
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(User.CurrentUser.loginType == .Guest){
            return 0
        }
        return User.CurrentUser.spaceCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SpaceCollcetionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpaceCell", for: indexPath) as! SpaceCollcetionViewCell;
        cell.reset()
        if let space = User.CurrentUser[indexPath.item] {
            cell.setSpace(space)
            if self.isEditMode {
                cell.onDelete = { spaceId in
                    if let spaceIdStr = spaceId {
                        PopupOptionView.show(spaceModel: space, action: "Delete", dismissHandler: {
                            User.CurrentUser.removeSpace(spaceId: spaceIdStr)
                            self.collectionView?.reloadData()
                        })
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell: SpaceCollcetionViewCell = collectionView.cellForItem(at: indexPath) as? SpaceCollcetionViewCell, !self.isEditMode {
            self.collectionView?.deselectItem(at: indexPath, animated: false)
            if let space = cell.spaceModel {
                PopupOptionView.buddyOptionPopUp(spaceModel: space) { (action: String) in
                    if(action == "Call"){
                        self.callActionTo(space)
                    }else if(action == "Message"){
                        self.messageActionTo(space)
                    }
                }
            }
        }
    }
    
    // MARK: - Other Functions
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

