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
import PhotosUI
import WebexSDK
import Photos
let inputViewHeight : CGFloat = Constants.Size.screenWidth > 375 ? 226 : 216
let kScreenWidth : CGFloat = Constants.Size.screenWidth
let kScreenHeight : CGFloat = Constants.Size.screenHeight
let attachBtnHeight : CGFloat = (Constants.Size.screenWidth/4-10)
let backColor : UIColor = UIColor.init(hexString: "#cdcdcd")!

class BuddiesInputView: UIView , UIImagePickerControllerDelegate , UINavigationControllerDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UITableViewDelegate,UITableViewDataSource{
    private static var myContext = 0
    private let animationTime : Double = 0.15
    private let textViewX = 50
    private let textViewY = 2
    private let textViewWidth = Int((Constants.Size.screenWidth - 140))
    private let textViewHeight = 36
    
    public var sendBtnClickBlock : ((_ text : String, _ assetModels:[BDAssetModel]? , _ mentionList:[Contact]?,_ mentionPositions: [Range<Int>])->())?
    public var audioCallBtnClickedBlock: (()->())?
    public var videoCallBtnClickedBlock: (()->())?
    
    private var tableView: UITableView
    public var inputTextView: UITextView?
    private var sendBtn: UIButton?
    private var tableTap: UIGestureRecognizer?
    private var plusBtn: UIButton?
    private var attachmentBackView : UIView?
    private var selectedImageDict : [String : Any]?
    private var selectedMembership : Membership?
    private var allAssets = [PHAsset]()
    private var imageCollectionView : UICollectionView?
    public var selectedAssetCollectionView : UICollectionView?
    private var mentionTableView: UITableView?
    private var assetDict: [String:BDAssetModel] = [:]
    private var selectedAssetModels :[BDAssetModel] = []
    private var contactList: [Contact] = []
    private var mentionedList: [Contact] = []
    private var mentionPositions : [Range<Int>] = [Range<Int>]()
    public var isInputViewInCall : Bool = false
    private var navController: UINavigationController?
    
