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

class PeopleListViewController: BaseViewController,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource {

    // MARK: - UI variables
    private var peopleList: [Contact] = Array()
    private var tableView: UITableView?
    private var userBuddiesChanged: Bool = false
    private var userGroupChanged: Bool = false
    private var segmentControll: UISegmentedControl?
    private var searchBarBackView: UIView?
    private var createGroupView : CreateGroupView?
    enum SegmentType : Int{
        case People = 0
        case Group = 1
    }
    private var searchBar: UISearchBar?
    var completionHandler: ((Bool) ->Void)?
    
    // MARK: - Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.Color.Theme.Background
        self.setUpSegmentControl()
        self.setUptableView()
    }
    
    // MARK: - WebexSDK: Listing people
    func requetPeopleList(searchStr: String){
        KTActivityIndicator.singleton.show(title: "Loading")
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
                    self.tableView?.reloadData()
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
                    self.tableView?.reloadData()
                    break
                case .failure:
                    break
                }
            }
        }
    }

    // MARK: WebexSDK: CALL Function Implementation
    /* webexSDK callwith contact model */
    public func makeWebexCall(_ contact: Contact){
        let callVC = BuddiesCallViewController(callee: contact)
        self.present(callVC, animated: true) {
            callVC.beginCall(isVideo: true)
        }
    }
    
    // MARK:  - UI Implementation
    func setUpSegmentControl(){
        if(self.segmentControll == nil){
            self.segmentControll = UISegmentedControl(items: ["People","Group"])
            self.segmentControll?.frame = CGRect(x: 0, y: 0, width: Constants.Size.screenWidth-120, height: 30)
            self.segmentControll?.addTarget(self, action: #selector(segmentClicked(sender:)), for: .valueChanged)
            self.segmentControll?.tintColor = UIColor.white
            
            let attr = NSDictionary(object: Constants.Font.InputBox.Button, forKey: NSAttributedStringKey.font as NSCopying)
            self.segmentControll?.setTitleTextAttributes(attr as [NSObject : AnyObject] , for: .normal)
            self.segmentControll?.selectedSegmentIndex = 0
            self.navigationItem.titleView = segmentControll
            let rightNavBarButton = UIBarButtonItem(image: UIImage(named: "icon_close"), style: .done, target: self, action: #selector(dismissVC))
            self.navigationItem.rightBarButtonItem = rightNavBarButton
        }
    }
    func setUpSearchBar() -> UIView{
        if(self.searchBar == nil){
            self.searchBarBackView = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Size.screenWidth, height: 40))
            self.searchBarBackView?.backgroundColor = Constants.Color.Theme.Background
            self.searchBar = UISearchBar(frame: CGRect(0, 0, Constants.Size.screenWidth, 40))
            self.searchBar?.tintColor = Constants.Color.Theme.Main
            self.searchBar?.becomeFirstResponder()
            self.searchBar?.delegate = self
            self.searchBar?.returnKeyType = .search
            self.searchBar?.showsCancelButton = true
            self.searchBarBackView?.addSubview(self.searchBar!)
        }
        return self.searchBarBackView!
    }
    
    func setUptableView(){
        if(self.tableView == nil){
            self.tableView = UITableView(frame: CGRect(0,0,Constants.Size.screenWidth,Constants.Size.screenHeight-64))
            self.tableView?.separatorStyle = .none
            self.tableView?.backgroundColor = Constants.Color.Theme.Background
            self.tableView?.delegate = self
            self.tableView?.dataSource = self
        }
        self.view.addSubview(self.tableView!)
    }
    
    func setUpCreateGroupView(){
        if(self.createGroupView == nil){
            self.createGroupView = CreateGroupView(frame: CGRect(x: 0.0, y: 0.0, width: CGFloat(Constants.Size.screenWidth), height: CGFloat(Constants.Size.screenHeight-CGFloat(Constants.Size.navHeight))))
            self.createGroupView?.groupCreateBlock = { (newGroup : Group) in
                if User.CurrentUser[newGroup.groupId!] == nil {
                    User.CurrentUser.addNewGroup(newGroup: newGroup)
                    self.userGroupChanged = true
                    self.dismissVC()
                }else {
                    KTInputBox.alert(title: "The user/group is already added")
                    return
                }
            }
        }
        self.view.addSubview(self.createGroupView!)
    }
    
    @objc func dismissVC(){
        self.searchBar?.resignFirstResponder()
        User.CurrentUser.clearContactSelection()
        if(self.completionHandler != nil){
            self.completionHandler!(self.userGroupChanged || self.userBuddiesChanged)
        }
        self.navigationController?.dismiss(animated: true, completion: {})
    }
    
    // MARK: SegmentControll Delegate
    @objc func segmentClicked(sender: UISegmentedControl){
        if(sender.selectedSegmentIndex == SegmentType.Group.rawValue){
            self.tableView?.removeFromSuperview()
            self.setUpCreateGroupView()
            if(self.createGroupView?.buddiesCollectionView != nil){
                self.createGroupView?.buddiesCollectionView?.reloadData()
            }
        }else{
            self.createGroupView?.removeFromSuperview()
            self.setUptableView()
        }
    }
    
    // MARK: SearchBar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchStr = searchBar.text{
            searchBar.resignFirstResponder()
            self.requetPeopleList(searchStr: searchStr)
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    // MARK: UITableView Delegate
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.setUpSearchBar()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(peopleTableCellHeight)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.peopleList.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let contackModel = self.peopleList[index]
        let cell = PeopleListTableCell(contactModel: contackModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.searchBar?.resignFirstResponder()
        let index = indexPath.row
        let contactModel = self.peopleList[index]
        
        let inputBox = KTInputBox(.Default(1));
        inputBox.title = "Add to Buddies"
        inputBox.customiseInputElement = {(element: UIView, index: Int) in
            if let element = element as? MKTextField {
                element.keyboardType = .emailAddress
                element.placeholder = "name@example.com";
                element.labelTitle = contactModel.name;
                element.floatingLabelTextColor = Constants.Color.Theme.Main
                element.text = contactModel.email
                element.isEnabled = false
            }
            return element
        }
        inputBox.onMiddle = { (_ btn: UIButton) in
            self.makeWebexCall(contactModel)
            return true
        }
        inputBox.customiseButton = { button, tag in
            if tag == 1 {
                button.setTitle("Add", for: .normal)
            }
            if(tag == 2){
                button.setTitle("Call", for: .normal)
            }
            return button;
        }
        
      
        
        inputBox.onSubmit = {(value: [AnyObject]) in
            if let email = value.first as? String, let _ = EmailAddress.fromString(email) {
                let singleGroupIdStr = email.md5
                if User.CurrentUser[singleGroupIdStr!] == nil {
                    User.CurrentUser.addNewContactAsGroup(contact: contactModel)
                    self.userBuddiesChanged = true
                    KTInputBox.alert(title: "Added successfully")
                    return true;
                }
                else {
                    KTInputBox.alert(title: "The user/group is already added")
                    return false;
                }
            }
            else {
                inputBox.shake()
                return false;
            }
        }
        inputBox.show()
    }
    
    // MARK: other functions
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
