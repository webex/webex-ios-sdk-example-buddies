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
import Cartography
import WebexSDK
import AVFoundation
import CallKit
import Alamofire

let MessageReceptionNotificaton = "MessageReceivedNotification"
let CallReceptionNotification = "CallReceptionNotification"
class MainViewController: UIViewController, UserOptionDelegate{
    
    // MARK: - UI variables
    private var buddiesVC: BuddiesViewController?
    private var spaceListVC: SpaceListViewController?
    private var teamVC: TeamListViewController?
    private var guestLoginVC: GuestSettingViewController?

    private let optionViewWidth = Constants.Size.screenWidth/4*3
    private var maskView: UIView?
    
    public var userOptionView: UserOptionView?
    public var navVC : UINavigationController?
    private var currentOptionType: UserOptionType = .Buddies
    
    // Receive Notification Variables
    private var provider: CXProvider
    fileprivate var callers = [UUID: Contact]()
    public var callViewController: BuddiesCallViewController?
    
    fileprivate var incomingCalls  = [Call]()
    fileprivate var newCall : Call?  = nil
    fileprivate var newCallCallee: Contact? = nil
    public var messageUnreadDict = [String : Bool]()
    
    
    // MARK: - Life circle
    init() {
        self.provider = CXProvider(configuration: MainViewController.providerConfiguration)
        super.init(nibName: nil, bundle: nil)
        self.provider.setDelegate(self, queue: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.buddiesVC = BuddiesViewController(mainViewController: self)
        self.navVC = UINavigationController(rootViewController: self.buddiesVC!)
        self.navVC?.navigationBar.updateAppearance();
        self.view.addSubview((navVC?.view)!)
        self.registerPhone()
    }
    public func registerPhone(){
        if(User.CurrentUser.loginType != .None && !User.CurrentUser.phoneRegisterd){
            let acitivtyIndicator = KTActivityIndicator()
            acitivtyIndicator.show(title: "Connecting...", at: (self.navVC?.view)!, offset: 0, size: 156, allowUserInteraction: false)
            WebexSDK?.phone.register({ (_ error) in
                acitivtyIndicator.hide()
                if(error == nil){
                    User.CurrentUser.phoneRegisterd = true
                    (self.navVC?.topViewController as! BaseViewController).updateViewController()
                    self.registerOnComingCall()
                    self.registerOnReceiveMessage()
                }else{
                    KTInputBox.alert(title: "Register To Could Fail")
                }
            })
        }
    }
    // MARK: - WebexSDK: user login/logout Implementation
    @objc public func userLogin(){
        let WebexAuthenticator = OAuthAuthenticator(clientId: Constants.ClientId, clientSecret: Constants.ClientSecret, scope: Constants.Scope, redirectUri: Constants.RedirectUrl)
        WebexSDK = Webex(authenticator: WebexAuthenticator)
        WebexAuthenticator.authorize(parentViewController: self) { success in
            if success {
                KTActivityIndicator.singleton.show(title: "Logging in")
                WebexSDK?.people.getMe { res in
                    KTActivityIndicator.singleton.hide()
                    if let person = res.result.data {
                        if(User.updateCurrenUser(person: person, loginType: .User)){
                            self.registerWebexWebhook(completionHandler: { (_ res) in })
                            self.userOptionView?.updateSubViews()
                            self.registerPhone()
                        }
                    }else if let error = res.result.error {
                        KTInputBox.alert(error: error)
                    }
                }
            }else {
                KTInputBox.alert(title: "Login failed")
            }
        }
    }
    
    @objc public func GuestLogin(){
        self.guestLoginVC = GuestSettingViewController()
        self.guestLoginVC?.signInSuccessBlock = {
            self.userOptionView?.updateSubViews()
            self.registerWebexWebhook(completionHandler: { (_ res) in })
            self.registerPhone()
        }
        let loginNavVC = UINavigationController(rootViewController: self.guestLoginVC!)
        self.presentFullScreen(loginNavVC, animated: true) {}
    }
    
    
    @objc public func GuestSetting(){
        self.guestLoginVC = GuestSettingViewController()
        let loginNavVC = UINavigationController(rootViewController: self.guestLoginVC!)
        self.presentFullScreen(loginNavVC, animated: true) {}
    }
    
    @objc public func userLogOut(){
        User.CurrentUser.logout()
        self.userOptionView?.updateSubViews()
        (self.navVC?.topViewController as! BaseViewController).updateViewController()
    }
    
    // MARK: - WebexSDK: Webhook Create / Register notification info into web hook server
    func registerWebexWebhook(completionHandler: ((Bool) -> Void)?) {
        if  let voipToken = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.device_voip_token"),
            let msgToken = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.device_msg_token") {
            KTActivityIndicator.singleton.show(title: "Connecting....")
            let threahSpace = DispatchGroup()
            
            /*
             Check if MSG web hook is registered for user
             */
            DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
                if(!User.CurrentUser.webHookCreated){
                    WebexSDK?.webhooks.list(completionHandler: { (response: ServiceResponse<[Webhook]>) in
                        switch response.result {
                        case .success(let value):
                            for webhook in value{
                                if(webhook.resource == "messages"){
                                    User.CurrentUser.setWebHookCreated(webHookId: (webhook.id)!)
                                    return
                                }
                            }
                            self.createNewWebHook()
                            break
                        case .failure:
                            self.createNewWebHook()
                            break
                        }
                    })
                }
            }))
            
            /*
             Register notificaiton info into web hook server
             */
            DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
                if(!User.CurrentUser.registerdOnWebhookServer){
                    /*
                     register device notification info on webhook server
                     */
                    let webHookServiceParamater: Parameters = [
                        "email": User.CurrentUser.email,
                        "voipToken": voipToken,
                        "msgToken": msgToken,
                        "personId": User.CurrentUser.id
                    ]
                    AF.request("https://ios-demo-pushnoti-server.herokuapp.com/register", method: .post, parameters: webHookServiceParamater, encoding: JSONEncoding.default).validate().response { res in
                        KTActivityIndicator.singleton.hide()
                        completionHandler?(true)
                        if(res.error == nil){
                            print("Webhookserver Register success")
                            User.CurrentUser.setRegisterdOnWebHookServer(registerd: true)
                        }
                    }
                }
            }))
            threahSpace.notify(queue: DispatchQueue.global(), execute: {
                DispatchQueue.main.async {
                    KTActivityIndicator.singleton.hide()
                }
            })
        }
        else {
            completionHandler?(false)
        }
    }
    
    func createNewWebHook(){
        /* create webhook for notification reception */
        let webHookName = User.CurrentUser.name + "-MSG-WebHook"
        let targetUrl = Constants.Webhook.redirectUrl
        //let filter = Constants.Webhook.filter
        /*
         Scope of notification, should one of resource below
         [all, calls, spaces, messages, memberships, callMemberships]
         */
        let resource = "messages"
        /*
         events of notification, should one of resource below
         [created, all, updated, deleted]
         */
        let event = "all"
        WebexSDK?.webhooks.create(name: webHookName, targetUrl: targetUrl, resource: resource, event: event, completionHandler: { (response: ServiceResponse<Webhook>) in
            switch response.result{
                
            case .success(let webhook):
                User.CurrentUser.setWebHookCreated(webHookId: (webhook.id)!)
                break
            case .failure(let error):
                print(error.localizedDescription)
                break
            }
            
        })
    }
    
    // MARK: - Call Receiption Notification Setting
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "Buddies")
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic, .phoneNumber, .emailAddress]
        return providerConfiguration
    }
    
    // MARK: - UI Implementation
    private func setUpMaskView(){
        if(self.maskView == nil){
            self.maskView = UIView(frame: CGRect.zero)
            self.maskView?.frame = self.view.frame
            self.maskView?.backgroundColor = UIColor.black
            self.maskView?.alpha = 0
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissUserOptionView))
            self.maskView?.addGestureRecognizer(tap)
        }
    }
    
    private func setUpUserOptionView(){
        if(self.userOptionView == nil){
            self.userOptionView = UserOptionView(frame: CGRect(x: -Constants.Size.screenWidth/4*3, y: 0, width: Constants.Size.screenWidth/4*3, height: Constants.Size.screenHeight))
            self.userOptionView?.delegate = self
        }
    }
    
    @objc public func slideInUserOptionView() {
        self.setUpMaskView()
        self.setUpUserOptionView()
        self.view.addSubview(self.userOptionView!)
        self.view.addSubview(self.maskView!)
        constrain(self.maskView!) { view in
            view.height == view.superview!.height;
            view.width == view.superview!.width;
        }
        UIView.animate(withDuration: 0.2) {
            self.userOptionView?.transform = CGAffineTransform(translationX: self.optionViewWidth, y: 0)
            self.maskView?.transform = CGAffineTransform(translationX: self.optionViewWidth, y: 0)
            self.maskView?.alpha = 0.4
            self.navVC?.view.transform = CGAffineTransform(translationX: self.optionViewWidth, y: 0)
        }
    }
    @objc public func dismissUserOptionView(){
        UIView.animate(withDuration: 0.2, animations: {
            self.userOptionView?.transform = CGAffineTransform(translationX:0, y: 0)
            self.maskView?.transform = CGAffineTransform(translationX: 0, y: 0)
            self.maskView?.alpha = 0
            self.navVC?.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (complete) in
            self.maskView?.removeFromSuperview()
            self.userOptionView?.removeFromSuperview()
        }
    }
    
    // MARK: - UserOptionView Delegate
    /*
     Receive ButtonClick action on slide-in user option view
     */
    func processUserAction(optionType: UserOptionType){
        switch optionType {
        case .UserLogin:
            self.userLogin()
            break
        case .GuestLogin:
            self.GuestLogin()
            break
        case .LogOut:
            self.userLogOut()
            break
        default:
            break
        }
        if(optionType == .Buddies || optionType == .Teams || optionType == .Spaces || optionType == .LogOut){
            if(currentOptionType == optionType || optionType == .LogOut ){
                self.dismissUserOptionView()
            }else{
                currentOptionType = optionType
                self.updateCurrentViewController(optionType: optionType)
            }
        }
    }
    
    func updateCurrentViewController(optionType: UserOptionType){
        if(self.navVC != nil){
            self.navVC?.viewControllers.removeAll()
            self.navVC?.view.removeFromSuperview()
        }
        self.navVC = UINavigationController(rootViewController: self.getChoosedVC(optionType: optionType))
        self.navVC?.navigationBar.updateAppearance();
        self.navVC?.view.transform = CGAffineTransform(translationX: self.optionViewWidth, y: 0)
        self.view.addSubview((navVC?.view)!)
        self.view.bringSubviewToFront(self.maskView!)
        self.dismissUserOptionView()
    }
    
    public func receiveIncomingCall(from: String) {
        self.fetchCalleeInfo(from: from)
    }
    public func fetchCalleeInfo(from: String){
        if let localContact = User.CurrentUser[from]{
            self.newCallCallee = localContact.contact
            self.reportNewIncomingCall(newCall: self.newCall, from: self.newCallCallee)
        }else{
            WebexSDK?.people.get(personId: from) { res in
                if let person = res.result.data, let contact = Contact(person: person) {
                    self.newCallCallee = contact
                    self.reportNewIncomingCall(newCall: self.newCall, from: self.newCallCallee)
                }
            }
        }
    }
    
    // MARK: - Webex IncomingCall Register
    public func registerOnComingCall(){
        if(User.CurrentUser.phoneRegisterd){
            WebexSDK?.phone.onIncoming = { call in
                self.incomingCalls.append(call)
                self.newCall = call
                self.receiveIncomingCall(from: (call.from?.personId)!)
            }
        }
    }
    
    func reportNewIncomingCall(newCall: Call?, from: Contact?){
        let update = CXCallUpdate()
        update.hasVideo = true
        if let call = newCall , let callee  = from{
            self.callers[call.uuid] = callee
            update.remoteHandle = CXHandle(type: .emailAddress, value: callee.name)
            if(self.callViewController?.currentCall?.status == .connected){
                DispatchQueue.global().async {
                    call.reject(completionHandler: { (_) in })
                }
            }else{
                self.provider.reportNewIncomingCall(with: call.uuid, update: update) { error in }

            }
            self.newCall = nil
            self.newCallCallee = nil
        }
    }
    
    // MARK: - Webex On ReceiveMessage Callback
    private func registerOnReceiveMessage() {
        if(User.CurrentUser.phoneRegisterd){
            WebexSDK?.messages.onEvent = { event in
                switch event{
                case .messageReceived(let message):
                    if User.CurrentUser.loginType == .Guest, let vc = self.guestLoginVC {
                        vc.receiveNewMessage(message)
                    }else {
                        if message.spaceType == SpaceType.direct, let vc = self.buddiesVC {
                            vc.receiveNewMessage(message)
                        }
                        else {
                            if let vc = self.spaceListVC {
                                vc.receiveNewMessage(message)
                            }
                            else if let spaceId = message.spaceId {
                                self.messageUnreadDict[spaceId] = true
                            }
                        }
                    }
                    break
                case .messageDeleted(_):
                    break
                case .messageUpdated:
                    break
                }
            }
        }
    }
    
    // MARK: - other functions
    private func getChoosedVC(optionType: UserOptionType) -> BaseViewController {
        var choosedVC: BaseViewController
        switch optionType {
        case .Buddies:
            if let vc = self.buddiesVC {
                choosedVC = vc
            }
            else {
                self.buddiesVC = BuddiesViewController(mainViewController: self)
                choosedVC = self.buddiesVC!
            }
            break
        case .Spaces:
            if let vc = self.spaceListVC {
                choosedVC = vc
            }
            else {
                self.spaceListVC = SpaceListViewController(mainViewController: self)
                choosedVC = self.spaceListVC!
            }
            break
        case .Teams:
            if let vc = self.teamVC {
                choosedVC = vc
            }
            else {
                self.teamVC = TeamListViewController(mainViewController: self)
                choosedVC = self.teamVC!
            }
            break
        default:
            choosedVC = BuddiesViewController(mainViewController: self)
            break
        }
        return choosedVC
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
                                           Unmanaged.passUnretained(self).toOpaque(),
                                           nil,
                                           nil)
    }
}

