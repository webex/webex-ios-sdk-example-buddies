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
import PushKit
import UserNotifications
var WebexSDK: Webex?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {

    var window: UIWindow?
    
    var rootController: MainViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.loadUserInfo()
        self.window = UIWindow(frame: UIScreen.main.bounds);
        if self.rootController == nil {
            self.rootController = MainViewController()
        }
        self.window?.rootViewController = rootController
        self.window?.makeKeyAndVisible()
        self.registerNotificationInfo(application: application)
        return true
    }
    
    func loadUserInfo(){
        if(User.loadUserFromLocal()){
            if(User.CurrentUser.loginType == .User){
                let WebexAuthenticator = OAuthAuthenticator(clientId: Constants.ClientId, clientSecret: Constants.ClientSecret, scope: Constants.Scope, redirectUri: Constants.RedirectUrl)
                WebexSDK = Webex(authenticator: WebexAuthenticator)
            }else if(User.CurrentUser.loginType == .Guest){
                let jwtStr = User.CurrentUser.jwtString
                let jwtAuthStrategy = JWTAuthenticator()
                if !jwtAuthStrategy.authorized {
                    jwtAuthStrategy.authorizedWith(jwt: jwtStr!)
                }
                if jwtAuthStrategy.authorized == true {
                    WebexSDK = Webex(authenticator: jwtAuthStrategy)
                }
            }
        }
    }
    
    func registerNotificationInfo(application: UIApplication){
        let pr = PKPushRegistry(queue: DispatchQueue.main)
        pr.delegate = self
        pr.desiredPushTypes = [PKPushType.voIP]
        UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .sound, .badge]) { (granted: Bool, error: Error?) in
            if (error != nil) {
                print("Failed to request authorization")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("The user refused the push notification")
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        /* Save User Info on Local */
        if(User.CurrentUser.loginType != .None){
            User.CurrentUser.saveLocalRooms()
            User.CurrentUser.saveGroupsToLocal()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // Get device token for message push notification
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let hex = deviceToken.map( {String(format: "%02x", $0) }).joined(separator: "")
        /* saving message noti certificate date on local UserDefualt */
        UserDefaults.standard.set(hex, forKey: "com.cisco.webex-ios-sdk.Buddies.data.device_msg_token")
        if(User.CurrentUser.loginType != .None){
            self.rootController?.registerWebexWebhook(completionHandler: nil)
        }
    }
    
    // Get device token for voip push notification
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        let hex = credentials.token.map( {String(format: "%02x", $0) }).joined(separator: "")
        /* saving voip noti certificate date on local UserDefualt */
        UserDefaults.standard.set(hex, forKey: "com.cisco.webex-ios-sdk.Buddies.data.device_voip_token")
        if(User.CurrentUser.loginType != .None){
            self.rootController?.registerWebexWebhook(completionHandler: nil)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register to APNs: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        /* first receive message notification */
        let dict = userInfo["aps"] as? Dictionary<String, AnyObject>
        let alert = dict?["alert"] as? Dictionary<String, AnyObject>
        let email = alert?["body"] as? String
        let title = alert?["title"] as? String

        let state = UIApplication.shared.applicationState
        if state != .active {
            if(User.loadUserFromLocal()){
                if let localGroup = User.CurrentUser.getSingleGroupWithContactEmail(email: email!){
                    localGroup.unReadedCount += 1
                }
            }
        }else{
            if(User.CurrentUser.loginType != .None){
                if let localGroup = User.CurrentUser.getSingleGroupWithContactEmail(email: email!){
                    localGroup.unReadedCount += 1
                }
            }
        }

        if(title == "New Message"){
            if let home = self.rootController, let email = email {
                if email != User.CurrentUser.email{
                    home.receviMessageNotification(fromEmail: email)
                }
            }
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for: PKPushType) {
        
        /* first receive voip/call notification */
        let dict =  payload.dictionaryPayload["aps"] as? Dictionary<String, AnyObject>
        let alert = dict?["alert"] as? Dictionary<String, AnyObject>
        let idStr = alert?["body"] as? String
        let state = UIApplication.shared.applicationState
        guard let home = self.rootController, let id = idStr else{return}
        if state == .active {
            if(!User.loadUserFromLocal() || User.CurrentUser.loginType == .None){
                return
            }else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: CallReceptionNotification), object: nil)
            }
        }else{
            if(User.loadUserFromLocal() && User.CurrentUser.loginType != .None){
                if !User.CurrentUser.phoneRegisterd{
                    home.registerPhone()
                }else{
                    home.receiveIncomingCall(from: id)
                }
            }
        }
    }
}

