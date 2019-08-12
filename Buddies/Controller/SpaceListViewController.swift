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

class SpaceListViewController: HomeViewController,UITableViewDelegate,UITableViewDataSource {

    // MARK: - UI variables
    private var tableView: UITableView?
    private let maxSpaceCount = 6
    private var spaceList: Array<SpaceModel> = Array<SpaceModel>()
    private var spaceVC : SpaceViewController?
    private var callVC: BuddiesCallViewController?
    
    // MARK: - Life Circle
    override init(mainViewController: MainViewController) {
        super.init(mainViewController : mainViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.Color.Theme.Background
        self.title = "Spaces"
        self.updateNavigationItems()
        self.webexListSpaces()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.spaceVC = nil
    }
    
    // MARK: - WebexSDK: listing spaces / delete spaces
    func webexListSpaces(){
        acitivtyIndicator.show(title: "Loading...", at: (self.view)!, offset: 0, size: 156, allowUserInteraction: false)
        WebexSDK?.spaces.list(max: maxSpaceCount, type: SpaceType.group){ (response: ServiceResponse<[Space]>) in
            self.acitivtyIndicator.hide()
            switch response.result {
            case .success(let spaceList):
                spaceList.forEach({ space in
                    let model = SpaceModel(space: space)
                    if let _ = self.mainController?.messageUnreadDict[model.spaceId] {
                        model.unReadedCount += 1
                    }
                    self.spaceList.append(model)
                })
                self.mainController?.messageUnreadDict.removeAll()
                self.setUptableView()
                break
            case .failure:
                break
            }
        }
    }
    
    func requestRoomMembers( _ indexPath: IndexPath) {
        let spaceModel = self.spaceList[indexPath.row]
        if spaceModel.spaceMembers.isEmpty {
            self.acitivtyIndicator.show(title: "Loading...")
            WebexSDK?.memberships.list(spaceId: spaceModel.spaceId) { (response: ServiceResponse<[Membership]>) in
                switch response.result {
                case .success(let value):
                    let members = value.filter({!($0.personEmail?.toString().contains("bot@cisco.com"))!})
                    var count = 0
                    members.forEach{ membership in
                        DispatchQueue.global().async(execute: DispatchWorkItem(block: {
                            WebexSDK?.people.get(personId: membership.personId!, completionHandler: { (response: ServiceResponse<Person>) in
                                if let person = response.result.data {
                                    count += 1
                                    let contact = Contact(person: person)
                                    spaceModel.spaceMembers.append(contact!)
                                    if count == members.count{
                                        self.callSapceAt(spaceModel)
                                    }
                                }
                            })
                        }))
                    }
                    break
                case .failure:
                    break
                }
            }
        }else{
            self.callSapceAt(spaceModel)
        }
    }
    
    func callSapceAt( _ spaceModel: SpaceModel){
        self.acitivtyIndicator.hide()
        self.callVC = BuddiesCallViewController(space: spaceModel)
        self.present(self.callVC!, animated: true) {
            self.callVC?.beginCall(isVideo: true)
        }
    }
    
    func removeSpaceAt(_ indexPath: IndexPath){
        let spaceModel = self.spaceList[indexPath.row]
        KTActivityIndicator.singleton.show(title: "Leaving...")
        WebexSDK?.spaces.delete(spaceId: spaceModel.spaceId) { (response: ServiceResponse<Any>) in
            KTActivityIndicator.singleton.hide()
            self.spaceList.remove(at: indexPath.row)
            self.tableView?.reloadData()
        }
    }

    // MARK: - UI Implementation
    func setUptableView(){
        if(self.tableView == nil){
            self.tableView = UITableView(frame: CGRect(0,0,Constants.Size.screenWidth,Constants.Size.screenHeight-64))
            self.tableView?.separatorStyle = .none
            self.tableView?.backgroundColor = Constants.Color.Theme.Background
            self.tableView?.delegate = self
            self.tableView?.dataSource = self
            self.view.addSubview(self.tableView!)
        }
        else {
            self.tableView?.reloadData()
        }
    }

    public func receiveNewMessage( _ messageModel: Message){
        if let spaceVC = self.spaceVC, let spaceModel = self.spaceVC?.spaceModel, messageModel.spaceId == spaceModel.spaceId{
            if messageModel.spaceId == spaceModel.spaceId{
                spaceVC.receiveNewMessage(message: messageModel)
                return
            } else{
                if let idx = self.spaceList.indexOfEquatable({$0.spaceId == messageModel.spaceId}){
                    self.spaceList[idx].unReadedCount += 1
                }
                self.tableView?.reloadData()
            }
            return
        } else if let callVC = self.callVC, let spaceModel = self.callVC?.spaceModel{
            if messageModel.spaceId == spaceModel.spaceId{
                callVC.receiveNewMessage(message: messageModel)
                return
            } else{
                if let space = User.CurrentUser[messageModel.personEmail!]{
                    space.unReadedCount += 1
                    self.tableView?.reloadData()
                }
            }
        }
        else {
            if let idx = self.spaceList.firstIndex(where: {$0.spaceId == messageModel.spaceId}) {
                spaceList[idx].unReadedCount += 1
            }
            self.tableView?.reloadData()
        }
    }
    
    @objc private func addSpaceBtnClicked(sender: UIBarButtonItem) {
        let peopleListVC = PeopleListViewController(pageType: .Space)
        peopleListVC.spaceCreatedHandler = { newSpace in
            self.spaceList.insert(newSpace, at: 0)
            self.tableView?.reloadData()
        }
        let peopleNavVC = UINavigationController(rootViewController: peopleListVC)
        self.navigationController?.present(peopleNavVC, animated: true, completion: {})
    }
    
    // MARK: UITableView Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(spaceTableCellHeight)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(User.CurrentUser.loginType == .Guest){
            return 0
        }
        return spaceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let spaceModel = spaceList[index]
        let cell = SpaceListTableCell(spaceModel: spaceModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let spaceModel = spaceList[index]
        self.spaceVC = SpaceViewController(space: spaceModel)
        if(spaceModel.unReadedCount>0){
            spaceModel.unReadedCount = 0
            self.tableView?.reloadData()
        }
        self.navigationController?.pushViewController(self.spaceVC!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let callAction = UITableViewRowAction(style: .normal, title: "Call") { (rowAction, indexPath) in
            self.requestRoomMembers(indexPath)
        }
        callAction.backgroundColor = UIColor.MKColor.Green.P700
        let leaveAction = UITableViewRowAction(style: .destructive, title: "Leave") { (rowAction, indexPath) in
            self.confirmToLeave(indexPath)
        }
        return [leaveAction,callAction]
    }
    
    func confirmToLeave(_ indexPath: IndexPath) {
        let alertView = UIAlertController.init(title: "Leave Confirm", message: "Are you sure to leave?", preferredStyle: .alert)
        let action1 = UIAlertAction.init(title: "Leave", style: .destructive) { _ in
            self.removeSpaceAt(indexPath)
        }
        let action2 = UIAlertAction.init(title: "Cancel", style: .cancel)
        alertView.addAction(action1)
        alertView.addAction(action2)
        self.present(alertView, animated: true)
    }

    // MARK: - BaseViewController Functions Override
    override func updateViewController() {
        self.updateNavigationItems()
        if (User.CurrentUser.loginType == .User) {
            self.webexListSpaces()
        }
        else {
            self.spaceList.removeAll()
            self.tableView?.reloadData()
        }
    }
    
    override func updateNavigationItems() {
        super.updateNavigationItems()
        if (User.CurrentUser.loginType == .User) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSpaceBtnClicked(sender:)))
        }
    }
    
    @objc private func reloadTableData(){
        self.tableView?.reloadData()
    }
    
    // MARK: - other functions
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
