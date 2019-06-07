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
import SDWebImage
import WebexSDK
import Alamofire

enum UserLoginType : Int {
    case None // not Login
    case User // Login as OAuthUser
    case Guest // Login as Guest
}

class User: Contact {
    
    static var CurrentUser = User(id: "", name: "qucui", email: "qucui@cisco.com")

    public var spaces: [SpaceModel] = []

    var loginType: UserLoginType = .None
    var jwtString: String?
    var phoneRegisterd: Bool = false
    var registerdOnWebhookServer: Bool = false
    var webHookCreated: Bool = false
    
    override init(id: String ,name: String, email: String){
        super.init(id: id, name: name, email: email)
        self.avatorUrl = nil
    }
    
    // MARK: User Login Implementation
    static func loadUserFromLocal() -> Bool {
        let name = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_name")
        let email = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_email")
        let userId = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_id")
        let loginTypeRawValue = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_LoginType")
        let registerdOnWebhookServer = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebHookRegisterd")
        let webhookCreated =  UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebHookCreated")
        if let name = name, let email = email {
            let user = User(id: userId!, name: name, email: email)
            user.avatorUrl = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_avator")
            user.registerdOnWebhookServer = (registerdOnWebhookServer != nil)
            user.webHookCreated = (webhookCreated != nil)
            user.loadLocalSpaces()
            if let userLoginTypeRawValue = loginTypeRawValue{
                let userLoginType = UserLoginType(rawValue: Int(userLoginTypeRawValue)!)
                user.loginType = userLoginType!
            }
            
            if(user.loginType == .Guest){
                user.jwtString = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_Login_JWTSTR")
            }
            
            CurrentUser = user
            return true
        }
        return false
    }
    
    static func updateCurrenUser(person: Person, loginType: UserLoginType) -> Bool {
        if let user = User(person: person) {
            user.loginType = loginType
            CurrentUser = user
            UserDefaults.standard.set(user.id, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_id")
            UserDefaults.standard.set(user.name, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_name")
            UserDefaults.standard.set(user.email, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_email")
            UserDefaults.standard.set(user.avatorUrl, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_avator")
            UserDefaults.standard.set(user.loginType.rawValue, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_LoginType")
            CurrentUser.loadLocalSpaces()
            return true
        }
        return false
    }
    
    func updateJwtString(jwtStr: String){
        self.jwtString = jwtStr
        UserDefaults.standard.set(self.jwtString, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_Login_JWTSTR")
    }
    
    func setRegisterdOnWebHookServer(registerd: Bool){
        self.registerdOnWebhookServer = registerd
        UserDefaults.standard.set(self.registerdOnWebhookServer, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebHookRegisterd")
    }
    
    func setWebHookCreated(webHookId: String){
        self.webHookCreated = true
        UserDefaults.standard.set(self.webHookCreated, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebHookCreated")
        UserDefaults.standard.set(webHookId, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebhookId")
    }
    
    func getLocalWebHookId() -> String?{
        return UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebhookId")
    }
    
    func logout() {
        self.saveSpacesToLocal()
        self.deRegisterPhoneAndWebHook()
        self.name = ""
        self.email = ""
        self.avatorUrl = nil
        self.loginType = .None
        self.spaces.removeAll()
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_name")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_email")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_avator")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_id")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_LoginType")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_callhook")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebHookRegisterd")
        UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebHookCreated")
        UserDefaults.standard.synchronize()
    }
    
    private func deRegisterPhoneAndWebHook(){
        KTActivityIndicator.singleton.show(title: "Logging Out..")
        let threahSpace = DispatchGroup()
        
        /* Remove cevice from cisco cloud */
        DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
            WebexSDK?.phone.deregister({ (_ error) in
                
            })
        }))
        
        /* Remove Message/Voip token from Webhook Server*/
        DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
            if let token = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.device_voip_token") {
                Alamofire.request("https://ios-demo-pushnoti-server.herokuapp.com/register/\(token)", method: .delete).response { res in
                    
                }
            }
        }))
        
        DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
            if let token = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.device_msg_token") {
                Alamofire.request("https://ios-demo-pushnoti-server.herokuapp.com/register/\(token)", method: .delete).response { res in
                           
                }
            }
        }))
        
        
        /* Delete WebHook for User */
        DispatchQueue.global().async(group: threahSpace, execute: DispatchWorkItem(block: {
            if let webHookId = UserDefaults.standard.string(forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebhookId") {
                WebexSDK?.webhooks.delete(webhookId: webHookId, completionHandler: { (_ res) in
                    print("\(res)")
                    UserDefaults.standard.set(nil, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_WebhookId")
                })
            }
        }))
        
        threahSpace.notify(queue: DispatchQueue.global(), execute: {
            DispatchQueue.main.async {
                KTActivityIndicator.singleton.hide()
                WebexSDK?.authenticator.deauthorize()
            }
        })
    }

    // MARK: - User Contacts Implementation
    var spaceCount: Int {
        return self.spaces.count
    }
        
    private var _callhook: String?
    
    var callhook: String? {
        get {
            return self._callhook
        }
        set {
            self._callhook = newValue
            UserDefaults.standard.set(self._callhook, forKey: "com.cisco.webex-ios-sdk.Buddies.data.user_callhook")
        }
    }
    
    subscript(index: Int) -> SpaceModel? {
        return self.spaces.safeObjectAtIndex(index)
    }
    
    subscript(spaceId: String) -> SpaceModel? {
        return self.spaces.filter({$0.localSpaceId == spaceId}).first
    }
    
    func getSingleSpaceWithContactId(contactId: String)->SpaceModel?{
         return self.getSingleMemberSpace().filter({$0.localSpaceId == contactId}).first
    }

    func addNewSpace(newSpace: SpaceModel){
        self.spaces.insert(newSpace, at: 0)
    }
    
    func addNewContactAsSpace(contact: Contact) {
        let newSpace = SpaceModel(contact: contact)
        self.spaces.append(newSpace)
    }
    
    func removeSpace(spaceId: String) {
        _ = self.spaces.removeObject(equality: { $0.localSpaceId == spaceId })
    }
    
    func removeAllSpaces(){
        self.spaces.removeAll()
    }
    
    func getSingleMemberSpace()->[SpaceModel]{
        return self.spaces
    }
    
    func loadLocalSpaces() {
        let spaceListFilePath = self.getSpaceFilePath()
        if(FileManager.default.fileExists(atPath: spaceListFilePath)){
            do{
                let spaceListData = try Data(contentsOf: URL(fileURLWithPath: spaceListFilePath))
                self.spaces = NSKeyedUnarchiver.unarchiveObject(with: spaceListData) as! [SpaceModel]
            }catch{
                print("ReadSpacelistFile Failed")
            }
        }
    }
    
    func saveSpacesToLocal() {
        let spaceListFilePath = self.getSpaceFilePath()
        let spaceData = NSKeyedArchiver.archivedData(withRootObject: self.spaces)
        do{
            try spaceData.write(to: URL(fileURLWithPath: spaceListFilePath))
        }catch let error{
            print("WirteSpaceListFile Failed + \(error.localizedDescription)")
        }
    }
    
    private func getSpaceFilePath() -> String{
        let localFilePath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
        let spacesFiltPath = localFilePath[0]
        let FileName = "\(self.email)+localSpaces.plist"
        let spaceListFilePath = spacesFiltPath + "/" + FileName
        return spaceListFilePath
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
