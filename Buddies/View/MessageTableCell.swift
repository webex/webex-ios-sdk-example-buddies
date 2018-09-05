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
import ImageIO

let avatorHeight = 50
let messageCellTextWidth = (Constants.Size.screenWidth - CGFloat(avatorHeight))/4*3
let imageWidth = Constants.Size.screenWidth/3
let imageHeight = Constants.Size.screenWidth/2
let fileWidth = Constants.Size.screenWidth/2
let fileHeight = Constants.Size.screenWidth/16*3

class MessageTableCell: UITableViewCell {
    
    // MARK: - UI variables
    private var message: BDSMessage
    
    private var avatorImageView: UIImageView?
    
    private var contentLabel: UILabel?
    
    private var messageShapeLayer: CAShapeLayer?
    
    private var messageIndicator: UIActivityIndicatorView?
    
    private var optionBtn: UIButton?
    
    private var messageSize: CGSize
    
    private var isUser: Bool
    
    private var fileViewArray: NSMutableArray?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    // MARK: - UI Iplementation
    init(message: BDSMessage){
        self.message = message
        self.messageSize = CGSize.zero
        self.isUser = (message.personId! == User.CurrentUser.id) || (message.personEmail?.toString() == User.CurrentUser.email)
        super.init(style: .default, reuseIdentifier: "MessageListTableCell")
        self.messageSize = self.getTextSize(text: (message.text)!)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.setUpMessageCellSubViews()
    }
    
    public func updateTableCell(message: BDSMessage){
        self.message = message
        self.messageSize = CGSize.zero
        self.isUser = (message.personId == User.CurrentUser.id) || (message.personEmail?.toString() == User.CurrentUser.email)
        self.messageSize = self.getTextSize(text: (message.text)!)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.setUpMessageCellSubViews()
    }
    
    private func setUpMessageCellSubViews(){
        self.cleanUpSubViews()
        if(self.avatorImageView == nil){
            if(!isUser){
                self.avatorImageView = UIImageView(frame: CGRect(x: 5, y: 10, width: avatorHeight, height: avatorHeight))
            }else{
                self.avatorImageView = UIImageView(frame: CGRect(x:Int(self.mirrorPosition(5, CGFloat(avatorHeight))), y: 10, width: avatorHeight, height: avatorHeight))
            }
            self.avatorImageView?.layer.cornerRadius = CGFloat(avatorHeight/2)
            self.avatorImageView?.layer.masksToBounds = true
            self.avatorImageView?.layer.borderColor = UIColor.white.cgColor
            self.avatorImageView?.layer.borderWidth = 2.0
            if(self.message.personId == User.CurrentUser.id){
                if let url = User.CurrentUser.avatorUrl {
                    self.avatorImageView?.sd_setImage(with: URL(string: url), placeholderImage: User.CurrentUser.placeholder)
                }
                else {
                    self.avatorImageView?.image = User.CurrentUser.placeholder
                }
            }else{
                if let spaceModel = User.CurrentUser[self.message.localSpaceId!] {
                    let contact = spaceModel.contact
                    if let url = contact?.avatorUrl {
                        self.avatorImageView?.sd_setImage(with: URL(string: url), placeholderImage: contact?.placeholder)
                    }
                    else {
                        self.avatorImageView?.image = contact?.placeholder
                    }
                }else {
                    let image = UIImage.getContactAvatorImage(name: (message.personEmail?.toString())!, size: 70)
                    if let url = message.avator {
                        self.avatorImageView?.sd_setImage(with: URL(string: url), placeholderImage: image)
                    }
                    else {
                        self.avatorImageView?.image = image
                    }
                }
            }
            self.addSubview(self.avatorImageView!)
        }
        if self.message.localFiles != nil || self.message.remoteFiles != nil{
            self.setUpFileAndContentView()
        }else{
            if self.message.text != nil{
                self.setupContentLabel()
            }
        }
        self.setUpIndicatorView()
    }
   
