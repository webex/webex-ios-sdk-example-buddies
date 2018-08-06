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

class TeamListViewController: HomeViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - UI variables
    private var teamList: [Team] = Array()
    private var tableView: UITableView?
    
    
    // MARK: - Life Circle
    override init(mainViewController: MainViewController) {
        super.init(mainViewController : mainViewController)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.Color.Theme.Background
        self.title = "Teams"
        self.setUptableView()
        self.updateNavigationItems()
        self.requestTeamList()
    }
    
    // MARK: - WebexSDK: listig team / create space
    private func requestTeamList(){
        KTActivityIndicator.singleton.show(title: "Loading...")
        WebexSDK?.teams.list(max: 20) {
            (response: ServiceResponse<[Team]>) in
            KTActivityIndicator.singleton.hide()
            switch response.result {
            case .success(let value):
                self.teamList.removeAll()
                for team in value{
                    self.teamList.append(team)
                }
                self.tableView?.reloadData()
                break
            case .failure:
                break
            }
        }
    }
    
    private func createNewTeam(teamName: String){
        KTActivityIndicator.singleton.show(title: "Adding")
        WebexSDK?.teams.create(name: teamName) { (response: ServiceResponse<Team>) in
            KTActivityIndicator.singleton.hide()
            switch response.result {
            case .success(let value):
                self.teamList.insert(value, at: 0)
                self.tableView?.reloadData()
                break
            case .failure:
                break
            }
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
    
    override func updateNavigationItems() {
        if(User.CurrentUser.loginType == .User){
            avator = User.CurrentUser.avator
            if let avator = avator {
                avator.setCorner(Int(avator.frame.height / 2))
            }
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTeam))
        }else {
            avator = UIImageView(frame: CGRect(0, 0, 28, 28))
            avator?.image = UIImage.fontAwesomeIcon(name: .userCircleO, textColor: UIColor.white, size: CGSize(width: 28, height: 28))
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(teamTableCellHeight)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(User.CurrentUser.loginType == .Guest || User.CurrentUser.loginType == .None){
            return 0
        }
        return (self.teamList.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let teamModel = self.teamList[index]
        let cell = TeamListTableCell(teamModel: teamModel)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let index = indexPath.row
//        let teamModel = self.teamList[index]
    }
    
    @objc private func addTeam(){
        let inputBox = KTInputBox(.Default(1));
        inputBox.title = "New Team"
        inputBox.customiseInputElement = {(element: UIView, index: Int) in
            if let element = element as? MKTextField {
                element.keyboardType = .emailAddress
                element.placeholder = "Team Name";
            }
            return element
        }
        inputBox.onSubmit = {(value: [AnyObject]) in
            if let teamName = value.first as? String{
                if(teamName == ""){
                    inputBox.shake()
                    return false
                }
                self.createNewTeam(teamName: teamName)
                return true
            }
            else {
                inputBox.shake()
                return false;
            }
        }
        inputBox.show()
    }
    
    // MARK: BaseViewController Functions Override
    override func updateViewController() {
        self.updateNavigationItems()
        self.tableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
