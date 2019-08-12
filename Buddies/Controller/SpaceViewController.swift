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
import WebexSDK
import ObjectMapper
import Cartography
import Photos
class SpaceViewController: BaseViewController,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate {
    
    // MARK: UI variables
    private var messageTableView: UITableView?
    public var spaceModel: SpaceModel
    private var spaceMemberTableView: UITableView?
    private var maskView: UIView?
    private var messageList: [BDSMessage] = []
    private let messageTableViewHeight = Constants.Size.navHeight > 64 ? (Constants.Size.screenHeight-Constants.Size.navHeight-74) : (Constants.Size.screenHeight-Constants.Size.navHeight-40)
    private var tableTap: UIGestureRecognizer?
    private var topIndicator: UIActivityIndicatorView?
    private var navigationTitleLabel: UILabel?
    private var buddiesInputView : BuddiesInputView?
    private var callVC : BuddiesCallViewController?

    // MARK: - Life Circle
    init(space: SpaceModel){
        self.spaceModel = space
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpTopNavigationView()
        self.setUpMessageTableView()
        if self.spaceModel.type == SpaceType.group, self.spaceModel.spaceMembers.isEmpty {
            self.requestRoomMembers()
        }
        else {
            self.requestMessageData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.callVC = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let buddiesInputView = self.buddiesInputView{
            buddiesInputView.selectedAssetCollectionView?.removeFromSuperview()
        }
    }
    
    func requestRoomMembers(){
        self.topIndicator?.startAnimating()
        WebexSDK?.memberships.list(spaceId: self.spaceModel.spaceId) { (response: ServiceResponse<[Membership]>) in
            switch response.result {
            case .success(let value):
                let threahSpace = DispatchGroup()
                let members = value.filter({!($0.personEmail?.toString().contains("bot@cisco.com"))!})
                members.forEach{ membership in
                    DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
                        WebexSDK?.people.get(personId: membership.personId!, completionHandler: { (response: ServiceResponse<Person>) in
                            if let person = response.result.data {
                                let contact = Contact(person: person)
                                self.spaceModel.spaceMembers.append(contact!)
                            }
                        })
                    }))
                }
                threahSpace.notify(queue: DispatchQueue.global(), execute: {
                    DispatchQueue.main.async {
                        self.requestMessageData()
                    }
                })
                break
            case .failure:
                self.topIndicator?.stopAnimating()
                self.updateSupViews()
                break
            }
        }
    }
    
    func requestMessageData(){
        if User.CurrentUser.phoneRegisterd{
            self.requestMessageList()
        }else{
            WebexSDK?.phone.register({ (error) in
                if error == nil{
                    self.requestMessageList()
                }
            })
        }
    }
    
    // MARK: - WebexSDK: listing member in a space
    func requestMessageList(){
        self.topIndicator?.startAnimating()
        if self.spaceModel.spaceId != "" {
            WebexSDK?.messages.list(spaceId: self.spaceModel.spaceId, before: nil, max: 50, mentionedPeople: nil, queue: nil, completionHandler: { (response: ServiceResponse<[Message]>) in
                self.topIndicator?.stopAnimating()
                self.updateSupViews()
                switch response.result {
                case .success(let value):
                    self.messageList.removeAll()
                    for message in value{
                        let tempMessage = BDSMessage(messageModel: message)
                        if let idx = self.spaceModel.spaceMembers.firstIndex(where: {$0.id == message.personId}) {
                            tempMessage?.avator = self.spaceModel.spaceMembers[idx].avatorUrl
                        }
                        tempMessage?.localSpaceId = self.spaceModel.localSpaceId
                        tempMessage?.messageState = MessageState.received
                        self.messageList.insert(tempMessage!, at: 0)
                    }
                    self.messageTableView?.reloadData()
                    let indexPath = IndexPath(row: self.messageList.count-1, section: 0)
                    if self.messageList.count != 0{
                        _ = self.messageTableView?.cellForRow(at: indexPath)
                        self.messageTableView?.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    }
                    break
                case .failure:
                    break
                }
            })
        }else{
            self.topIndicator?.stopAnimating()
            self.updateSupViews()
        }
    }
    
    // MARK: - WebexSDK: post message | make call to a space
    func sendMessage(text: String, _ assetList:[BDAssetModel]? = nil , _ mentionList:[Contact]? = nil, _ menpositions:[Range<Int>]){
        let tempMessageModel = BDSMessage()
        tempMessageModel.spaceId = self.spaceModel.spaceId
        tempMessageModel.messageState = MessageState.willSend
        tempMessageModel.text = text
        if self.spaceModel.type == SpaceType.direct {
            if let buddy = self.spaceModel.contact {
                let personEmail = buddy.email
                let personId = buddy.id
                tempMessageModel.toPersonEmail = EmailAddress.fromString(personEmail)
                tempMessageModel.toPersonId = personId
            }
        }
        tempMessageModel.personId = User.CurrentUser.id
        tempMessageModel.personEmail = EmailAddress.fromString(User.CurrentUser.email)
        tempMessageModel.localSpaceId = self.spaceModel.localSpaceId
        if let mentions = mentionList, mentions.count>0{
            var mentionModels : [Mention] = []
            for mention in mentions{
                if mention.name == "All"{
                    mentionModels.append(Mention.all)
                }else{
                    mentionModels.append(Mention.person(mention.id))
                }
            }
            tempMessageModel.mentionList = mentionModels
            tempMessageModel.text = String.processMentionString(contentStr: text, mentions: mentionModels, mentionsArr: menpositions)
        }
        if let models = assetList, models.count>0{
            var files : [LocalFile] = []
            tempMessageModel.fileNames = []
            let manager = PHImageManager.default()
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var loadedCount = 0
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat
            for index in 0..<models.count{
                let asset = models[index].asset
                manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth/4, height: asset.pixelHeight/4), contentMode: .aspectFill, options: requestOptions) { (result, info) in
                    let date : Date = Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMddyyyy:hhmmSSS"
                    let todaysDate = dateFormatter.string(from: date)
                    let name = "Image-" + todaysDate + ".jpg"
                    let destinationPath = documentsPath + "/" + name
                    loadedCount += 1
                    if let data = result!.jpegData(compressionQuality: 1.0){
                        do{
                            try data.write(to: URL(fileURLWithPath: destinationPath))
                            let thumbFile = LocalFile.Thumbnail(path: destinationPath, mime: "image/png", width: Int((result?.size.width)!), height: Int((result?.size.height)!))
                            let file = LocalFile(path: destinationPath, name: name, mime: "image/png", thumbnail: thumbFile, progressHandler: nil)
                            files.append(file!)
                            tempMessageModel.fileNames?.append(name)
                            if loadedCount == models.count{
                                tempMessageModel.localFiles = files
                                self.postMessage(message: tempMessageModel)
                            }
                        }catch let error as NSError{
                            print("Write File Error:" + error.description)
                        }
                    }
                }
            }
        }else{
            self.postMessage(message: tempMessageModel)
        }
        return
    }
    func postMessage(message: BDSMessage){
        self.messageList.append(message)
        let indexPath = IndexPath(row: self.messageList.count-1, section: 0)
        self.messageTableView?.reloadData()
        _ = self.messageTableView?.cellForRow(at: indexPath)
        self.messageTableView?.scrollToRow(at: indexPath, at: .bottom, animated: false)
        self.buddiesInputView?.inputTextView?.text = ""
    }
    
    func makeCall(isVideo: Bool){
        self.callVC = BuddiesCallViewController(space: self.spaceModel)
        self.present(self.callVC!, animated: true) {
            self.callVC?.beginCall(isVideo: isVideo)
        }
    }
    
    // MARK: - WebexSDK: receive a new message
    public func receiveNewMessage(message: Message){
        if let _ = self.messageList.filter({$0.messageId == message.id}).first{
            return
        }
        if let callVc = self.callVC{
            callVc.receiveNewMessage(message: message)
            return
        }
        let msgModel = BDSMessage(messageModel: message)
        msgModel?.messageState = MessageState.received
        msgModel?.localSpaceId = self.spaceModel.localSpaceId
        if let idx = self.spaceModel.spaceMembers.firstIndex(where: {$0.id == message.personId}) {
            msgModel?.avator = self.spaceModel.spaceMembers[idx].avatorUrl
        }
        if(msgModel?.text == nil){
            msgModel?.text = ""
        }
        self.messageList.append(msgModel!)
        let indexPath = IndexPath(row: self.messageList.count-1, section: 0)
        self.messageTableView?.reloadData()
        _ = self.messageTableView?.cellForRow(at: indexPath)
        self.messageTableView?.scrollToRow(at: indexPath, at: .bottom, animated: false)

    }
    
    // MARK: - UI Implementation
    private func setUpTopNavigationView(){
        if(self.navigationTitleLabel == nil){
            self.navigationTitleLabel = UILabel(frame: CGRect(0,0,Constants.Size.screenWidth-80,20))
            self.navigationTitleLabel?.font = Constants.Font.NavigationBar.Title
            self.navigationTitleLabel?.textColor = UIColor.white
            self.navigationTitleLabel?.textAlignment = .center
            self.navigationItem.titleView = self.navigationTitleLabel
            self.topIndicator = UIActivityIndicatorView(style: .white)
            self.topIndicator?.hidesWhenStopped = true
            self.navigationTitleLabel?.addSubview(self.topIndicator!)
            self.topIndicator?.center = CGPoint((self.navigationTitleLabel?.center.x)!-20, 15)
        }
    }
    
    private func updateSupViews(){
        self.updateNavigationTitle()
        self.updateBarItem()
        self.setUpBottomView()
    }
    
    private func updateBarItem() {
        var avator: UIImageView?
        if (User.CurrentUser.loginType != .None) {
            avator = User.CurrentUser.avator
            if let avator = avator {
                avator.setCorner(Int(avator.frame.height / 2))
            }
            if self.spaceModel.type == SpaceType.group {
                let membersBtnItem = UIBarButtonItem(image: UIImage(named: "icon_members"), style: .plain, target: self, action: #selector(membersBtnClicked))
                self.navigationItem.rightBarButtonItem = membersBtnItem
            }
        }
    }
    private func setUpMessageTableView(){
        if(self.messageTableView == nil){
            self.messageTableView = UITableView(frame: CGRect(0,0,Int(Constants.Size.screenWidth),Int(messageTableViewHeight)))
            self.messageTableView?.separatorStyle = .none
            self.messageTableView?.backgroundColor = Constants.Color.Theme.Background
            self.messageTableView?.delegate = self
            self.messageTableView?.dataSource = self
            self.messageTableView?.alwaysBounceVertical = true
            self.messageTableView?.showsVerticalScrollIndicator = false
            self.view.addSubview(self.messageTableView!)
        }
    }
    
    private func setUpBottomView(){
        let bottomViewWidth = Constants.Size.screenWidth
        self.buddiesInputView = BuddiesInputView(frame: CGRect(x: 0, y: messageTableViewHeight, width: bottomViewWidth, height: 40) , tableView: self.messageTableView!, contacts: self.spaceModel.spaceMembers, navController: self.navigationController)
        self.buddiesInputView?.sendBtnClickBlock = { (textStr: String, assetList:[BDAssetModel]?, mentionList:[Contact]?,mentionPositions: [Range<Int>]) in
            self.sendMessage(text: textStr, assetList, mentionList,mentionPositions)
        }
        self.buddiesInputView?.videoCallBtnClickedBlock = {
            self.makeCall(isVideo: true)
        }
        self.buddiesInputView?.audioCallBtnClickedBlock = {
            self.makeCall(isVideo: false)
        }
        self.view.addSubview(self.buddiesInputView!)
    }
    
    private func setUpMembertableView(){
        if(self.spaceMemberTableView == nil){
            let offSetY : CGFloat = Constants.Size.screenWidth > 375 ? 20.0 : 64.0
            self.spaceMemberTableView = UITableView(frame: CGRect(Constants.Size.screenWidth,-offSetY,Constants.Size.screenWidth/4*3,Constants.Size.screenHeight+offSetY))
            self.spaceMemberTableView?.separatorStyle = .none
            self.spaceMemberTableView?.backgroundColor = Constants.Color.Theme.Background
            self.spaceMemberTableView?.delegate = self
            self.spaceMemberTableView?.dataSource = self
        }
    }
    
    private func setUpMaskView(){
        if(self.maskView == nil){
            self.maskView = UIView(frame: CGRect.zero)
            self.maskView?.frame = CGRect(x: 0, y: 0, width: Constants.Size.screenWidth, height: Constants.Size.screenHeight)
            self.maskView?.backgroundColor = UIColor.black
            self.maskView?.alpha = 0
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMemberTableView))
            self.maskView?.addGestureRecognizer(tap)
        }
    }
    
    @objc private func membersBtnClicked(){
        self.buddiesInputView?.inputTextView?.resignFirstResponder()
        self.slideMembersTableView()
    }
    
    @objc public func slideMembersTableView() {
        self.setUpMaskView()
        self.setUpMembertableView()
        self.navigationController?.view.addSubview(self.maskView!)
        self.navigationController?.view.addSubview(self.spaceMemberTableView!)
        
        UIView.animate(withDuration: 0.2, animations: { 
            self.spaceMemberTableView?.transform = CGAffineTransform(translationX: -Constants.Size.screenWidth/4*3, y: 0)
            self.maskView?.alpha = 0.4
        }) { (_) in
            self.spaceMemberTableView?.reloadData()
        }
        
    }
    @objc public func dismissMemberTableView(){
        UIView.animate(withDuration: 0.2, animations: {
            self.spaceMemberTableView?.transform = CGAffineTransform(translationX:0, y: 0)
            self.maskView?.alpha = 0
        }) { (complete) in
            self.maskView?.removeFromSuperview()
            self.spaceMemberTableView?.removeFromSuperview()
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == self.spaceMemberTableView){
            return CGFloat(membershipTableCellHeight)
        }else{
            var fileCount = 0
            var imageCount = 0
            if let localFiles = self.messageList[indexPath.row].localFiles {
                imageCount = localFiles.filter({$0.mime.contains("image/")}).count
                fileCount = localFiles.count - imageCount
            }
            else if let remoteFiles = self.messageList[indexPath.row].remoteFiles {
                imageCount = remoteFiles.filter({($0.mimeType?.contains("image/"))!}).count
                fileCount = remoteFiles.count - imageCount
            }
            var attrText : NSAttributedString = NSAttributedString.init(string: "")
            if let text = self.messageList[indexPath.row].text, text.count > 0 {
                 attrText = MessageParser.sharedInstance().translate(toAttributedString: text)
            }
            let cellHeight = MessageTableCell.getCellHeight(attrText: attrText, imageCount: imageCount, fileCount: fileCount)
            return cellHeight
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == self.spaceMemberTableView){
            return self.spaceModel.spaceMembers.count
        }else{
            return self.messageList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == self.spaceMemberTableView){
            let index = indexPath.row
            let memberModel = self.spaceModel.spaceMembers[index]
            var reuseCell = tableView.dequeueReusableCell(withIdentifier: "PeopleListTableCell")
            if reuseCell != nil{
                (reuseCell as! PeopleListTableCell).updateMembershipCell(membershipContact: memberModel)
            }else{
                reuseCell = PeopleListTableCell(membershipContact: memberModel)
            }
            return reuseCell!
        }else{
            let index = indexPath.row
            let message = self.messageList[index]
            var reuseCell = tableView.dequeueReusableCell(withIdentifier: "MessageTabelCell")
            if reuseCell == nil{
                reuseCell = MessageTableCell(message: message)
            }
            return reuseCell!
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(tableView == self.spaceMemberTableView){
            return 64
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(tableView == self.spaceMemberTableView){
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Size.screenWidth/4*3, height: 64))
            headerView.backgroundColor = Constants.Color.Theme.Main
            let label = UILabel(frame: CGRect(x: 0, y: 20, width: headerView.frame.size.width, height: headerView.frame.size.height-20))
            label.text = "Members"
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.font = Constants.Font.NavigationBar.Title
            headerView.addSubview(label)
            return headerView
        }else{
            return nil
        }

    }
    
    // MARK: - Other Functions
    private func updateNavigationTitle(){
        self.navigationTitleLabel?.text = self.spaceModel.title != nil ? self.spaceModel.title! : "No Name"
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