    @objc private func setUpFileAndContentView(){
        if self.message.text?.length == 0{
            messageSize.width = Constants.Size.screenWidth/2
            messageSize.height = -10
            let beginY = CGFloat(avatorHeight/2 - 10) + messageSize.height+10
            if let _ = self.message.localFiles{
                self.setUpLocalFileView(beginY: beginY)
            }
            else if let _ = self.message.remoteFiles{
                self.setUpRemoteFileView(beginY: beginY)
            }
            if(self.message.messageState == MessageState.willSend){
                self.sendMessage()
            }else{
                self.updateMessageState()
            }
        }else{
            self.setupContentLabel()
            let beginY = CGFloat(avatorHeight/2 - 10) + messageSize.height+10
            if let _ = self.message.localFiles{
                self.setUpLocalFileView(beginY: beginY)
            }
            else if let _ = self.message.remoteFiles{
                self.setUpRemoteFileView(beginY: beginY)
            }
        }
    }
    
    
    @objc private func setupContentLabel(){
        if(self.contentLabel == nil){
            if(self.messageShapeLayer == nil){
                self.messageShapeLayer = CAShapeLayer()
                self.messageShapeLayer?.path = self.getMessageShapePath()
                if(!isUser){
                    self.messageShapeLayer?.fillColor = Constants.Color.Message.OtherBack.cgColor
                }else{
                    self.messageShapeLayer?.fillColor = Constants.Color.Message.MineBack.cgColor
                }
                self.layer.addSublayer(messageShapeLayer!)
            }
            
            if(!isUser){
                self.contentLabel = UILabel(frame: CGRect(x: CGFloat(avatorHeight + 20) , y:CGFloat(avatorHeight/2 - 10), width: messageCellTextWidth, height: messageSize.height+20))
            }else{
                let xPosition = self.mirrorPosition(CGFloat(avatorHeight + 20), messageSize.width)
                self.contentLabel = UILabel(frame: CGRect(x: CGFloat(xPosition) , y:CGFloat(avatorHeight/2 - 10), width: messageCellTextWidth, height: messageSize.height+20))
            }
            if let text = self.message.text, text.count > 0{
                self.contentLabel?.attributedText = NSAttributedString.convertAttributeStringToPretty(attributedString: MessageParser.sharedInstance().translate(toAttributedString: text))
            }
            else{
                self.contentLabel?.attributedText = NSAttributedString.init(string: "")
            }
            self.contentLabel?.numberOfLines = 0
            self.addSubview(self.contentLabel!)
            if(self.message.messageState == MessageState.willSend){
                self.sendMessage()
            }else{
                self.updateMessageState()
            }
        }
    }
    
    
    @objc private func setUpLocalFileView(beginY: CGFloat){
        if(self.fileViewArray == nil){
            self.fileViewArray = NSMutableArray()
            var totalY : CGFloat = 0
            do {
                if let remoteFiles = message.localFiles{
                    for index in 0..<remoteFiles.count {
                        let file = remoteFiles[index]
                        var imageViewWidth : CGFloat = 0
                        var imageViewHeight : CGFloat = 0
                        var fileLabelY: CGFloat = 0
                        var fileLableHeight: CGFloat = 0
                        if (file.mime.contains("image/")){
                            imageViewWidth = imageWidth
                            imageViewHeight = imageHeight
                            fileLabelY = imageViewHeight/4*3
                            fileLableHeight = imageViewHeight/4
                        }else{
                            imageViewWidth = fileWidth
                            imageViewHeight = fileHeight
                            fileLableHeight = imageViewHeight
                        }
                        let imageView = UIImageView()
                        imageView.layer.masksToBounds = true
                        imageView.contentMode = .scaleAspectFill
                        var x1 = CGFloat(avatorHeight + 15)
                        let y1 = beginY + CGFloat(avatorHeight/2 - 10) + totalY + 10*(CGFloat(index))
                        totalY += imageViewHeight
                        if(isUser){
                            x1 = self.mirrorPosition(x1, imageViewWidth)
                        }
                        imageView.frame = CGRect(x1,y1,imageViewWidth,imageViewHeight)
                        imageView.layer.cornerRadius = 3.0
                        imageView.backgroundColor = UIColor.white
                        self.addSubview(imageView)
                        
                        if (file.mime.contains("image/")){
                            imageView.image = UIImage(contentsOfFile: (file.path))
                        }
                        let fileNameLabel = UILabel()
                        fileNameLabel.frame = CGRect(x: 0, y: fileLabelY, width: imageViewWidth, height: fileLableHeight)
                        fileNameLabel.text = file.name
                        fileNameLabel.textAlignment = .center
                        fileNameLabel.numberOfLines = 3
                        imageView.addSubview(fileNameLabel)
                        
                        if (file.mime.contains("image/")){
                            fileNameLabel.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
                            fileNameLabel.textColor = UIColor.white
                            fileNameLabel.font = Constants.Font.InputBox.Comments
                        }else{
                            fileNameLabel.backgroundColor = UIColor.lightGray
                            fileNameLabel.textColor = UIColor.black
                            fileNameLabel.font = Constants.Font.NavigationBar.Title
                        }
                    }
                }
            }
        }
    }
    
