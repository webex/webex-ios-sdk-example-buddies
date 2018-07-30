// Copyright 2016-2017 Cisco Systems Inc
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
        if self.spaceVC != nil{
            self.spaceVC = nil
        }
    }
    
    // MARK: - WebexSDK: Phone Register And Setup Message-Receive Call Back
    public func checkWebexRegister(){
        if(User.CurrentUser.phoneRegisterd){
            WebexSDK?.messages.onEvent = { event in
                switch event{
                case .messageReceived(let message):
                    self.receiveNewMessage(message)
                    break
                case .messageDeleted(_):
                    break
                }
            }
        }
    }

    // MARK: - Webex Call / Message Function Implementation
    public func callActionTo( _ group: Group){
        let localSpaceName = group.groupName
        let localGroupId = group.groupId
        group.unReadedCount = 0
        self.collectionView?.reloadData()
        if let spaceModel = User.CurrentUser.findLocalSpaceWithId(localGroupId: localGroupId!){
            spaceModel.title = localSpaceName!
            spaceModel.spaceMembers = [Contact]()
            for contact in group.groupMembers{
                spaceModel.spaceMembers?.append(contact)
            }
            self.callVC = BuddiesCallViewController(space: spaceModel)
            self.present(self.callVC!, animated: true) {
                self.callVC?.beginCall(isVideo: true)
            }
        }else{
            if(group.groupType == .singleMember){
                let createdSpace = SpaceModel(spaceId: "")
                createdSpace.localGroupId = group.groupId!
                createdSpace.title = localSpaceName!
                createdSpace.type = SpaceType.direct
                createdSpace.spaceMembers = [Contact]()
                for contact in group.groupMembers{
                    createdSpace.spaceMembers?.append(contact)
                }
                User.CurrentUser.insertLocalSpace(space: createdSpace, atIndex: 0)
                self.callVC = BuddiesCallViewController(space: createdSpace)
                self.present(self.callVC!, animated: true) {
                    self.callVC?.beginCall(isVideo: true)
                }
                return
            }
            
            acitivtyIndicator.show(title: "Loading...", at: (self.view)!, offset: 0, size: 156, allowUserInteraction: false)
            WebexSDK?.spaces.create(title: localSpaceName!, completionHandler: {(response: ServiceResponse<Space>) in
                switch response.result {
                case .success(let value):
                    if let createdSpace = SpaceModel(space: value){
                        group.groupId = createdSpace.spaceId
                        createdSpace.localGroupId = createdSpace.spaceId
                        createdSpace.title = localSpaceName
                        createdSpace.type = SpaceType.group
                        createdSpace.spaceMembers = [Contact]()
                        group.groupId = createdSpace.spaceId
                        let threahGroup = DispatchGroup()
                        for contact in group.groupMembers{
                            DispatchQueue.global().async(group: threahGroup, execute: DispatchWorkItem(block: {
                                WebexSDK?.memberships.create(spaceId: createdSpace.spaceId, personEmail:EmailAddress.fromString(contact.email)!, completionHandler: { (response: ServiceResponse<Membership>) in
                                    switch response.result{
                                    case .success(_):
                                        createdSpace.spaceMembers?.append(contact)
                                        break
                                    case .failure(let error):
                                        KTInputBox.alert(error: error)
                                        break
                                    }
                                })
                            }))
                        }
                        
                        threahGroup.notify(queue: DispatchQueue.global(), execute: {
                            DispatchQueue.main.async {
                                self.acitivtyIndicator.hide()
                                User.CurrentUser.insertLocalSpace(space: createdSpace, atIndex: 0)
                                self.callVC = BuddiesCallViewController(space: createdSpace)
                                self.present(self.callVC!, animated: true) {
                                    self.callVC?.beginCall(isVideo: true)
                                }
                            }
                        })
                    }
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.acitivtyIndicator.hide()
                        KTInputBox.alert(error: error)
                    }
                    break
                }
            })
        }
    }
    
    public func messageActionTo(_ group: Group){
        let localSpaceName = group.groupName
        let localGroupId = group.groupId
        group.unReadedCount = 0
        self.collectionView?.reloadData()
        if let spaceModel = User.CurrentUser.findLocalSpaceWithId(localGroupId: localGroupId!){
            spaceModel.title = localSpaceName!
            spaceModel.spaceMembers = [Contact]()
            for contact in group.groupMembers{
                spaceModel.spaceMembers?.append(contact)
            }
            self.spaceVC = SpaceViewController(space: spaceModel)
            self.navigationController?.pushViewController(self.spaceVC!, animated: true)
        }else{
            if(group.groupType == .singleMember){
                let createdSpace = SpaceModel(spaceId: "")
                createdSpace.localGroupId = group.groupId!
                createdSpace.title = localSpaceName!
                createdSpace.type = SpaceType.direct
                createdSpace.spaceMembers = [Contact]()
                for contact in group.groupMembers{
                    createdSpace.spaceMembers?.append(contact)
                }
                User.CurrentUser.insertLocalSpace(space: createdSpace, atIndex: 0)
                self.spaceVC = SpaceViewController(space: createdSpace)
                self.navigationController?.pushViewController(self.spaceVC!, animated: true)
                return
            }
            
            KTActivityIndicator.singleton.show(title: "Loading")
            WebexSDK?.spaces.create(title: localSpaceName!, completionHandler: {(response: ServiceResponse<Space>) in
                switch response.result {
                case .success(let value):
                    if let createdSpace = SpaceModel(space: value){
                        group.groupId = createdSpace.spaceId
                        createdSpace.localGroupId = createdSpace.spaceId
                        createdSpace.title = localSpaceName
                        createdSpace.type = SpaceType.group
                        createdSpace.spaceMembers = [Contact]()
                        group.groupId = createdSpace.spaceId
                        let threahGroup = DispatchGroup()
                        for contact in group.groupMembers{
                            DispatchQueue.global().async(group: threahGroup, execute: DispatchWorkItem(block: {
                                WebexSDK?.memberships.create(spaceId: createdSpace.spaceId, personEmail:EmailAddress.fromString(contact.email)!, completionHandler: { (response: ServiceResponse<Membership>) in
                                    switch response.result{
                                    case .success(_):
                                        createdSpace.spaceMembers?.append(contact)
                                        break
                                    case .failure(let error):
                                        KTInputBox.alert(error: error)
                                        break
                                    }
                                })
                            }))
                        }
                        
                        threahGroup.notify(queue: DispatchQueue.global(), execute: {
                            DispatchQueue.main.async {
                                KTActivityIndicator.singleton.hide()
                                User.CurrentUser.insertLocalSpace(space: createdSpace, atIndex: 0)
                                self.spaceVC = SpaceViewController(space: createdSpace)
                                self.navigationController?.pushViewController(self.spaceVC!, animated: true)
                            }
                        })
                    }
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        KTActivityIndicator.singleton.hide()
                        KTInputBox.alert(error: error)
                    }
                    break
                }
            })
        }
    }
    
    public func receiveNewMessage( _ messageModel: Message){
        if messageModel.spaceType == SpaceType.direct{//GROUP
            if let spaceVC = self.spaceVC, let spaceModel = self.spaceVC?.spaceModel{
                if messageModel.personEmail == spaceModel.localGroupId{
                    spaceVC.receiveNewMessage(message: messageModel)
                    return
                }
            }else{
                if let group = User.CurrentUser.getSingleGroupWithContactEmail(email: messageModel.personEmail!){
                    group.unReadedCount += 1
                    self.collectionView?.reloadData()
                }
            }
            if let callVC = self.callVC, let spaceModel = self.callVC?.spaceModel{
                if messageModel.personEmail?.md5 == spaceModel.localGroupId{
                    callVC.receiveNewMessage(message: messageModel)
                    return
                }
            }
        }else{
            if let spaceVC = self.spaceVC, let spaceModel = self.spaceVC?.spaceModel{
                if messageModel.spaceId == spaceModel.spaceId && messageModel.personEmail != User.CurrentUser.email{
                    spaceVC.receiveNewMessage(message: messageModel)
                    return
                }
            }else{
                if let group = User.CurrentUser[messageModel.spaceId!]{
                    group.unReadedCount += 1
                    self.collectionView?.reloadData()
                }
            }
            if let callVC = self.callVC, let spaceModel = self.callVC?.spaceModel{
                if messageModel.personEmail?.md5 == spaceModel.localGroupId{
                    callVC.receiveNewMessage(message: messageModel)
                    return
                }
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
        self.collectionView?.register(GroupCollcetionViewCell.self, forCellWithReuseIdentifier: "GroupCell");
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
    
    override func updateNavigationItems() {
        super.updateNavigationItems()
        if (User.CurrentUser.loginType == .User) { // UserLogin
            if self.isEditMode {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitEditMode(sender:)))
            }
            else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addContactBtnClicked(sender:)))
            }
        }
    }
    
    // MARK: UI Logic Implementation
    @objc private func addContactBtnClicked(sender: UIBarButtonItem) {
        let peopleListVC = PeopleListViewController()
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
            if let indexPath = self.collectionView?.indexPathForItem(at: p), let _: GroupCollcetionViewCell = self.collectionView?.cellForItem(at: indexPath) as? GroupCollcetionViewCell {
                self.isEditMode = true
            }
        }
    }
    
    @objc private func exitEditMode(sender: UIBarButtonItem) {
        self.isEditMode = false
    }
    
    // MARK: BaseViewController Functions Override
    override func updateViewController() {
        self.checkWebexRegister()
        self.updateNavigationItems()
        self.collectionView?.reloadData()
    }
    
    // MARK: CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(140, 140);
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(User.CurrentUser.loginType == .Guest){
            return 0
        }
        return User.CurrentUser.groupCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GroupCollcetionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCollcetionViewCell;
        cell.reset()
        if let group = User.CurrentUser[indexPath.item] {
            cell.setGroup(group)
            if self.isEditMode {
                cell.onDelete = { groupId in
                    if let groupIdStr = groupId {
                        PopupOptionView.show(group: group, action: "Delete", dismissHandler: {
                            User.CurrentUser.removeGroup(groupId: groupIdStr)
                            self.collectionView?.reloadData()
                        })
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell: GroupCollcetionViewCell = collectionView.cellForItem(at: indexPath) as? GroupCollcetionViewCell, !self.isEditMode {
            self.collectionView?.deselectItem(at: indexPath, animated: false)
            if let group = cell.groupModel {
                PopupOptionView.buddyOptionPopUp(groupModel: group) { (action: String) in
                    if(action == "Call"){
                        self.callActionTo(group)
                    }else if(action == "Message"){
                        self.messageActionTo(group)
                    }
                }
            }
        }
    }
    
    // MARK: Other Functions
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

