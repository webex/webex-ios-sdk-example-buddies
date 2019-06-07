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

class AddContactView: UIView, UITextFieldDelegate , UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate{
    
    // MARK: - UI variables
    var spaceCreatedBlock: ((SpaceModel, Bool)->())?
    
    private var backView : UIView?
    private var addedCollectionView: UICollectionView?
    private var buddiesCollectionView: UICollectionView?
    private var peopleTableView: UITableView?
    private var segmentControll: UISegmentedControl?
    private var searchBarBackView: UIView?
    private var searchBar: UISearchBar?
    private var spaceNameTextFeild: MKTextField?
    private var addedContactList: [Contact] = []
    private var peopleList : [Contact] = []
    private var viewWidth = 0
    private var viewHeight = 0
    private var backViewWidth = 0
    private var backViewHeight = 0
    
    enum SegmentType : Int{
        case Buddies = 0
        case People = 1
    }
    
    // MARK: - WebexSDK: listing people/ create space
    func requetPeopleList(searchStr: String){
        KTActivityIndicator.singleton.show(title: "Loading...")
        if let email = EmailAddress.fromString(searchStr) {
            WebexSDK?.people.list(email: email, max: 20) {
                (response: ServiceResponse<[Person]>) in
                KTActivityIndicator.singleton.hide()
                switch response.result {
                case .success(let value):
                    self.peopleList.removeAll()
                    for person in value{
                        if let tempContack = Contact(person: person){
                            self.peopleList.append(tempContack)
                        }
                    }
                    self.peopleTableView?.reloadData()
                    break
                case .failure:
                    break
                }
            }
        } else {
            WebexSDK?.people.list(displayName: searchStr, max: 20) {
                (response: ServiceResponse<[Person]>) in
                KTActivityIndicator.singleton.hide()
                switch response.result {
                case .success(let value):
                    self.peopleList.removeAll()
                    for person in value{
                        if let tempContack = Contact(person: person){
                            self.peopleList.append(tempContack)
                        }
                    }
                    self.peopleTableView?.reloadData()
                    break
                case .failure:
                    break
                }
            }
        }
    }
    func requestCreateSpace(){
//        let localSpaceId = Space.getSpaceSpaceId(contacts: self.addedContactList)
//        if let spaceModel = User.CurrentUser.findLocalSpaceWithId(localSpaceId: localSpaceId){
//            if(self.spaceCreatedBlock != nil){
//                self.spaceCreatedBlock!(spaceModel,false)
//            }
//            self.disMiss()
//            return;
//        }
        var spaceTitle = self.spaceNameTextFeild?.text
        KTActivityIndicator.singleton.show(title: "Creating")
//        if(spaceTitle?.length == 0){
//            spaceTitle = Space.getSpaceSpaceName(contacts: self.addedContactList)
//        }
        WebexSDK?.spaces.create(title: spaceTitle!) { (response: ServiceResponse<Space>) in
            switch response.result {
            case .success(let value):
                if let createdSpace = SpaceModel(space: value){
                    let threahSpace = DispatchGroup()
                    for contact in self.addedContactList{
                        DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
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
//                    createdSpace.localSpaceId = localSpaceId
                    threahSpace.notify(queue: DispatchQueue.global(), execute: {
                        DispatchQueue.main.async {
                            KTActivityIndicator.singleton.hide()
                            if(self.spaceCreatedBlock != nil){
                                self.spaceCreatedBlock!(createdSpace, true)
                            }
                            self.disMiss()
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
        }
    }
    
    // MARK: - UI Implementation
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.viewWidth = Int(frame.size.width)
        self.viewHeight = Int(frame.size.height)
        self.backViewWidth = viewWidth - 60
        self.backViewHeight = viewHeight - 60
        self.setUpSubViews()
    }
    
    func setUpSubViews(){
        self.setUpBlurView()
        self.setUpTitleView()
        self.setUpAddedCollectionView()
        self.setUpSegmentView()
        self.setUpBuddiesCollectionView()
        self.setUPBottomBtnView()
        
    }
    func setUpBlurView(){
        let blurView = UIVisualEffectView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
        blurView.effect = UIBlurEffect(style: .extraLight)
        blurView.alpha = 0.7
        self.addSubview(blurView)
    }
    func setUpTitleView(){
     
        self.backView = UIView(frame: CGRect(x: 30, y: 30, width: backViewWidth, height: backViewHeight))
        self.backView?.backgroundColor = UIColor.white
        self.backView?.setShadow(color: UIColor.gray, radius: 0.5, opacity: 0.5, offsetX: 0, offsetY: 0)
        self.addSubview(self.backView!)
        
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 10, width: backViewWidth-30, height: 30))
        titleLabel.font = Constants.Font.InputBox.Title
        titleLabel.textColor = Constants.Color.Theme.DarkControl
        titleLabel.text = "New Space"
        titleLabel.textAlignment = .center
        self.backView?.addSubview(titleLabel)
        
        self.spaceNameTextFeild = MKTextField(frame: CGRect(x: 30, y: 40, width: backViewWidth-60, height: 40))
        self.spaceNameTextFeild?.delegate = self;
        self.spaceNameTextFeild?.textAlignment = .center
        self.spaceNameTextFeild?.tintColor = Constants.Color.Theme.Main;
        self.spaceNameTextFeild?.layer.borderColor = UIColor.clear.cgColor
        self.spaceNameTextFeild?.font = Constants.Font.InputBox.Input
        self.spaceNameTextFeild?.bottomBorderEnabled = true;
        self.spaceNameTextFeild?.floatingPlaceholderEnabled = false
        self.spaceNameTextFeild?.rippleEnabled = false;
        self.spaceNameTextFeild?.placeholder = "input space name"
        self.spaceNameTextFeild?.returnKeyType = .done;
        self.backView?.addSubview(self.spaceNameTextFeild!)
    }
    
    func setUpAddedCollectionView(){
        if(self.addedCollectionView == nil){
            
            let layout = UICollectionViewFlowLayout();
            layout.scrollDirection = UICollectionViewScrollDirection.horizontal;
            layout.minimumLineSpacing = 3;
            layout.minimumInteritemSpacing = 5;
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 10);
            layout.itemSize = CGSize(60,60)
            
            self.addedCollectionView = UICollectionView(frame:CGRect(x: 5, y: 80, width: backViewWidth-10, height: 60), collectionViewLayout: layout);
            self.addedCollectionView?.register(ContactCollectionViewCell.self, forCellWithReuseIdentifier: "AddedContactCollectionCell");
            self.addedCollectionView?.delegate = self;
            self.addedCollectionView?.dataSource = self;
            self.addedCollectionView?.showsHorizontalScrollIndicator = false
            self.addedCollectionView?.backgroundColor = UIColor.white
            self.addedCollectionView?.allowsMultipleSelection = true
            self.addedCollectionView?.alwaysBounceHorizontal = true
        }
        self.backView?.addSubview(self.addedCollectionView!)
    }
    
    func setUpSegmentView(){
        if(self.segmentControll == nil){
            self.segmentControll = UISegmentedControl(items: ["Buddies","People"])
            self.segmentControll?.frame = CGRect(x: 30, y: 155, width: backViewWidth-60, height: 30)
            self.segmentControll?.addTarget(self, action: #selector(segmentClicked(sender:)), for: .valueChanged)
            self.segmentControll?.tintColor = Constants.Color.Theme.Main
            
            let attr = NSDictionary(object: Constants.Font.InputBox.Button, forKey: NSAttributedStringKey.font as NSCopying)
            self.segmentControll?.setTitleTextAttributes(attr as [NSObject : AnyObject] , for: .normal)
            
            self.segmentControll?.selectedSegmentIndex = 0
            self.backView?.addSubview(self.segmentControll!)
        }
        
    }
    @objc func segmentClicked(sender: UISegmentedControl){
        if(sender.selectedSegmentIndex == SegmentType.Buddies.rawValue){
            self.peopleTableView?.removeFromSuperview()
            self.setUpBuddiesCollectionView()
        }else{
            self.buddiesCollectionView?.removeFromSuperview()
            self.setUpPeopleTableView()
        }
    }
    
    func setUpBuddiesCollectionView(){
        if(self.buddiesCollectionView == nil){
            let layout = UICollectionViewFlowLayout();
            layout.scrollDirection = UICollectionViewScrollDirection.vertical;
            layout.minimumLineSpacing = 0;
            layout.minimumInteritemSpacing = 0;
            layout.itemSize = CGSize((backViewWidth-20)/3, (backViewWidth-20)/3);
            layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 0);
            
            self.buddiesCollectionView = UICollectionView(frame:CGRect(x: 5, y: 185, width: backViewWidth-10, height: backViewHeight-235), collectionViewLayout: layout);
            self.buddiesCollectionView?.register(ContactCollectionViewCell.self, forCellWithReuseIdentifier: "BuddiesCollectionViewCell");
            self.buddiesCollectionView?.delegate = self;
            self.buddiesCollectionView?.dataSource = self;
            self.buddiesCollectionView?.backgroundColor = UIColor.white
            self.buddiesCollectionView?.alwaysBounceVertical = true
        }
        self.backView?.addSubview(self.buddiesCollectionView!)
    }
    
    func setUpPeopleTableView(){
        if(self.peopleTableView == nil){
            self.peopleTableView = UITableView(frame: CGRect(x: 5, y: 185, width: backViewWidth-10, height: backViewHeight-235))
            self.peopleTableView?.separatorStyle = .none
            self.peopleTableView?.backgroundColor = UIColor.white
            self.peopleTableView?.delegate = self
            self.peopleTableView?.dataSource = self
        }
        self.backView?.addSubview(self.peopleTableView!)
    }
    
    func setUPBottomBtnView(){
        let btnBackView = UIView(frame: CGRect(x: 0, y: backViewHeight-50, width: backViewWidth, height: 50))
        let line = CALayer()
        line.frame = CGRect(x: 0.0, y: 0.0, width: Double(backViewWidth), height: 0.5)
        line.backgroundColor = Constants.Color.Theme.DarkControl.cgColor
        btnBackView.layer .addSublayer(line)
        
        let cancelBtn = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: Double(backViewWidth/2), height: 50.0))
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.setTitleColor(Constants.Color.Theme.DarkControl, for: .normal)
        cancelBtn.addTarget(self, action: #selector(disMiss), for: .touchUpInside)
        cancelBtn.titleLabel?.font = Constants.Font.InputBox.Button
        btnBackView.addSubview(cancelBtn)
        
        let createBtn = UIButton(frame: CGRect(x: Double(backViewWidth/2), y: 0.0, width: Double(backViewWidth/2), height: 50.0))
        createBtn.setTitle("Create", for: .normal)
        createBtn.setTitleColor(Constants.Color.Theme.Main, for: .normal)
        createBtn.addTarget(self, action: #selector(createSpaceBtnClicked), for: .touchUpInside)
        createBtn.titleLabel?.font = Constants.Font.InputBox.Button
        btnBackView.addSubview(createBtn)
        
        let line1 = CALayer()
        line1.frame = CGRect(x: Double(backViewWidth)/2, y: 0.0, width:0.5, height: 50)
        line1.backgroundColor = Constants.Color.Theme.DarkControl.cgColor
        btnBackView.layer .addSublayer(line1)
        
        self.backView?.addSubview(btnBackView)
    }
    
    
    // MARK: Page Logic Implementation
    func checkAddedPeopleList(choosedContact: Contact)->Bool{
        let email = choosedContact.email
        if(self.addedContactList.find(equality: { $0.email == email }) == nil){
            return true
        }else{
            return false
        }
    }
    
    
    func popUpOnWindow(){
        self.backView?.alpha = 0.0
        self.backView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        ((UIApplication.shared.delegate) as! AppDelegate).window?.addSubview(self)
        UIView.animate(withDuration: 0.2, animations: {
            UIView.setAnimationCurve(.easeInOut)
            self.backView?.alpha = 1.0
            self.backView?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }) { (_) in
            
        }

    }
    @objc func disMiss(){
        UIView.animate(withDuration: 0.2, animations: {
            UIView.setAnimationCurve(.easeInOut)
            self.alpha = 0.0
            self.backView?.alpha = 0.0
            self.backView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { (_) in
            self.removeFromSuperview()
        }
    }
    
    @objc func createSpaceBtnClicked(){
        self.requestCreateSpace()
    }
    
    
    // MARK: UIcollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == self.buddiesCollectionView){
            return User.CurrentUser.getSingleMemberSpace().count
        }else{
            return  (self.addedContactList.count)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == self.buddiesCollectionView){
            let contact = User.CurrentUser[indexPath.item]?.contact
            let cell: ContactCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "BuddiesCollectionViewCell", for: indexPath) as! ContactCollectionViewCell
            cell.updateUIElements(cellWidth: (backViewWidth-20)/3, showDeleteBtn: false, contact: contact, onDelete: nil)
            return cell
        }else{
            let contact = self.addedContactList[indexPath.row]
            let cell:ContactCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddedContactCollectionCell", for: indexPath) as! ContactCollectionViewCell;
            cell.updateUIElements(cellWidth: 60 , showDeleteBtn: true, contact: contact, onDelete: {
                cell.contact?.isChoosed = false
                let email = cell.contact?.email
                _ = self.addedContactList.removeObject(equality: { $0.email == email })
                self.addedCollectionView?.reloadData()
                self.buddiesCollectionView?.reloadData()
                self.peopleTableView?.reloadData()
            })
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == self.buddiesCollectionView){
            let cell: ContactCollectionViewCell = collectionView.cellForItem(at: indexPath) as! ContactCollectionViewCell
            if(cell.contact?.isChoosed)!{
                cell.contact?.isChoosed = false
                cell.updateSelection()
                let email = cell.contact?.email
                _ = self.addedContactList.removeObject(equality: { $0.email == email })
                self.addedCollectionView?.reloadData()
            }else{
                if(self.checkAddedPeopleList(choosedContact: cell.contact!)){
                    cell.contact?.isChoosed = true
                    cell.updateSelection()
                    self.addedContactList.insert(cell.contact!, at: 0)
                    self.addedCollectionView?.reloadData()
                }
            }
        }
    }

    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if(self.searchBar == nil){
            self.searchBarBackView = UIView(frame: CGRect(x: 0, y: 0, width: (self.backView?.frame.size.width)!, height: 40))
            self.searchBarBackView?.backgroundColor = UIColor.white
            self.searchBar = UISearchBar(frame: CGRect(0, 10, Constants.Size.screenWidth-90, 20))
            self.searchBar?.tintColor = Constants.Color.Theme.Main
            self.searchBar?.backgroundImage = UIImage()
            self.searchBar?.delegate = self
            self.searchBar?.returnKeyType = .search
            self.searchBar?.showsCancelButton = true
            self.searchBarBackView?.addSubview(self.searchBar!)
        }
        return self.searchBarBackView
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(peopleTableCellHeight)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peopleList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let contactModel = self.peopleList[index]
        let cell = PeopleListTableCell(searchedContactModel: contactModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell: PeopleListTableCell = tableView.cellForRow(at: indexPath) as! PeopleListTableCell
        if(cell.contactModel?.isChoosed)!{
            cell.contactModel?.isChoosed = false
            cell.updateSelection()
            let email = cell.contactModel?.email
            _ = self.addedContactList.removeObject(equality: { $0.email == email })
            self.addedCollectionView?.reloadData()
        }else{
            if(self.checkAddedPeopleList(choosedContact: cell.contactModel!)){
                cell.contactModel?.isChoosed = true
                cell.updateSelection()
                self.addedContactList.insert(cell.contactModel!, at: 0)
                self.addedCollectionView?.reloadData()
            }
        }
    }

    // MARK: SearchBar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchStr = searchBar.text{
            self.requetPeopleList(searchStr: searchStr)
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Hide the cancel button
        searchBar.resignFirstResponder()
        searchBar.text = ""
    }

    // MARK: TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