    @objc private func setUpRemoteFileView(beginY: CGFloat){
        if(self.fileViewArray == nil){
            self.fileViewArray = NSMutableArray()
            var totalY : CGFloat = 0
            do {
                if let remoteFiles = message.remoteFiles{
                    for index in 0..<remoteFiles.count {
                        let file = remoteFiles[index]
                        var imageViewWidth : CGFloat = 0
                        var imageViewHeight : CGFloat = 0
                        var fileLabelY: CGFloat = 0
                        var fileLableHeight: CGFloat = 0
                        if (file.mimeType?.contains("image/"))!{
                            imageViewWidth = imageWidth
                            imageViewHeight = imageHeight
                            fileLabelY = imageViewHeight/4*3
                            fileLableHeight = imageViewHeight/4
                        }else{
                            imageViewWidth = fileWidth
                            imageViewHeight = fileHeight
                            fileLableHeight = imageViewHeight
                        }
                        let imageView = UIImageView()
                        imageView.layer.masksToBounds = true
                        imageView.contentMode = .scaleAspectFill
                        var x1 = CGFloat(avatorHeight + 15)
                        let y1 = beginY + CGFloat(avatorHeight/2 - 10) + totalY + 10*(CGFloat(index))
                        totalY += imageViewHeight
                        if(isUser){
                            x1 = self.mirrorPosition(x1, imageViewWidth)
                        }
                        imageView.frame = CGRect(x1,y1,imageViewWidth,imageViewHeight)
                        imageView.layer.cornerRadius = 3.0
                        imageView.backgroundColor = UIColor.white
                        self.addSubview(imageView)
                        
                        if (file.mimeType?.contains("image/"))!{
                            if let localUrl  = file.localUrl{
                                imageView.image = UIImage(contentsOfFile: localUrl)
                            }
                            else{
                                imageView.backgroundColor = UIColor.lightGray
                                let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
                                indicator.center = CGPoint(x: imageViewWidth/2, y: imageViewHeight/2-10)
                                indicator.startAnimating()
                                imageView.addSubview(indicator)
                                WebexSDK?.messages.downloadFile(file.remoteFile, completionHandler: { result in
                                    indicator.stopAnimating()
                                    if let localUrl = result.data{
                                        self.message.remoteFiles![index].localUrl = localUrl.path
                                        imageView.image = UIImage(contentsOfFile: (localUrl.path))
                                    }
                                    else{
                                        imageView.backgroundColor = UIColor.lightGray
                                    }
                                })
                            }
                        }
                        let fileNameLabel = UILabel()
                        fileNameLabel.frame = CGRect(x: 0, y: fileLabelY, width: imageViewWidth, height: fileLableHeight)
                        fileNameLabel.text = self.message.fileNames?[index]
                        fileNameLabel.textAlignment = .center
                        fileNameLabel.numberOfLines = 3
                        imageView.addSubview(fileNameLabel)
                        
                        if (file.mimeType?.contains("image/"))!{
                            fileNameLabel.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
                            fileNameLabel.textColor = UIColor.white
                            fileNameLabel.font = Constants.Font.InputBox.Comments
                        }else{
                            fileNameLabel.backgroundColor = UIColor.lightGray
                            fileNameLabel.textColor = UIColor.black
                            fileNameLabel.font = Constants.Font.NavigationBar.Title
                        }
                    }
                }
            }
        }
    }
    
    private func setUpIndicatorView(){
        if(self.messageIndicator == nil){
            self.messageIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            self.messageIndicator?.color = Constants.Color.Theme.Main
            self.messageIndicator?.hidesWhenStopped = true
            self.addSubview(self.messageIndicator!)

        }
        var padding = messageSize.width+10+10
        if(!isUser){
            self.messageIndicator?.center = CGPoint(x: CGFloat(avatorHeight + 20) + padding, y: CGFloat(avatorHeight/2)+10.0)
        }else{
            if let uploadFiles = self.message.localFiles, uploadFiles.count>0, let text = self.message.text, text.count <= 0{
                padding -= imageWidth/2
            }
            let positionX = self.mirrorPosition(CGFloat(avatorHeight + 20) + padding , 0)
            self.messageIndicator?.center = CGPoint(x: positionX, y: CGFloat(avatorHeight/2)+10.0)
        }
        self.bringSubview(toFront: self.messageIndicator!)
        if self.message.messageState == MessageState.willSend{
            self.optionBtn?.removeFromSuperview()
            self.messageIndicator?.startAnimating()
        }
        else{
            self.messageIndicator?.stopAnimating()
        }
    }
    
