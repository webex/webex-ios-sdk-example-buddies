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

class SpaceListViewController: HomeViewController,UITableViewDelegate,UITableViewDataSource {

    // MARK: - UI variables
    private var tableView: UITableView?
    private let maxSpaceCount = 6
    private var spaceList: Array<SpaceModel> = Array<SpaceModel>()
    
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
    
    // MARK: - WebexSDK: listing spaces / delete spaces
    func webexListSpaces(){
        acitivtyIndicator.show(title: "Loading...", at: (self.view)!, offset: 0, size: 156, allowUserInteraction: false)
        WebexSDK?.spaces.list(max: maxSpaceCount, type: SpaceType.group){ (response: ServiceResponse<[Space]>) in
            self.acitivtyIndicator.hide()
            switch response.result {
            case .success(let spaceList):
                spaceList.forEach({ space in
                    let model = SpaceModel(space: space)
                    self.spaceList.append(model!)
                })
                self.setUptableView()
                break
            case .failure:
                break
            }
        }
    }
    
    func removeSpaceAt(_ indexPath: IndexPath){
        let spaceModel = User.CurrentUser.spaces[indexPath.row]
        KTActivityIndicator.singleton.show(title: "Loading")
        WebexSDK?.spaces.delete(spaceId: spaceModel.spaceId) { (response: ServiceResponse<Any>) in
            KTActivityIndicator.singleton.hide()
            User.CurrentUser.spaces.remove(at: indexPath.row)
            self.tableView?.deleteRows(at: [indexPath], with: .top)
            User.CurrentUser.saveLocalSpaces()
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
    }

    func messageNotiReceived(noti: Notification){
        self.tableView?.reloadData()
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
        let spaceVC = SpaceViewController(space: spaceModel)
        if let spaceGroup = User.CurrentUser[(spaceModel.localGroupId)]{
            if(spaceGroup.unReadedCount>0){
                spaceGroup.unReadedCount = 0
                self.tableView?.reloadData()
            }
        }
        self.navigationController?.pushViewController(spaceVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let tableActions = UITableViewRowAction(style: .destructive, title: "Delete") { (rowAction, indexPath) in
            self.removeSpaceAt(indexPath)
        }
        return [tableActions]
    }

    @objc private func createNewSpace(){
        
        let createSpaceView = CreateSpaceView(frame: CGRect(x: 0, y: 0, width: Constants.Size.screenWidth, height: Constants.Size.screenHeight))
        createSpaceView.spaceCreatedBlock = { (createdSpace : SpaceModel, isNew : Bool) in
            if(isNew){
                User.CurrentUser.insertLocalSpace(space: createdSpace, atIndex: 0)
                self.tableView?.reloadData()
            }

            let spaceVC = SpaceViewController(space: createdSpace)
            self.navigationController?.pushViewController(spaceVC, animated: true)
        }
        createSpaceView.popUpOnWindow()
    }
    
    // MARK: BaseViewController Functions Override
    override func updateViewController() {
        self.updateNavigationItems()
        self.tableView?.reloadData()
    }
    
    @objc private func reloadTableData(){
        self.tableView?.reloadData()
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
