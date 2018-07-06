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

class ContactViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {

    // MARK: - UI variables
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    private var collectionView:UICollectionView?
    private var roomVC : RoomViewController?
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
        self.setUpSubViews()
        self.updateNavigationItems()
    }
    override func viewWillAppear(_ animated: Bool) {
        if self.roomVC != nil{
            self.roomVC = nil
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
                case .messageDeleted(let _):
                    break
                }
            }
        }
    }

    // MARK: - Webex Call / Message Function Implementation
    public func callActionTo( _ group: Group){
        let localRoomName = group.groupName
        let localGroupId = group.groupId
        group.unReadedCount = 0
        self.collectionView?.reloadData()
        if let roomModel = User.CurrentUser.findLocalRoomWithId(localGroupId: localGroupId!){
            roomModel.title = localRoomName!
            roomModel.roomMembers = [Contact]()
            for contact in group.groupMembers{
                roomModel.roomMembers?.append(contact)
            }
            self.callVC = BuddiesCallViewController(room: roomModel)
            self.present(self.callVC!, animated: true) {
                self.callVC?.beginCall(isVideo: true)
            }
        }else{
            if(group.groupType == .singleMember){
                let createdRoom = RoomModel(roomId: "")
                createdRoom.localGroupId = group.groupId!
                createdRoom.title = localRoomName!
                createdRoom.type = RoomType.direct
                createdRoom.roomMembers = [Contact]()
                for contact in group.groupMembers{
                    createdRoom.roomMembers?.append(contact)
                }
                User.CurrentUser.insertLocalRoom(room: createdRoom, atIndex: 0)
                self.callVC = BuddiesCallViewController(room: createdRoom)
                self.present(self.callVC!, animated: true) {
                    self.callVC?.beginCall(isVideo: true)
                }
                return
            }
            
            KTActivityIndicator.singleton.show(title: "Loading")
            WebexSDK?.rooms.create(title: localRoomName!, completionHandler: {(response: ServiceResponse<Room>) in
                switch response.result {
                case .success(let value):
                    if let createdRoom = RoomModel(room: value){
                        group.groupId = createdRoom.roomId
                        createdRoom.localGroupId = createdRoom.roomId
                        createdRoom.title = localRoomName
                        createdRoom.type = RoomType.group
                        createdRoom.roomMembers = [Contact]()
                        group.groupId = createdRoom.roomId
                        let threahGroup = DispatchGroup()
                        for contact in group.groupMembers{
                            DispatchQueue.global().async(group: threahGroup, execute: DispatchWorkItem(block: {
                                WebexSDK?.memberships.create(roomId: createdRoom.roomId, personEmail:EmailAddress.fromString(contact.email)!, completionHandler: { (response: ServiceResponse<Membership>) in
                                    switch response.result{
                                    case .success(_):
                                        createdRoom.roomMembers?.append(contact)
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
                                User.CurrentUser.insertLocalRoom(room: createdRoom, atIndex: 0)
                                self.callVC = BuddiesCallViewController(room: createdRoom)
                                self.present(self.callVC!, animated: true) {
                                    self.callVC?.beginCall(isVideo: true)
                                }
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
    
    public func messageActionTo(_ group: Group){
        let localRoomName = group.groupName
        let localGroupId = group.groupId
        group.unReadedCount = 0
        self.collectionView?.reloadData()
        if let roomModel = User.CurrentUser.findLocalRoomWithId(localGroupId: localGroupId!){
            roomModel.title = localRoomName!
            roomModel.roomMembers = [Contact]()
            for contact in group.groupMembers{
                roomModel.roomMembers?.append(contact)
            }
            self.roomVC = RoomViewController(room: roomModel)
            self.navigationController?.pushViewController(self.roomVC!, animated: true)
        }else{
            if(group.groupType == .singleMember){
                let createdRoom = RoomModel(roomId: "")
                createdRoom.localGroupId = group.groupId!
                createdRoom.title = localRoomName!
                createdRoom.type = RoomType.direct
                createdRoom.roomMembers = [Contact]()
                for contact in group.groupMembers{
                    createdRoom.roomMembers?.append(contact)
                }
                User.CurrentUser.insertLocalRoom(room: createdRoom, atIndex: 0)
                self.roomVC = RoomViewController(room: createdRoom)
                self.navigationController?.pushViewController(self.roomVC!, animated: true)
                return
            }
            
            KTActivityIndicator.singleton.show(title: "Loading")
            WebexSDK?.rooms.create(title: localRoomName!, completionHandler: {(response: ServiceResponse<Room>) in
                switch response.result {
                case .success(let value):
                    if let createdRoom = RoomModel(room: value){
                        group.groupId = createdRoom.roomId
                        createdRoom.localGroupId = createdRoom.roomId
                        createdRoom.title = localRoomName
                        createdRoom.type = RoomType.group
                        createdRoom.roomMembers = [Contact]()
                        group.groupId = createdRoom.roomId
                        let threahGroup = DispatchGroup()
                        for contact in group.groupMembers{
                            DispatchQueue.global().async(group: threahGroup, execute: DispatchWorkItem(block: {
                                WebexSDK?.memberships.create(roomId: createdRoom.roomId, personEmail:EmailAddress.fromString(contact.email)!, completionHandler: { (response: ServiceResponse<Membership>) in
                                    switch response.result{
                                    case .success(_):
                                        createdRoom.roomMembers?.append(contact)
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
                                User.CurrentUser.insertLocalRoom(room: createdRoom, atIndex: 0)
                                self.roomVC = RoomViewController(room: createdRoom)
                                self.navigationController?.pushViewController(self.roomVC!, animated: true)
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
        if messageModel.roomType == RoomType.direct{//GROUP
            if let roomVC = self.roomVC, let roomModel = self.roomVC?.roomModel{
                if messageModel.personEmail == roomModel.localGroupId{
                    roomVC.receiveNewMessage(message: messageModel)
                    return
                }
            }else{
                if let group = User.CurrentUser.getSingleGroupWithContactEmail(email: messageModel.personEmail!){
                    group.unReadedCount += 1
                    self.collectionView?.reloadData()
                }
            }
            if let callVC = self.callVC, let roomModel = self.callVC?.roomModel{
                if messageModel.personEmail?.md5 == roomModel.localGroupId{
                    callVC.receiveNewMessage(message: messageModel)
                    return
                }
            }
        }else{
            if let roomVC = self.roomVC, let roomModel = self.roomVC?.roomModel{
                if messageModel.roomId == roomModel.roomId && messageModel.personEmail != User.CurrentUser.email{
                    roomVC.receiveNewMessage(message: messageModel)
                    return
                }
            }else{
                if let group = User.CurrentUser[messageModel.roomId!]{
                    group.unReadedCount += 1
                    self.collectionView?.reloadData()
                }
            }
            if let callVC = self.callVC, let roomModel = self.callVC?.roomModel{
                if messageModel.personEmail?.md5 == roomModel.localGroupId{
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
    
    private func updateNavigationItems() {
        var avator: UIImageView?
        if (User.CurrentUser.loginType == .User) { // UserLogin
            avator = User.CurrentUser.avator
            if let avator = avator {
                avator.setCorner(Int(avator.frame.height / 2))
            }
            if self.isEditMode {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitEditMode(sender:)))
            }
            else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addContactBtnClicked(sender:)))
            }
        } else {
            avator = UIImageView(frame: CGRect(0, 0, 28, 28))
            avator?.image = UIImage.fontAwesomeIcon(name: .userCircleO, textColor: UIColor.white, size: CGSize(width: 28, height: 28))
            self.navigationItem.rightBarButtonItem = nil
        }
        
        
        if let avator = avator {
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(showUserOptionView))
            singleTap.numberOfTapsRequired = 1;
            avator.isUserInteractionEnabled = true
            avator.addGestureRecognizer(singleTap)
            let widthConstraint = avator.widthAnchor.constraint(equalToConstant: 28)
            let heightConstraint = avator.heightAnchor.constraint(equalToConstant: 28)
            widthConstraint.isActive = true
            heightConstraint.isActive = true
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avator)
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
    
    @objc private func showUserOptionView() {
        self.mainController?.slideInUserOptionView()
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
        let cell:GroupCollcetionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCollcetionViewCell;
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