    // MARK: - WebexSDK: send message
    @objc private func sendMessage(){
        if(self.message.messageState == MessageState.willSend || self.message.messageState == MessageState.sendFailed){
            self.message.messageState = MessageState.willSend
            self.setUpIndicatorView()
            if(self.message.spaceId == nil || self.message.spaceId?.length == 0){
                DispatchQueue.global().async {
                    let emailStr = User.CurrentUser.loginType == UserLoginType.User ? (self.message.toPersonEmail?.toString())! : self.message.localSpaceId
                    WebexSDK?.messages.post(personEmail: EmailAddress.fromString(emailStr!)!, text: self.message.text!, files: self.message.localFiles, queue: nil, completionHandler: { (response: ServiceResponse<Message>) in
                        self.messageIndicator?.stopAnimating()
                        switch response.result {
                        case .success(let value):
                            let spaceModel = User.CurrentUser[self.message.localSpaceId!]
                            spaceModel?.spaceId = value.spaceId!
                            User.CurrentUser.saveSpacesToLocal()
                            self.message.messageId = value.id
                            self.message.messageState = MessageState.idle
                            break
                        case let .failure(error):
                            print(error)
                            self.message.messageState = MessageState.sendFailed
                            self.updateMessageState()
                            break
                        }
                    })
                }
            }else{
                DispatchQueue.global().async {
                    self.message.messageState = MessageState.sending
                    WebexSDK?.messages.post(spaceId: self.message.spaceId!, text: (self.message.text!), mentions: self.message.mentionList, files: self.message.localFiles, queue: nil, completionHandler: { (response: ServiceResponse<Message>) in
                        self.messageIndicator?.stopAnimating()
                        switch response.result {
                        case .success(let value):
                            self.message.messageId = value.id
                            self.message.messageState = MessageState.idle
                            break
                        case let .failure(error):
                            print(error)
                            self.message.messageState = MessageState.sendFailed
                            self.updateMessageState()
                            break
                        }
                    })
                }
            }
        }
    }
    
    private func updateMessageState(){
        if(self.message.messageState == MessageState.sendFailed){
            if(self.optionBtn == nil){
                self.optionBtn = UIButton(type: .custom)
                self.optionBtn?.frame = CGRect(0,0,20,20)
                self.optionBtn?.titleLabel?.font = UIFont.fontAwesome(ofSize: 20)
                self.optionBtn?.setTitle(String.fontAwesomeIcon(name: .exclamation), for: .normal)
                self.optionBtn?.setTitleColor(Constants.Color.Message.Warning, for: .normal)
                self.optionBtn?.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
            }
            if(!isUser){
                self.optionBtn?.center = CGPoint(x: CGFloat(avatorHeight + 20) + messageSize.width+10+10, y: CGFloat(avatorHeight/2)+10.0)
            }else{
                let positionX = self.mirrorPosition(CGFloat(avatorHeight + 20) + messageSize.width+10+10, 0)
                self.optionBtn?.center = CGPoint(x: positionX, y: CGFloat(avatorHeight/2)+10.0)
            }
            self.addSubview(self.optionBtn!)
        }
    }
    
    // MARK: - Get Cell Total Height
    public static func getCellHeight(attrText: NSAttributedString , imageCount: Int , fileCount: Int) -> CGFloat{
        let totalCount = imageCount + fileCount
        let trimedText =  attrText.string.getLineTrimedString()
        if(totalCount > 0 && trimedText.length != 0){
            let textHeight = trimedText.calculateSringHeight(width: Double(CGFloat(messageCellTextWidth)), font: Constants.Font.InputBox.Input)
            if(textHeight+25 > CGFloat(avatorHeight)){
                return textHeight + 45 + (imageHeight)*CGFloat(imageCount) + 10*CGFloat(totalCount+1) + (fileHeight)*CGFloat(fileCount)
            }else{
                return CGFloat(avatorHeight) + 15 + (imageHeight)*CGFloat(imageCount) + 10*CGFloat(totalCount+1) + (fileHeight)*CGFloat(fileCount)
            }
        }
        if(totalCount > 0){
            return 15 + (imageHeight)*CGFloat(imageCount) + 10*CGFloat(totalCount+1) + (fileHeight)*CGFloat(fileCount)
        }
        let textHeight = trimedText.calculateSringHeight(width: Double(CGFloat(messageCellTextWidth)), font: Constants.Font.InputBox.Input)
        if(textHeight+25 > CGFloat(avatorHeight)){
            return textHeight + 45
        }else{
            return CGFloat(avatorHeight) + 15
        }
    }
    
