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
import Cartography

class GuestSettingViewController: BaseViewController,UITextViewDelegate,UITextFieldDelegate{

    // MARK: - UI variables
    public var signInSuccessBlock: (()->())?
    private var configurationView: UIView?
    private var peopleListView: UIView?
    private var tokenTextView: UITextView?
    private var healthcareProTF: MKTextField?
    private var financialAdPTF: MKTextField?
    private var customerCareTF: MKTextField?
    private var addedEmailDict: Dictionary<String,String>?
    private var spaceVC : SpaceViewController?
    private var callVC: BuddiesCallViewController?
    
    // MARK : - Life Circle
    override func viewDidLoad() {
        if(User.CurrentUser.loginType == .None){
            self.title = "Configuration"
        }else{
            self.title = "Guest Experience"
        }
        super.viewDidLoad()
        self.checkWebexRegister()
        self.updateBarItem()
        self.setUpSubViews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - WebexSDK CALL/Message Function Implementation
    @objc
    public func makeWebexCall(sender: UIButton){
        let index = sender.tag - 20000
        let space = User.CurrentUser[index]!
        if(space.type == SpaceType.direct){
            let contact = space.contact!
            self.callVC = BuddiesCallViewController(callee: contact)
            self.present(self.callVC!, animated: true) {
                self.callVC?.beginCall(isVideo: true)
            }
        }
    }
    
    @objc public func makeWebexMessage(sender: UIButton){
        let index = sender.tag - 20000
        let spaceModel = User.CurrentUser[index]!
        spaceModel.unReadedCount = 0
        if let unreadLabel = self.view.viewWithTag(index+10000){
            unreadLabel.removeFromSuperview()
        }
        self.spaceVC = SpaceViewController(space: spaceModel)
        self.navigationController?.pushViewController(self.spaceVC!, animated: true)
    }
    
    public func receiveNewMessage( _ messageModel: Message){
        if let spaceVC = self.spaceVC, let spaceModel = self.spaceVC?.spaceModel{
            if messageModel.personEmail == spaceModel.localSpaceId{
                spaceVC.receiveNewMessage(message: messageModel)
                return
            } else{
                if let space = User.CurrentUser[messageModel.personEmail!]{
                    space.unReadedCount += 1
                    self.updateUnreadedLabels()
                }
            }
        }
        else if let callVC = self.callVC, let spaceModel = self.callVC?.spaceModel{
            if messageModel.personEmail == spaceModel.localSpaceId{
                callVC.receiveNewMessage(message: messageModel)
                return
            } else{
                if let space = User.CurrentUser[messageModel.personEmail!]{
                    space.unReadedCount += 1
                    self.updateUnreadedLabels()
                }
            }
        }
        else{
            if let space = User.CurrentUser[messageModel.personEmail!]{
                space.unReadedCount += 1
                self.updateUnreadedLabels()
            }
        }
    }

    
    // MARK: - UI Implementation
    private func updateBarItem() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVC))
    }
    
    private func setUpSubViews(){
        if(User.CurrentUser.loginType == .None){
            self.setUpConfiguartionView()
        }else{
            self.setUpPeopleListView()
        }
    }
    
    @objc private func setUpConfiguartionView(){
        if(self.peopleListView != nil){
            self.peopleListView?.removeFromSuperview()
        }
        let viewWidth = Constants.Size.screenWidth
        let viewHeight = Constants.Size.screenHeight
        self.configurationView = UIView(frame: CGRect(0,0,viewWidth,viewHeight))
        self.view.addSubview(self.configurationView!)
        
        var tokenInputHeight = 0
        if(User.CurrentUser.loginType == .None){
            let homeTitleLabel = UILabel(frame: CGRect(30,15,viewWidth-30,40))
            homeTitleLabel.text = "1st Time Guest Configuration"
            homeTitleLabel.textAlignment = .left
            homeTitleLabel.font = Constants.Font.NavigationBar.BigTitle
            homeTitleLabel.textColor = Constants.Color.Theme.Main
            
            self.configurationView?.addSubview(homeTitleLabel)
            
            let jwtTitleLabel = UILabel(frame: CGRect(30,50,viewWidth,20))
            jwtTitleLabel.text = "Developer JWT Token"
            jwtTitleLabel.textAlignment = .left
            jwtTitleLabel.font = Constants.Font.NavigationBar.Title
            jwtTitleLabel.textColor = Constants.Color.Theme.Main
            self.configurationView?.addSubview(jwtTitleLabel)
            
            self.tokenTextView = UITextView(frame: CGRect(x: 30, y: 75, width: viewWidth-60, height: 100))
            self.tokenTextView?.textAlignment = .center
            self.tokenTextView?.tintColor = Constants.Color.Theme.Main
            self.tokenTextView?.layer.borderColor = UIColor.clear.cgColor
            self.tokenTextView?.font = Constants.Font.InputBox.Input
            self.tokenTextView?.textAlignment = .left
            self.tokenTextView?.returnKeyType = .done;
            self.tokenTextView?.layer.cornerRadius = 5.0
            self.tokenTextView?.layer.borderColor = Constants.Color.Theme.Main.cgColor
            self.tokenTextView?.layer.borderWidth = 1.0
            self.tokenTextView?.delegate = self
            self.configurationView?.addSubview(self.tokenTextView!)
            
            tokenInputHeight = 175
        }
        
        let emailTitleLabel = UILabel(frame: CGRect(30,tokenInputHeight + 15,Int(viewWidth),20))
        emailTitleLabel.text = "Webex Email Address for"
        emailTitleLabel.textAlignment = .left
        emailTitleLabel.font = Constants.Font.NavigationBar.Title
        emailTitleLabel.textColor = Constants.Color.Theme.Main
        self.configurationView?.addSubview(emailTitleLabel)
        
        let healthCareLabel = UILabel(frame: CGRect(30,tokenInputHeight + 35,Int(viewWidth/2-45),40))
        healthCareLabel.text = "Healthcare Provider:"
        healthCareLabel.textAlignment = .left
        healthCareLabel.font = Constants.Font.NavigationBar.Title
        healthCareLabel.textColor = Constants.Color.Theme.Main
        self.configurationView?.addSubview(healthCareLabel)
        
        self.healthcareProTF = MKTextField(frame:  CGRect(x: viewWidth/2-15, y: CGFloat(tokenInputHeight + 40), width: viewWidth/2, height: CGFloat(30)))
        self.healthcareProTF?.delegate = self
        self.healthcareProTF?.textAlignment = .left
        self.healthcareProTF?.tintColor = Constants.Color.Theme.Main;
        self.healthcareProTF?.layer.borderColor = UIColor.clear.cgColor
        self.healthcareProTF?.font = Constants.Font.InputBox.Input
        self.healthcareProTF?.backgroundColor = UIColor.white
        self.healthcareProTF?.floatingPlaceholderEnabled = false
        self.healthcareProTF?.rippleEnabled = false;
        self.healthcareProTF?.placeholder = "Email"
        self.healthcareProTF?.returnKeyType = .done;
        self.configurationView?.addSubview(self.healthcareProTF!)
        
        
        let financialLabel = UILabel(frame: CGRect(30,tokenInputHeight+80,Int(viewWidth/2-45),40))
        financialLabel.text = "Financial Adviser:"
        financialLabel.textAlignment = .left
        financialLabel.font = Constants.Font.NavigationBar.Title
        financialLabel.textColor = Constants.Color.Theme.Main
        self.configurationView?.addSubview(financialLabel)
        
        self.financialAdPTF = MKTextField(frame:  CGRect(x: viewWidth/2-15, y: CGFloat(tokenInputHeight + 85), width: viewWidth/2, height: CGFloat(30)))
        self.financialAdPTF?.delegate = self
        self.financialAdPTF?.textAlignment = .left
        self.financialAdPTF?.tintColor = Constants.Color.Theme.Main;
        self.financialAdPTF?.layer.borderColor = UIColor.clear.cgColor
        self.financialAdPTF?.font = Constants.Font.InputBox.Input
        self.financialAdPTF?.backgroundColor = UIColor.white
        self.financialAdPTF?.floatingPlaceholderEnabled = false
        self.financialAdPTF?.rippleEnabled = false;
        self.financialAdPTF?.placeholder = "Email"
        self.financialAdPTF?.returnKeyType = .done;
        self.configurationView?.addSubview(self.financialAdPTF!)
        
        let customerLabel = UILabel(frame: CGRect(30,tokenInputHeight + 125,Int(viewWidth/2-45),40))
        customerLabel.text = "Customer Care Agent:"
        customerLabel.textAlignment = .left
        customerLabel.font = Constants.Font.NavigationBar.Title
        customerLabel.textColor = Constants.Color.Theme.Main
        self.configurationView?.addSubview(customerLabel)
        
        self.customerCareTF = MKTextField(frame:  CGRect(x: viewWidth/2-15, y: CGFloat(tokenInputHeight + 130), width: viewWidth/2, height: CGFloat(30)))
        self.customerCareTF?.delegate = self
        self.customerCareTF?.textAlignment = .left
        self.customerCareTF?.tintColor = Constants.Color.Theme.Main;
        self.customerCareTF?.layer.borderColor = UIColor.clear.cgColor
        self.customerCareTF?.font = Constants.Font.InputBox.Input
        self.customerCareTF?.backgroundColor = UIColor.white
        self.customerCareTF?.floatingPlaceholderEnabled = false
        self.customerCareTF?.rippleEnabled = false;
        self.customerCareTF?.placeholder = "Email"
        self.customerCareTF?.returnKeyType = .done;
        self.configurationView?.addSubview(self.customerCareTF!)
    
        let initBtn = UIButton(frame: CGRect(x: 30, y: tokenInputHeight + 185, width: Int(viewWidth - 60), height: 40))
        initBtn.backgroundColor = Constants.Color.Theme.Main
        if(User.CurrentUser.loginType == .Guest){
            initBtn.setTitle("Update Guest Configuration", for: .normal)
        }else{
            initBtn.setTitle("Initialize Guest Configuration", for: .normal)
        }

        initBtn.setTitleColor(UIColor.white, for: .normal)
        initBtn.titleLabel?.font = Constants.Font.NavigationBar.Title
        initBtn.layer.cornerRadius = 20.0
        initBtn.layer.masksToBounds = true
        initBtn.addTarget(self, action: #selector(authenticateWithJWT), for: .touchUpInside)
        self.configurationView?.addSubview(initBtn)
        
        if(User.CurrentUser.loginType == .Guest){
            for index in 0..<User.CurrentUser.spaceCount{
                let space = User.CurrentUser[index]
                if(space?.title == "Healthcare Provider"){
                   self.healthcareProTF?.text = space?.localSpaceId
                }
                if(space?.title == "Financial Advisor"){
                    self.financialAdPTF?.text = space?.localSpaceId
                }
                if(space?.title == "Customer Care Agent"){
                    self.customerCareTF?.text = space?.localSpaceId
                }
            }
        }
    }
    
    private func setUpPeopleListView(){
        KTActivityIndicator.singleton.hide()
        self.title = "Guest Experience"
        let viewWidth = Constants.Size.screenWidth
        let viewHeight = Constants.Size.screenHeight
        if(self.configurationView != nil){
            self.configurationView?.removeFromSuperview()
        }
        
        if(self.peopleListView != nil){
            self.peopleListView?.removeFromSuperview()
        }
        
        self.peopleListView = UIView(frame: CGRect(0,0,viewWidth,viewHeight))
        self.view.addSubview(self.peopleListView!)
        
        let homeTitleLabel = UILabel(frame: CGRect(30,15,viewWidth-30,40))
        homeTitleLabel.text = "Buddies Guest User Experience"
        homeTitleLabel.textAlignment = .center
        homeTitleLabel.font = Constants.Font.NavigationBar.BigTitle
        homeTitleLabel.textColor = Constants.Color.Theme.Main
        
        self.peopleListView?.addSubview(homeTitleLabel)
        
        for index in 0..<User.CurrentUser.spaceCount{
            let space = User.CurrentUser[index]
            let initBtn = UIButton(frame: CGRect(x: 30, y: 80+50*index, width: Int(viewWidth - 100), height: 40))
            initBtn.backgroundColor = Constants.Color.Theme.Main
            initBtn.setTitle("Call " + (space?.title)!, for: .normal)
            initBtn.setTitleColor(UIColor.white, for: .normal)
            initBtn.titleLabel?.font = Constants.Font.NavigationBar.Title
            initBtn.layer.cornerRadius = 20.0
            initBtn.layer.masksToBounds = true
            initBtn.tag = 20000+index
            
            let messageBtn = UIButton(frame: CGRect(x: Int(viewWidth - 65), y: 80+50*index, width: Int(42), height: 42))
            messageBtn.backgroundColor = Constants.Color.Theme.Main
            messageBtn.setImage(UIImage(named: "text_message"), for: .normal)
            messageBtn.setTitleColor(UIColor.white, for: .normal)
            messageBtn.titleLabel?.font = Constants.Font.NavigationBar.Title
            messageBtn.layer.cornerRadius = 20.0
            messageBtn.layer.masksToBounds = true
            messageBtn.tag = 20000+index
            
            if(space?.localSpaceId != ""){
                initBtn.addTarget(self, action: #selector(makeWebexCall(sender:)), for: .touchUpInside)
                messageBtn.addTarget(self, action: #selector(makeWebexMessage(sender:)), for: .touchUpInside)
            }else{
                initBtn.backgroundColor = UIColor.gray
                messageBtn.backgroundColor = UIColor.gray
            }
            
            self.peopleListView?.addSubview(initBtn)
            self.peopleListView?.addSubview(messageBtn)
        }
        
        let settingBtn = UIButton(type: .custom)
        settingBtn.frame = CGRect(x: 30, y: 80 + 50*User.CurrentUser.spaceCount+20, width: (Int(viewWidth-60)), height: 20)
        settingBtn.titleLabel?.font = Constants.Font.InputBox.Button
        settingBtn.tag = UserOptionType.GuestLogin.rawValue
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        let attStringSaySomething1 = NSAttributedString.init(string: "Configuration",
                                                             attributes: [NSAttributedString.Key.font: Constants.Font.NavigationBar.Button, NSAttributedString.Key.foregroundColor:Constants.Color.Theme.Main,
                                                                          NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                          NSAttributedString.Key.paragraphStyle: paragraph])
        
        settingBtn.setAttributedTitle(attStringSaySomething1, for: .normal)
        settingBtn.addTarget(self, action: #selector(setUpConfiguartionView), for: .touchUpInside)
        self.peopleListView?.addSubview(settingBtn)

    }
    
    func updateUnreadedLabels(){
        let viewWidth = Constants.Size.screenWidth
        for index in 0..<User.CurrentUser.spaceCount{
            let space = User.CurrentUser[index]
            if(space?.unReadedCount != 0){
                if let unreadedLabel = self.peopleListView?.viewWithTag(10000+index){
                    (unreadedLabel as! UILabel).text = String(describing: (space?.unReadedCount)!)
                }else{
                    let unreadedLabel = UILabel(frame: CGRect(x: Int(viewWidth - 36), y: 80+50*index, width: Int(16), height: 16))
                    unreadedLabel.backgroundColor = Constants.Color.Theme.Main
                    unreadedLabel.layer.borderColor = UIColor.white.cgColor
                    unreadedLabel.layer.borderWidth = 2.0
                    unreadedLabel.layer.cornerRadius = 8
                    unreadedLabel.layer.masksToBounds = true
                    unreadedLabel.textAlignment = .center
                    unreadedLabel.tag = 10000+index
                    self.peopleListView?.addSubview(unreadedLabel)
                }
            }
        }
    }
    
    
    // MARK: - WebexSDK: JWT Authentication Implementation
    @objc
    func authenticateWithJWT(){
        self.addedEmailDict = Dictionary()
        if(self.healthcareProTF?.text != nil && self.healthcareProTF?.text?.length != 0){
            if let _ = EmailAddress.fromString((self.healthcareProTF?.text)!){
                self.addedEmailDict?["Healthcare Provider"] = self.healthcareProTF?.text!
            }else{
                KTInputBox.alert(title: "HealthCareProvider Email Invalid")
                return
            }
        }
        if(self.financialAdPTF?.text != nil && self.financialAdPTF?.text?.length != 0){
            if let _ = EmailAddress.fromString((self.financialAdPTF?.text)!){
                self.addedEmailDict?["Financial Advisor"] = self.financialAdPTF?.text!
            }else{
                KTInputBox.alert(title: "FinancialAdviser Email Invalid")
                return
            }
        }
        
        if(self.customerCareTF?.text != nil && self.customerCareTF?.text?.length != 0){
            if let _ = EmailAddress.fromString((self.customerCareTF?.text)!){
                self.addedEmailDict?["Customer Care Agent"] = self.customerCareTF?.text!
            }else{
                KTInputBox.alert(title: "Customer Care Agent Email Invalid")
                return
            }
        }
        
        if(self.addedEmailDict?.count == 0){
            KTInputBox.alert(title: "At least one Email Needed")
            return
        }
        
        self.healthcareProTF?.resignFirstResponder()
        self.financialAdPTF?.resignFirstResponder()
        self.tokenTextView?.resignFirstResponder()
        
        if(User.CurrentUser.loginType == .Guest){
            self.updateContacts()
        }else{
            let jwtStr = self.tokenTextView?.text
            let jwtAuthStrategy = JWTAuthenticator()
            
            jwtAuthStrategy.authorizedWith(jwt: jwtStr!)
            
            if jwtAuthStrategy.authorized == true {
                WebexSDK = Webex(authenticator: jwtAuthStrategy)
                KTActivityIndicator.singleton.show(title: "Loading...")
                WebexSDK?.people.getMe { res in
                    if let person = res.result.data {
                        if(User.updateCurrenUser(person: person, loginType: .Guest)){
                            User.CurrentUser.updateJwtString(jwtStr: jwtStr!)
                        }
                        if(self.signInSuccessBlock != nil){
                            self.signInSuccessBlock!()
                        }
                        self.updateContacts()
                    }else if let error = res.result.error {
                        KTActivityIndicator.singleton.hide()
                        KTInputBox.alert(error: error)
                    }
                }
            } else {
                KTActivityIndicator.singleton.hide()
                KTInputBox.alert(title: "Invalid Key")
            }
        }
    }
    
    public func checkWebexRegister(){
        if(User.CurrentUser.phoneRegisterd){
            WebexSDK?.messages.onEvent = { event in
                switch event{
                case .messageReceived(let message):
                    self.receiveNewMessage(message)
                    break
                case .messageDeleted( _):
                    break
                }
            }
        }
    }
    
    // MARK: - UI Logic Implementation
    @objc private func dismissVC(){
        self.healthcareProTF?.resignFirstResponder()
        self.financialAdPTF?.resignFirstResponder()
        self.customerCareTF?.resignFirstResponder()
        self.tokenTextView?.resignFirstResponder()
        self.dismiss(animated: true) {}
    }
    private func addContacts(){
        if(User.CurrentUser.spaceCount == 0){
            for element in self.addedEmailDict!{
                WebexSDK?.people.list(email: EmailAddress.fromString(element.value), displayName: nil, max: 1) { res in
                    if let person = res.result.data?.first, let contact = Contact(person: person) {
                        contact.name = element.key
                        User.CurrentUser.addNewContactAsSpace(contact: contact)
                        if(User.CurrentUser.spaceCount == self.addedEmailDict?.count){
                            self.setUpPeopleListView()
                        }
                    }else{
                        let tempContact = Contact(id: "", name: element.key, email: element.value)
                        User.CurrentUser.addNewContactAsSpace(contact: tempContact)
                        if(User.CurrentUser.spaceCount == self.addedEmailDict?.count){
                            self.setUpPeopleListView()
                        }
                    }
                }
            }
        }else{
            self.setUpPeopleListView()
        }
    }
    private func updateContacts(){
        User.CurrentUser.removeAllSpaces()
        KTActivityIndicator.singleton.show(title: "Loading...")
        for element in self.addedEmailDict!{
            WebexSDK?.people.list(email: EmailAddress.fromString(element.value), displayName: nil, max: 1) { res in
                if let person = res.result.data?.first, let contact = Contact(person: person) {
                    contact.name = element.key
                    User.CurrentUser.addNewContactAsSpace(contact: contact)
                    if(User.CurrentUser.spaceCount == self.addedEmailDict?.count){
                        KTActivityIndicator.singleton.hide()
                        self.setUpPeopleListView()
                    }
                }else{
                    let tempContact = Contact(id: "", name: element.key, email: element.value)
                    User.CurrentUser.addNewContactAsSpace(contact: tempContact)
                    if(User.CurrentUser.spaceCount == self.addedEmailDict?.count){
                        KTActivityIndicator.singleton.hide()
                        self.setUpPeopleListView()
                    }
                }
            }
        }
    }
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: TextView Delegate Impelementation
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    // MARK: - Other functions
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
