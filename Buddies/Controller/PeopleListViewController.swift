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

enum AddBuddiesPageType : Int{
    case People = 0
    case Space = 1
}

class PeopleListViewController: BaseViewController,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource {

    // MARK: - UI variables
    public var spaceVC: SpaceViewController?
    private var peopleList: [Contact] = Array()
    private var tableView: UITableView?
    private var userBuddiesChanged: Bool = false
    private var segmentControll: UISegmentedControl?
    private var searchBarBackView: UIView?
    private var createSpaceView : CreateSpaceView?
    private var roomNavController: UINavigationController?
    private var searchBar: UISearchBar?
    private var pageType: AddBuddiesPageType
    var completionHandler: ((Bool) ->Void)?
    var spaceCreatedHandler: ((SpaceModel) -> Void)?
    
    init(pageType: AddBuddiesPageType){
        self.pageType = pageType
        super.init()
    }
    
    // MARK: - Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.Color.Theme.Background
        if pageType == .People{
            self.title = "Search Buddies"
            self.setUptableView()
        }
        else {
            self.title = "New Space"
            self.setUpCreateSpaceView()
        }
        let rightNavBarButton = UIBarButtonItem(image: UIImage(named: "icon_close"), style: .done, target: self, action: #selector(dismissVC))
        self.navigationItem.rightBarButtonItem = rightNavBarButton
    }
    
    // MARK: - WebexSDK: Listing people
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
    // MARK: WebexSDK: MESSAGE Function Implementation
    /* webexSDK callwith contact model */
    public func makeWebexMessage(_ contact: Contact){
        if let spaceModel = User.CurrentUser[contact.email] {
            spaceVC = SpaceViewController.init(space: spaceModel)
            let roomNavController = UINavigationController.init(rootViewController: spaceVC!)
            let backImageView = UIImageView.init(image: UIImage(named: "icon_back"))
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(dismissSpaceVC))
            singleTap.numberOfTapsRequired = 1;
            backImageView.isUserInteractionEnabled = true
            backImageView.addGestureRecognizer(singleTap)
            spaceVC!.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: backImageView)
            self.present(roomNavController, animated: true) {}
        }
    }
    
    // MARK:  - UI Implementation
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
    
    func setUpCreateSpaceView(){
        if(self.createSpaceView == nil){
            self.createSpaceView = CreateSpaceView(frame: CGRect(x: 0.0, y: 0.0, width: CGFloat(Constants.Size.screenWidth), height: CGFloat(Constants.Size.screenHeight-CGFloat(Constants.Size.navHeight))))
            self.createSpaceView?.spaceCreateBlock = { (newSpace : SpaceModel) in
                if let spaceCreatedHandler = self.spaceCreatedHandler {
                    spaceCreatedHandler(newSpace)
                    self.dismissVC()
                }
            }
        }
        self.view.addSubview(self.createSpaceView!)
    }
    
    @objc func dismissVC(){
        self.searchBar?.resignFirstResponder()
        if let completionHandler = self.completionHandler{
            completionHandler(self.userBuddiesChanged)
        }
        self.navigationController?.dismiss(animated: true, completion: {})
    }
    
    @objc func dismissSpaceVC(){
        self.navigationController?.dismiss(animated: true, completion: {})
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
        
        if User.CurrentUser[contactModel.email] == nil {
            User.CurrentUser.addNewContactAsSpace(contact: contactModel)
            self.userBuddiesChanged = true
        }
        
        let inputBox = KTInputBox(.Default(1));
        inputBox.title = "Buddies"
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
        
        inputBox.customiseButton = { button, tag in
            if tag == 1 {
                button.setTitle("Call", for: .normal)
            }
            if(tag == 2){
                button.setTitle("Message", for: .normal)
            }
            return button;
        }
        
        inputBox.onMiddle = { (_ btn: UIButton) in
            self.makeWebexMessage(contactModel)
            return true
        }
        
        inputBox.onSubmit = {(value: [AnyObject]) in
            self.makeWebexCall(contactModel)
            return true
        }
        
        inputBox.show()
    }
    
    // MARK: other functions
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