    // MARK: - Support Functions
    private func getTextSize(text: String) ->CGSize{
        if text.count == 0{
            let textSize = text.calculateSringSize(width: Double(CGFloat(messageCellTextWidth)), font: Constants.Font.InputBox.Input)
            return textSize
        }
        else{
            let textStr = MessageParser.sharedInstance().translate(toAttributedString:text)!
            let result = textStr.string.getLineTrimedString()
            let textSize = result.calculateSringSize(width: Double(CGFloat(messageCellTextWidth)), font: Constants.Font.InputBox.Input)
            return textSize
        }

    }
    
    private func getMessageShapePath() -> CGPath{
        let cornerRadius : CGFloat = 3.0
        let tempPath = UIBezierPath()
        var x1 = CGFloat(avatorHeight + 15)
        var x2 = (x1 + cornerRadius)
        var x4 = (x1+messageSize.width+10)
        var x3 = (x4 - cornerRadius)
        
        let y1 = CGFloat(avatorHeight/2 - 10)
        let y2 = y1 +  cornerRadius
        let y4 = (y1+messageSize.height+20)
        let y3 = y4 - cornerRadius
        
        var triAngleP : CGPoint
        var triAngleP1 : CGPoint
        var triAngleP2 : CGPoint
        
        if(isUser){
            x1 = self.mirrorPosition(x1, messageSize.width+10)
            x2 = (x1+cornerRadius)
            x4 = (x1+messageSize.width+10)
            x3 = (x4 - cornerRadius)
        }
        
        tempPath.move(to: CGPoint(x1,y2))
        tempPath.addQuadCurve(to: CGPoint(x2,y1), controlPoint: CGPoint(x1,y1))
        tempPath.addLine(to: CGPoint(x3,y1))
        tempPath.addQuadCurve(to: CGPoint(x4,y2), controlPoint: CGPoint(x4,y1))
        if(isUser){
            triAngleP = CGPoint(x: self.mirrorPosition(CGFloat(avatorHeight + 8), 0) , y: CGFloat(avatorHeight/2+10))
            triAngleP1 = CGPoint(x: self.mirrorPosition(CGFloat(avatorHeight + 15), 0) , y: CGFloat(avatorHeight/2-4+10))
            triAngleP2 = CGPoint(x: self.mirrorPosition(CGFloat(avatorHeight + 15), 0), y: CGFloat(avatorHeight/2+4+10))
            tempPath.addLine(to: triAngleP1)
            tempPath.addLine(to: triAngleP)
            tempPath.addLine(to: triAngleP2)
        }
        tempPath.addLine(to: CGPoint(x4,y3))
        tempPath.addQuadCurve(to: CGPoint(x3,y4), controlPoint: CGPoint(x4,y4))
        tempPath.addLine(to: CGPoint(x2,y4))
        tempPath.addQuadCurve(to: CGPoint(x1,y3), controlPoint: CGPoint(x1,y4))
        if(!isUser){
            triAngleP = CGPoint(x: CGFloat(avatorHeight + 8), y: CGFloat(avatorHeight/2+10))
            triAngleP1 = CGPoint(x: CGFloat(avatorHeight + 15), y: CGFloat(avatorHeight/2-4+10))
            triAngleP2 = CGPoint(x: CGFloat(avatorHeight + 15), y: CGFloat(avatorHeight/2+4+10))
            tempPath.addLine(to: triAngleP2)
            tempPath.addLine(to: triAngleP)
            tempPath.addLine(to: triAngleP1)
        }
        tempPath.close()
        return tempPath.cgPath
    }

    private func mirrorPosition(_ originPosition: CGFloat,_ size: CGFloat)->CGFloat{
        return Constants.Size.screenWidth - originPosition - size
    }
    
    private func cleanUpSubViews(){
        for view in self.subviews{
            if view == self.avatorImageView{
                continue
            }
            if view is UIImageView{
                view.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Other Functions
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}

