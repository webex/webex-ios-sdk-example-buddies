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
import WebexSDK
import ObjectMapper
import Cartography
import Photos
class SpaceViewController: BaseViewController,UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate {
    
    // MARK: UI variables
    private var messageTableView: UITableView?
    public var spaceModel: SpaceModel?
    private var spaceMemberTableView: UITableView?
    private var maskView: UIView?
    private var spaceMeberList: [Membership] = []
    private var messageList: [BDSMessage] = []
    private let messageTableViewHeight = Constants.Size.navHeight > 64 ? (Constants.Size.screenHeight-Constants.Size.navHeight-74) : (Constants.Size.screenHeight-Constants.Size.navHeight-40)
    private var tableTap: UIGestureRecognizer?
    private var topIndicator: UIActivityIndicatorView?
    private var navigationTitleLabel: UILabel?
    private var buddiesInputView : BuddiesInputView?
    private var callVC : BuddiesCallViewController?

    // MARK: - Life Circle
    init(space: SpaceModel){
        super.init()
        self.spaceModel = space
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpTopNavigationView()
        self.setUpSupViews()
        self.requestMessageData()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let buddiesInputView = self.buddiesInputView{
            buddiesInputView.selectedAssetCollectionView?.removeFromSuperview()
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
        if let spaceId = self.spaceModel?.spaceId , spaceId != "" {
            self.topIndicator?.startAnimating()
            WebexSDK?.messages.list(spaceId: spaceId, before: nil, max: 50, mentionedPeople: nil, queue: nil, completionHandler: { (response: ServiceResponse<[Message]>) in
                self.topIndicator?.stopAnimating()
                self.updateNavigationTitle()
                switch response.result {
                case .success(let value):
                    self.messageList.removeAll()
                    for message in value{
                        let tempMessage = BDSMessage(messageModel: message)
                        tempMessage?.localGroupId = self.spaceModel?.localGroupId
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
            self.updateNavigationTitle()
        }
    }
    
    // MARK: - WebexSDK: listing member in a space
    func requestSpaceMemberList(){
        KTActivityIndicator.singleton.show(title: "Loading")
        WebexSDK?.memberships.list(spaceId: (self.spaceModel?.spaceId)!) { (response: ServiceResponse<[Membership]>) in
            KTActivityIndicator.singleton.hide()
            switch response.result {
            case .success(let value):
                self.spaceMeberList.removeAll()
                for memberShip in value{
                    self.spaceMeberList.append(memberShip)
                }
                self.spaceMemberTableView?.reloadData()
                break
            case .failure:
                break
            }
        }
    }
    
    // MARK: - WebexSDK: post message | make call to a space
    func sendMessage(text: String, _ assetList:[BDAssetModel]? = nil , _ mentionList:[Contact]? = nil, _ menpositions:[Range<Int>]){
        let tempMessageModel = BDSMessage()
        tempMessageModel.spaceId = self.spaceModel?.spaceId
        tempMessageModel.messageState = MessageState.willSend
        tempMessageModel.text = text
        if self.spaceModel?.type == SpaceType.direct{
            if let personEmail = self.spaceModel?.spaceMembers![0].email,
                let personId = self.spaceModel?.spaceMembers![0].id{
                tempMessageModel.toPersonEmail = EmailAddress.fromString(personEmail)
                tempMessageModel.toPersonId = personId
            }
        }
        tempMessageModel.personId = User.CurrentUser.id
        tempMessageModel.personEmail = EmailAddress.fromString(User.CurrentUser.email)
        tempMessageModel.localGroupId = self.spaceModel?.localGroupId
        if let mentions = mentionList, mentions.count>0{
            var mentionModels : [Mention] = []
            for mention in mentions{
                if mention.name == "ALL"{
                    mentionModels.append(Mention.all)
                }else{
                    mentionModels.append(Mention.person(mention.id))
                }
            }
            tempMessageModel.mentionList = mentionModels
            tempMessageModel.text = self.processMentionString(contentStr: text, mentions: mentionModels, mentionsArr: menpositions)
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
                    if let data = UIImageJPEGRepresentation(result!, 1.0){
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
        if let spaceModel = self.spaceModel{
            self.callVC = BuddiesCallViewController(space: spaceModel)
            self.present(self.callVC!, animated: true) {
                self.callVC?.beginCall(isVideo: isVideo)
            }
        }
    }
    
    // MARK: - WebexSDK: receive a new message
    public func receiveNewMessage(message: Message){
        if let _ = self.messageList.filter({$0.messageId == message.id}).first{
            return
        }
        let msgModel = BDSMessage(messageModel: message)
        msgModel?.messageState = MessageState.received
        msgModel?.localGroupId = self.spaceModel?.localGroupId
        if(msgModel?.text == nil){
            msgModel?.text = ""
        }
        self.messageList.append(msgModel!)
        let indexPath = IndexPath(row: self.messageList.count-1, section: 0)
        self.messageTableView?.reloadData()
        _ = self.messageTableView?.cellForRow(at: indexPath)
        self.messageTableView?.scrollToRow(at: indexPath, at: .bottom, animated: false)
        if let callVc = self.callVC{
            callVc.receiveNewMessage(message: message)
        }
    }
    
    // MARK: - UI Implementation
    private func setUpTopNavigationView(){
        if(self.navigationTitleLabel == nil){
            self.navigationTitleLabel = UILabel(frame: CGRect(0,0,Constants.Size.screenWidth-80,20))
            self.navigationTitleLabel?.font = Constants.Font.NavigationBar.Title
            self.navigationTitleLabel?.textColor = UIColor.white
            self.navigationTitleLabel?.textAlignment = .center
            self.navigationItem.titleView = self.navigationTitleLabel
            self.topIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
            self.topIndicator?.hidesWhenStopped = true
            self.navigationTitleLabel?.addSubview(self.topIndicator!)
            self.topIndicator?.center = CGPoint((self.navigationTitleLabel?.center.x)!-20, 15)
        }
    }
    
    private func setUpSupViews(){
        self.updateBarItem()
        self.setUpMessageTableView()
        self.setUpBottomView()
    }
    
    private func updateBarItem() {
        var avator: UIImageView?
        if (User.CurrentUser.loginType != .None) {
            avator = User.CurrentUser.avator
            if let avator = avator {
                avator.setCorner(Int(avator.frame.height / 2))
            }
            let membersBtnItem = UIBarButtonItem(image: UIImage(named: "icon_members"), style: .plain, target: self, action: #selector(membersBtnClicked))
            self.navigationItem.rightBarButtonItem = membersBtnItem
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
        if let group = User.CurrentUser[(self.spaceModel?.localGroupId)!]{
            self.buddiesInputView = BuddiesInputView(frame: CGRect(x: 0, y: messageTableViewHeight, width: bottomViewWidth, height: 40) , tableView: self.messageTableView!, contacts: group.groupMembers)
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
        }else{
            self.buddiesInputView = BuddiesInputView(frame: CGRect(x: 0, y: messageTableViewHeight, width: bottomViewWidth, height: 40) , tableView: self.messageTableView!)
            self.buddiesInputView?.sendBtnClickBlock = { (textStr: String, assetList:[BDAssetModel]?, mentionList:[Contact]?,mentionPositions: [Range<Int>]) in
                self.sendMessage(text: textStr, assetList, mentionList,mentionPositions)
            }
            self.view.addSubview(self.buddiesInputView!)
        }

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
            self.requestSpaceMemberList()
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
            return self.spaceMeberList.count
        }else{
            return self.messageList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == self.spaceMemberTableView){
            let index = indexPath.row
            let memberModel = self.spaceMeberList[index]
            var reuseCell = tableView.dequeueReusableCell(withIdentifier: "PeopleListTableCell")
            if reuseCell != nil{
                (reuseCell as! PeopleListTableCell).updateMembershipCell(newMemberShipModel: memberModel)
            }else{
                reuseCell = PeopleListTableCell(membershipModel: memberModel)
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

    // MARK: - Markup string
    private func processMentionString(contentStr: String?, mentions: [Mention],mentionsArr: [Range<Int>])-> String{
        var result: String = ""
        if let contentStr = contentStr{
            var markedUpContent = contentStr
            var mentionStringLength = 0
            for index in 0..<mentionsArr.count{
                let mention = mentions[index]
                let mentionItem = mentionsArr[index]
                let startPosition = (mentionItem.lowerBound) + mentionStringLength
                let endPostion = (mentionItem.upperBound) + mentionStringLength
                if markedUpContent.length < startPosition || markedUpContent.length < markedUpContent.startIndex.hashValue + endPostion{
                    continue
                }
                let startIndex = markedUpContent.index(markedUpContent.startIndex, offsetBy: startPosition)
                let endIndex = markedUpContent.index(markedUpContent.startIndex, offsetBy: endPostion)
                let mentionContent = markedUpContent[startPosition..<endPostion]
                switch mention{
                case .all:
                    let markupStr = markUpString(mentionContent: mentionContent, groupType: "All", mentionType: "groupMention")
                    markedUpContent = markedUpContent.replacingCharacters(in: startIndex..<endIndex, with: markupStr)
                    mentionStringLength += (markupStr.count - (mentionContent?.count)!)
                    break
                case .person(let personId):
                    let markupStr = markUpString(mentionContent: mentionContent, mentionId: personId, mentionType: "person")
                    markedUpContent = markedUpContent.replacingCharacters(in: startIndex..<endIndex, with: markupStr)
                    mentionStringLength += (markupStr.count - (mentionContent?.count)!)
                    break
                }
            }
            result = markedUpContent
        }
        return result
    }
    private func markUpString(mentionContent: String?, mentionId: String? = nil, groupType: String?=nil, mentionType: String)->String{
        var result = "<spark-mention"
        if let mentionid = mentionId{
            result = result + " data-object-id=" + mentionid
        }
        if let grouptype = groupType{
            result = result + " data-group-type=" + grouptype
        }
        
        result = result + " data-object-type=" + mentionType
        result = result + ">"
        if let content = mentionContent{
            result = result + content
        }
        result = result + "</spark-mention>"
        return result
    }
    
    // MARK: Other Functions
    private func updateNavigationTitle(){
        self.navigationTitleLabel?.text = self.spaceModel?.title != nil ? self.spaceModel?.title! : "No Name"
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
