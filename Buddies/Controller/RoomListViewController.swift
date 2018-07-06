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

class RoomListViewController: BaseViewController,UITableViewDelegate,UITableViewDataSource {

    // MARK: - UI variables
    private var tableView: UITableView?
    
    // MARK: - Life Circle
    override init(mainViewController: MainViewController) {
        super.init(mainViewController : mainViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.Color.Theme.Background
        self.title = "Rooms"
        self.setUptableView()
        self.updateNavigationItems()
    }
    
    // MARK: - WebexSDK: listing rooms / delete rooms
    func webexListRooms(){
        WebexSDK?.rooms.list(completionHandler: { (response: ServiceResponse<[Room]>) in
            switch response.result {
            case .success(let roomList):
                for room in roomList{
                    let roomModel = RoomModel(room: room)
                    User.CurrentUser.addLocalRoom(room: roomModel!)
                    self.tableView?.reloadData()
                }
                break
            case .failure:
                break
            }
        })
    }
    func removeRoomAt(_ indexPath: IndexPath){
        let roomModel = User.CurrentUser.rooms[indexPath.row]
        KTActivityIndicator.singleton.show(title: "Loading")
        WebexSDK?.rooms.delete(roomId: roomModel.roomId) { (response: ServiceResponse<Any>) in
            KTActivityIndicator.singleton.hide()
            User.CurrentUser.rooms.remove(at: indexPath.row)
            self.tableView?.deleteRows(at: [indexPath], with: .top)
            User.CurrentUser.saveLocalRooms()
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
    private func updateNavigationItems() {
        var avator: UIImageView?
        if(User.CurrentUser.loginType == .User){
            avator = User.CurrentUser.avator
            if let avator = avator {
                avator.setCorner(Int(avator.frame.height / 2))
            }
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewRoom))
        }else {
            avator = UIImageView(frame: CGRect(0, 0, 28, 28))
            avator?.image = UIImage.fontAwesomeIcon(name: .userCircleO, textColor: UIColor.white, size: CGSize(width: 28, height: 28))
            self.navigationItem.rightBarButtonItem = nil
        }
        if let avator = avator {
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(showUserOptionView))
            singleTap.numberOfTapsRequired = 1;
            avator.isUserInteractionEnabled = true
            avator.addGestureRecognizer(singleTap)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avator)
        }
    }
    
    func messageNotiReceived(noti: Notification){
        self.tableView?.reloadData()
    }
    
    // MARK: UITableView Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(roomTableCellHeight)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(User.CurrentUser.loginType == .Guest){
            return 0
        }
        return (User.CurrentUser.localRoomCount)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let roomModel = User.CurrentUser.rooms[index]
        let cell = RoomListTableCell(roomModel: roomModel)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let roomModel = User.CurrentUser.rooms[index]
        let roomVC = RoomViewController(room: roomModel)
        if let roomGroup = User.CurrentUser[(roomModel.localGroupId)]{
            if(roomGroup.unReadedCount>0){
                roomGroup.unReadedCount = 0
                self.tableView?.reloadData()
            }
        }
        self.navigationController?.pushViewController(roomVC, animated: true)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let tableActions = UITableViewRowAction(style: .destructive, title: "Delete") { (rowAction, indexPath) in
            self.removeRoomAt(indexPath)
        }
        return [tableActions]
    }

    
    @objc private func createNewRoom(){
        
        let createRoomView = CreateRoomView(frame: CGRect(x: 0, y: 0, width: Constants.Size.screenWidth, height: Constants.Size.screenHeight))
        createRoomView.roomCreatedBlock = { (createdRoom : RoomModel, isNew : Bool) in
            if(isNew){
                User.CurrentUser.insertLocalRoom(room: createdRoom, atIndex: 0)
                self.tableView?.reloadData()
            }

            let roomVC = RoomViewController(room: createdRoom)
            self.navigationController?.pushViewController(roomVC, animated: true)
        }
        createRoomView.popUpOnWindow()
    }
    
    
    // MARK: BaseViewController Functions Override
    override func updateViewController() {
        self.updateNavigationItems()
        self.tableView?.reloadData()
    }
    
    @objc private func showUserOptionView() {
        self.mainController?.slideInUserOptionView()
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