// MARK: - receive voip notification callkit extention
extension MainViewController: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
        print("@@@@@@@@@@@@@@@@@: did reset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
         print("@@@@@@@@@@@@@@@@@: CXAnswerCallAction")
        let uuid = action.callUUID
        if let contact = self.callers[uuid], let call = self.incomingCalls.filter({$0.uuid.uuidString == uuid.uuidString}).first{
            if self.callViewController == nil {
                self.callViewController?.removeFromParent()
                self.callViewController = nil
                self.callViewController = BuddiesCallViewController(callee: contact, uuid: uuid, callkit: provider)
            }
            if let presentedViewController = self.presentedViewController,presentedViewController != self.callViewController {
                if let presentedNavController = presentedViewController as? UINavigationController {
                    presentedNavController.topViewController?.presentFullScreen(self.callViewController!, animated: true) {
                        self.callViewController?.answerNewIncomingCall(call: call, callKitAction: action)
                    }
                }
                else {
                    self.presentFullScreen(self.callViewController!, animated: true) {
                        self.callViewController?.answerNewIncomingCall(call: call, callKitAction: action)
                    }
                }
            }
            else if let presentedViewController = self.presentedViewController,presentedViewController == self.callViewController {
                self.callViewController?.answerNewIncomingCall(call: call, callKitAction: action)
            }
            else {
                self.presentFullScreen(self.callViewController!, animated: true) {
                    self.callViewController?.answerNewIncomingCall(call: call, callKitAction: action)
                }
            }
        }
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
          print("@@@@@@@@@@@@@@@@@: CXSetSpaceCallAction")
    }
    public func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
         print("@@@@@@@@@@@@@@@@@: CXSetSpaceCallAction")
        return false
    }
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
         print("@@@@@@@@@@@@@@@@@: didActivate")
        if let call = self.incomingCalls.filter({$0.uuid.uuidString == action.callUUID.uuidString}).first{
            if call.status == .connected {
                call.hangup() {
                    error in
                }
            }
            else {
                call.reject(completionHandler: { (_ error) in })
            }
        }
        action.fulfill()
    }      
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("@@@@@@@@@@@@@@@@@: didActivate")
        if let call = self.incomingCalls.filter({$0.status == .connected}).first {
            call.updateAudioSession()
        }
    }
    
    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("@@@@@@@@@@@@@@@@@: didDeactivate")
    }
}