    init(frame: CGRect , tableView: UITableView, contacts: [Contact]? = nil, navController: UINavigationController? = nil){
        self.tableView = tableView
        super.init(frame: frame)
        self.setUpSubViews()
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillAppear(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillDisappear(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        if let contacts = contacts{
            self.contactList = contacts
        }
        if let navCon = navController {
            self.navController = navCon
        }
    }
    
    func setUpSubViews(){
        let bottomViewWidth = Constants.Size.screenWidth
        self.backgroundColor = UIColor.white
        
        self.plusBtn = UIButton(frame: CGRect(x: 14, y: 7, width: 26, height: 26))
        self.plusBtn?.setImage(UIImage(named: "icon_plus"), for: .normal)
        self.plusBtn?.addTarget(self, action: #selector(plusBtnClicked), for: .touchUpInside)
        self.addSubview(self.plusBtn!)
        
        self.inputTextView = UITextView(frame: CGRect(x: textViewX, y: textViewY, width: textViewWidth, height: textViewHeight))
        self.inputTextView?.textAlignment = .center
        self.inputTextView?.tintColor = Constants.Color.Theme.Main
        self.inputTextView?.layer.borderColor = UIColor.clear.cgColor
        self.inputTextView?.font = Constants.Font.InputBox.Input
        self.inputTextView?.textAlignment = .left
        self.inputTextView?.returnKeyType = .default;
        self.inputTextView?.layer.cornerRadius = 5.0
        self.inputTextView?.layer.borderColor = Constants.Color.Theme.Main.cgColor
        self.inputTextView?.layer.borderWidth = 1.0
        self.inputTextView?.layoutManager.allowsNonContiguousLayout = false
        self.inputTextView?.addObserver(self, forKeyPath:"contentSize" , options: [NSKeyValueObservingOptions.old , NSKeyValueObservingOptions.new], context: &BuddiesInputView.myContext)
        self.addSubview(self.inputTextView!)
        
        self.sendBtn = UIButton(frame: CGRect(x: bottomViewWidth-80, y: 5, width: 70, height: 30))
        self.sendBtn?.setTitle("Send", for: .normal)
        self.sendBtn?.backgroundColor = Constants.Color.Theme.Main
        self.sendBtn?.titleLabel?.font = Constants.Font.InputBox.Input
        self.sendBtn?.layer.cornerRadius = 15
        self.sendBtn?.layer.masksToBounds = true
        self.sendBtn?.addTarget(self, action: #selector(sendBtnClicked), for: .touchUpInside)
        self.addSubview(self.sendBtn!)
    }
    
    
    // MARK: - UI Logic Implementation
    @objc private func sendBtnClicked(){
        if self.inputTextView?.text.length == 0 && self.selectedAssetModels.count == 0{
            return
        }
        if(self.sendBtnClickBlock != nil){
            self.sendBtnClickBlock!((self.inputTextView?.text)!, self.selectedAssetModels, self.mentionedList,self.mentionPositions)
            self.imageCollectionDismiss()
            self.selectedCollectionDismiss()
            self.mentionTabelDismiss()
            self.assetDict.removeAll()
            self.selectedAssetModels.removeAll()
            self.mentionedList.removeAll()
            self.mentionPositions.removeAll()

        }
    }
    
    @objc private func plusBtnClicked(){
        if self.attachmentBackView == nil{
            self.attachmentBackView = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: inputViewHeight))
            self.attachmentBackView?.backgroundColor = backColor
            
            let imageBtn = self.createAttachButton(imageName: "icon_image", title: "Images")
            imageBtn.frame = CGRect(x:5, y:5, width: attachBtnHeight, height: attachBtnHeight)
            imageBtn.addTarget(self, action: #selector(addImageButtnClicked), for: .touchUpInside)
            self.attachmentBackView?.addSubview(imageBtn)
            
            if(!self.isInputViewInCall){
                let cameraBtn = self.createAttachButton(imageName: "icon_camera", title: "Camera")
                cameraBtn.frame =  CGRect(x: 15+attachBtnHeight, y:5, width: attachBtnHeight, height: attachBtnHeight)
                cameraBtn.addTarget(self, action: #selector(cemeraButtnClicked), for: .touchUpInside)
                self.attachmentBackView?.addSubview(cameraBtn)
                
                let videoBtn = self.createAttachButton(imageName: "icon_video", title: "Video Call")
                videoBtn.frame =  CGRect(x:25+attachBtnHeight*2, y: 5, width: attachBtnHeight, height: attachBtnHeight)
                videoBtn.addTarget(self, action:#selector(videoCallBtnClicked), for: .touchUpInside)
                self.attachmentBackView?.addSubview(videoBtn)
                
                let callBtn = self.createAttachButton(imageName: "icon_call", title: "Audio Call")
                callBtn.frame =  CGRect(x:35+attachBtnHeight*3, y:5, width: attachBtnHeight, height: attachBtnHeight)
                callBtn.addTarget(self, action:#selector(audioCallBtnClicked), for: .touchUpInside)
                self.attachmentBackView?.addSubview(callBtn)
                
                if self.contactList.count > 1{
                    let mentionBtn = self.createAttachButton(imageName: "icon_at", title: "Mention")
                    mentionBtn.frame = CGRect(x:5, y:10+attachBtnHeight, width: attachBtnHeight, height: attachBtnHeight)
                    mentionBtn.addTarget(self, action:#selector(mentionBtnClicked), for: .touchUpInside)
                    self.attachmentBackView?.addSubview(mentionBtn)
                }
            }else{
                if self.contactList.count > 1{
                    let mentionBtn = self.createAttachButton(imageName: "icon_at", title: "Mention")
                    mentionBtn.frame = CGRect(x:15+attachBtnHeight, y:5, width: attachBtnHeight, height: attachBtnHeight)
                    mentionBtn.addTarget(self, action:#selector(mentionBtnClicked), for: .touchUpInside)
                    self.attachmentBackView?.addSubview(mentionBtn)
                }
            }
        }
        
        self.inputTextView?.inputView = self.attachmentBackView
        self.inputTextView?.reloadInputViews()
        self.inputTextView?.tintColor = UIColor.clear
        let control = UIControl(frame: (self.inputTextView?.bounds)!)
        control.addTarget(self, action: #selector(textViewClicked), for: .touchUpInside)
        self.inputTextView?.addSubview(control)
        self.inputTextView?.becomeFirstResponder()
    }
    
    @objc private func textViewClicked(){
        self.inputTextView?.inputView = nil
        self.inputTextView?.tintColor = Constants.Color.Theme.Main
        self.inputTextView?.becomeFirstResponder()
        self.inputTextView?.reloadInputViews()
        if let _ = self.imageCollectionView{
            self.imageCollectionView?.transform = CGAffineTransform.init(translationX: 0, y: 0)
        }
        if let _ = self.mentionTableView{
            self.mentionTableView?.transform = CGAffineTransform.init(translationX: 0, y: 0)
        }
    }
    
    @objc private func cemeraButtnClicked(){
        let imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        if User.CurrentUser.loginType == .User {
            UIApplication.shared.keyWindow?.rootViewController?.present(imagePicker, animated: true, completion: nil)
        }
        else {
            if let nav = self.navController {
                nav.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    @objc private func addImageButtnClicked(){
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            self.setUpImageCollectionView()
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized{
                    DispatchQueue.main.async {
                        self.setUpImageCollectionView()
                    }
                }
            })
            break
        case .restricted:
            break
        case .denied:
            break
        }
    }
    
    @objc func audioCallBtnClicked(){
        self.tableViewTapped()
        if let callBlock = self.audioCallBtnClickedBlock{
            callBlock()
        }
    }
    
    @objc func videoCallBtnClicked(){
        self.tableViewTapped()
        if let callBlock = self.videoCallBtnClickedBlock{
            callBlock()
        }
    }
    
    @objc func mentionBtnClicked(){
        self.setUpMentionTableView()
    }
    
    @objc private func tableViewTapped(){
        self.inputTextView?.resignFirstResponder()
        
    }
    
    // MARK: - KeyBoard Delegate Implementation
    @objc func keyBoardWillAppear(notification: Notification){
        if(tableTap == nil){
            tableTap =  UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        }
        self.tableView.addGestureRecognizer(tableTap!)
        let userInfo = notification.userInfo!
        let keyboardFrame:NSValue = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        let currentTableInsetBottom = self.tableView.contentInset.bottom
        let inputEdgeHeight:CGFloat = Constants.Size.navHeight > 64 ? 34: 0
        UIView.animate(withDuration: 0.25) {
            self.tableView.transform = CGAffineTransform.init(translationX: 0, y: -keyboardHeight+inputEdgeHeight)
            let keyBoardGap = -(self.transform.ty+keyboardHeight-inputEdgeHeight)
            self.updateUIPositions(keyBoardGap)
            self.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight+inputEdgeHeight)
            self.tableView.contentInset = UIEdgeInsetsMake(keyboardHeight, 0, currentTableInsetBottom, 0)
        }
    }
    
    @objc func keyBoardWillDisappear(notification: Notification){
        if(tableTap != nil){
            self.tableView.removeGestureRecognizer(tableTap!)
        }
        let currentTableInsetBottom = self.tableView.contentInset.bottom
        UIView.animate(withDuration: 0.25) {
            self.tableView.transform = CGAffineTransform.init(translationX: 0, y: 0)
            let keyBoardGap = -(self.transform.ty)
            self.updateUIPositions(keyBoardGap)
            self.transform = CGAffineTransform(translationX: 0, y: 0)
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, currentTableInsetBottom, 0)
        }
    }

    // MARK: - Attachments SubViews Setup
    func setUpImageCollectionView(){
        if self.imageCollectionView == nil{
            let layOut = UICollectionViewFlowLayout()
            layOut.scrollDirection = .horizontal
            layOut.itemSize = CGSize(inputViewHeight,inputViewHeight)
            layOut.minimumInteritemSpacing = 0
            layOut.minimumLineSpacing = 0
            self.imageCollectionView = UICollectionView(frame:  CGRect(0,inputViewHeight,kScreenWidth,inputViewHeight), collectionViewLayout: layOut)
            self.imageCollectionView?.register(AssetCollectionCell.self, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
            self.imageCollectionView?.delegate = self
            self.imageCollectionView?.dataSource = self
            self.imageCollectionView?.backgroundColor = backColor
            self.imageCollectionView?.showsHorizontalScrollIndicator = false
            self.attachmentBackView?.addSubview(self.imageCollectionView!)
        }
        self.loadAllAssets()
        self.imageCollectionPopUp()
    }
    
    private func setUpSelectedCollectionView(){
        if self.selectedAssetCollectionView == nil{
            let layOut = UICollectionViewFlowLayout()
            layOut.scrollDirection = .horizontal
            layOut.itemSize = CGSize(inputViewHeight/2,inputViewHeight/2)
            layOut.minimumInteritemSpacing = 0
            layOut.minimumLineSpacing = 0
            var Y : CGFloat
            if self.isInputViewInCall{
                Y = self.frame.origin.y-inputViewHeight/2+Constants.Size.navHeight+50
            }else{
                Y = self.frame.origin.y-inputViewHeight/2+Constants.Size.navHeight
            }
            self.selectedAssetCollectionView = UICollectionView(frame:  CGRect(0,Y,kScreenWidth,inputViewHeight/2), collectionViewLayout: layOut)
            self.selectedAssetCollectionView?.register(SelectedAssetCollectionCell.self, forCellWithReuseIdentifier: "SelectedAssetCollectionCell")
            self.selectedAssetCollectionView?.delegate = self
            self.selectedAssetCollectionView?.dataSource = self
            self.selectedAssetCollectionView?.showsHorizontalScrollIndicator = false
            self.selectedAssetCollectionView?.backgroundColor = backColor
        }
    }
    
    private func setUpMentionTableView(){
        if self.mentionTableView == nil{
            self.mentionTableView = UITableView(frame: CGRect(0,inputViewHeight,kScreenWidth,inputViewHeight))
            self.mentionTableView?.separatorStyle = .none
            self.mentionTableView?.backgroundColor = backColor
            self.mentionTableView?.delegate = self
            self.mentionTableView?.dataSource = self
            if let _ = self.contactList.filter({$0.name == "All"}).first{
                
            }else{
                let allMention = Contact(id: "", name: "All", email: "")
                self.contactList.insert(allMention, at: 0)
            }
            self.attachmentBackView?.addSubview(self.mentionTableView!)

        }
        self.mentionTalblePopUp()
    }
    
    private func imageCollectionPopUp(){
        UIView.beginAnimations("ImageViewSlideIn", context: nil)
        UIView.setAnimationCurve(.easeInOut)
        UIView.setAnimationDuration(animationTime)
        self.imageCollectionView?.transform = CGAffineTransform.init(translationX: 0, y: -inputViewHeight)
        UIView.commitAnimations()
    }
    
    private func imageCollectionDismiss(){
        UIView.beginAnimations("ImageViewSlideIn", context: nil)
        UIView.setAnimationCurve(.easeInOut)
        UIView.setAnimationDuration(animationTime)
        self.imageCollectionView?.transform = CGAffineTransform.init(translationX: 0, y: 0)
        UIView.commitAnimations()
        self.imageCollectionView = nil
    }
    
    private func selectedCollectionPopUp(){
        UIApplication.shared.keyWindow?.addSubview(self.selectedAssetCollectionView!)
        self.selectedAssetCollectionView?.alpha = 0.0
        UIView.beginAnimations("ImageSlideIn", context: nil)
        UIView.setAnimationCurve(.easeOut)
        UIView.setAnimationDuration(0.25)
        self.selectedAssetCollectionView?.alpha = 1.0
        UIView.commitAnimations()
    }
    private func selectedCollectionDismiss(){
        if let collectionView = self.selectedAssetCollectionView{
            UIView.animate(withDuration: 0.15, animations: {
                self.selectedAssetCollectionView?.alpha = 0.0
            }, completion: { (true) in
                collectionView.removeFromSuperview()
                self.selectedAssetCollectionView = nil
            })
        }
    }
    
    private func mentionTalblePopUp(){
        UIView.beginAnimations("mentionTablePopUp", context: nil)
        UIView.setAnimationCurve(.easeInOut)
        UIView.setAnimationDuration(animationTime)
        self.mentionTableView?.transform = CGAffineTransform.init(translationX: 0, y: -inputViewHeight)
        UIView.commitAnimations()
    }
    private func mentionTabelDismiss(){
        UIView.beginAnimations("mentionTableDismiss", context: nil)
        UIView.setAnimationCurve(.easeInOut)
        UIView.setAnimationDuration(animationTime)
        self.mentionTableView?.transform = CGAffineTransform.init(translationX: 0, y: 0)
        UIView.commitAnimations()
        self.mentionTableView = nil
    }
    
    // MARK: - Observing Keyboard/Tableview Offset Change Implemenation
    @objc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &BuddiesInputView.myContext{
            if let newValue = change?[.newKey] as? CGSize, let oldValue = change?[.oldKey] as? CGSize, newValue != oldValue {
                var contentHeight = newValue.height
                let textViewWidth = self.textViewWidth
                if(contentHeight < 36){
                    contentHeight = 36
                }else if(contentHeight >= 120){
                    contentHeight = 120
                }
                let gap = contentHeight - self.frame.size.height + 4
                if(newValue.height >= oldValue.height){
                    self.inputTextView?.frame = CGRect(x: textViewX, y: textViewY, width: textViewWidth, height: Int(contentHeight))
                    self.frame.size.height = contentHeight+4
                    UIView.animate(withDuration: 0.15, animations: {
                        self.updateTableViewInset(-gap)
                        self.updateUIPositions(-gap)
                    })
                }else{
                    self.inputTextView?.frame = CGRect(x: textViewX, y: textViewY, width: textViewWidth, height: Int(contentHeight))
                    UIView.animate(withDuration: 0.15, animations: {
                        self.frame.size.height = contentHeight+4
                        self.updateTableViewInset(-gap)
                        self.updateUIPositions(-gap)
                    })
                    
                }
            }
        }
    }
    
    func updateTableViewInset(_ height: CGFloat){
        let currentTableInsetBottom = self.tableView.contentInset.bottom
        let currentTableInsetTop = self.tableView.contentInset.top
        self.tableView.contentInset = UIEdgeInsetsMake(currentTableInsetTop, 0, currentTableInsetBottom-height, 0)
        let contentHeight = self.tableView.contentSize.height
        let contentOffSetY = self.tableView.contentOffset.y
        let delta = contentHeight - contentOffSetY
        let animate = delta > Constants.Size.screenHeight ? true : false
        self.tableView.setContentOffset(CGPoint(0,contentOffSetY-height), animated: animate)
        self.frame.origin.y += (height)
        self.sendBtn?.frame.origin.y -= (height)
        self.plusBtn?.frame.origin.y -= (height)
    }
    
    func updateUIPositions(_ gap: CGFloat){
        if let collectionView = self.selectedAssetCollectionView{
            let currentOffSet = collectionView.transform.ty
            collectionView.transform = CGAffineTransform.init(translationX: 0, y: currentOffSet + gap)
        }
    }

    // MARK: - Attachment button creation
    func createAttachButton(imageName: String, title: String)-> UIButton{
        let btn = UIButton(frame:CGRect(x: 5, y: 5, width: attachBtnHeight, height: attachBtnHeight))
        btn.setTitleColor(Constants.Color.Theme.Main, for: .normal)
        btn.titleLabel?.font = Constants.Font.InputBox.Input
        btn.contentVerticalAlignment = .top
        btn.contentHorizontalAlignment = .center
        btn.layer.cornerRadius = 5.0
        btn.layer.borderColor = UIColor.lightGray.cgColor
        btn.layer.borderWidth = 0.5
        btn.backgroundColor = UIColor.white
        btn.layer.masksToBounds = true
        btn.setImage(UIImage(named: imageName), for: .normal)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.layer.borderColor = UIColor.black.cgColor
        btn.imageView?.layer.borderColor = UIColor.black.cgColor
        btn.layoutIfNeeded()
        btn.titleLabel?.layoutIfNeeded()
        btn.imageView?.layoutIfNeeded()
        let titleFrame = btn.titleLabel?.frame
        let imageFrame = btn.imageView?.frame
        let space: CGFloat = titleFrame!.origin.x - imageFrame!.origin.x - imageFrame!.size.width
        btn.imageEdgeInsets = UIEdgeInsets(top: attachBtnHeight/4-10, left: attachBtnHeight/4, bottom: attachBtnHeight/4+10, right: attachBtnHeight/4)
        btn.titleEdgeInsets = UIEdgeInsets(top: attachBtnHeight/4*3-5, left: -space-attachBtnHeight-(titleFrame?.size.width)!, bottom: 0, right: 0)
        return btn
    }
    
    // MARK: - Load All Availble Cemara Roll Resources
    func loadAllAssets(){
        self.allAssets.removeAll()
        let allImages = PHAsset.fetchAssets(with: PHAssetMediaType.image , options: nil)
        allImages.enumerateObjects({ (object, count, stop) in
            self.allAssets.append(object)
        })
        self.allAssets.reverse()
    }
    
    // MARK: - Collectionview Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.selectedAssetCollectionView{
            return self.selectedAssetModels.count
        }else{
            return self.allAssets.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.selectedAssetCollectionView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedAssetCollectionCell", for: indexPath) as! SelectedAssetCollectionCell
            let imageModel = self.selectedAssetModels[indexPath.row]
            cell.updateImageCell(imageModel)
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! AssetCollectionCell
            let asset = self.allAssets[indexPath.row]
            if let tempModel = assetDict[asset.localIdentifier]{
                cell.updateImageCell(tempModel)
            }else{
                let manager = PHImageManager.default()
                manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil) { (result, info) in
                    let tempModel = BDAssetModel(asset: asset)
                    self.assetDict[asset.localIdentifier] = tempModel
                    tempModel.image = result
                    cell.updateImageCell(tempModel)
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.imageCollectionView{
            let cell = collectionView.cellForItem(at: indexPath) as! AssetCollectionCell
            if let isSelected = cell.assetModel?.isSelected{
                cell.assetModel?.isSelected = !isSelected
                cell.setUpSelectCheckImage()
                if !isSelected{
                    self.insertSelectAssetModel(assetModel: cell.assetModel!)
                }else{
                    var item : Int = 0
                    for row in 0..<self.selectedAssetModels.count{
                        if self.selectedAssetModels[row] == cell.assetModel{
                            item = row
                            break
                        }
                    }
                    self.selectedAssetModels.remove(at: item)
                    if (self.selectedAssetModels.count == 0) {
                        self.selectedAssetCollectionView?.reloadData()
                        self.selectedCollectionDismiss()
                    } else {
                        let path = IndexPath(item: item, section: 0)
                        self.selectedAssetCollectionView?.deleteItems(at: [path])
                    }
                }
            }
        }else{
            let cell = collectionView.cellForItem(at: indexPath) as! SelectedAssetCollectionCell
            cell.assetModel?.isSelected = false
            self.selectedAssetModels.remove(at: indexPath.row)
            if (self.selectedAssetModels.count == 0) {
                self.selectedCollectionDismiss()
            } else {
                self.selectedAssetCollectionView?.deleteItems(at: [indexPath])
            }
            self.imageCollectionView?.reloadData()
        }
    }
    
    private func insertSelectAssetModel(assetModel: BDAssetModel){
        self.setUpSelectedCollectionView()
        self.selectedAssetModels.append(assetModel)
        if self.selectedAssetModels.count == 1{
            self.selectedCollectionPopUp()
        }
        if (self.selectedAssetModels.count == 1) {
            self.selectedAssetCollectionView?.reloadData()
        } else {
            let path = IndexPath(item: self.selectedAssetModels.count - 1, section: 0)
            self.selectedAssetCollectionView?.insertItems(at: [path])
            self.selectedAssetCollectionView?.scrollToItem(at: path, at: .centeredHorizontally, animated: true)
        }
    }
    
    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(mentionTableCellHeight)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contactList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let contactModel = self.contactList[index]
        let cell = PeopleListTableCell(mentionContact: contactModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedContact = self.contactList[indexPath.row]
        self.mentionedList.append(selectedContact)
        let start = self.inputTextView?.text.count
        let end = (self.inputTextView?.text.count)! + selectedContact.name.count
        self.mentionPositions.append(start!..<(end+1))
        self.inputTextView?.text.append(" " + selectedContact.name + " ")
        self.mentionTabelDismiss()
        self.textViewClicked()
    }
    
    // MARK: - ImagePicker Delegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        picker.dismiss(animated: true) {
            self.textViewClicked()
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            KTActivityIndicator.singleton.show(title: "Save Photo Fialure \(error.description)")
        } else {
            let assets = PHAsset.fetchAssets(with: PHAssetMediaType.image , options: nil)
            if let asset = assets.lastObject{
                let tempModel = BDAssetModel(asset: asset)
                tempModel.isSelected = true
                self.insertSelectAssetModel(assetModel: tempModel)
            }
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.dismiss(animated: true) {
            self.textViewClicked()
        }
    }
    
    // MARK: - Other Functions
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        self.inputTextView?.removeObserver(self, forKeyPath: "contentSize")
    }
    
}
