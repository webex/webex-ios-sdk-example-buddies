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
enum UserOptionType: Int {
    case UserLogin
    case GuestLogin
    case LogOut
    case Buddies
    case Spaces
    case Teams
}
protocol UserOptionDelegate{
    func processUserAction(optionType: UserOptionType)
}
class UserOptionView: UIView {
    
    // MARK: - UI variables
    var delegate:UserOptionDelegate! = nil
    var backView: UIScrollView?
    var topUserInfoView: UIView?
    var viewWidth: CGFloat = 0
    var viewHeight: CGFloat = 0
  
    
    // MARK: - UI Implementation
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewWidth = frame.size.width
        viewHeight = frame.size.height
        self.updateSubViews()
    }

    func updateSubViews(){
        if(self.backView != nil){
            self.backView?.removeFromSuperview()
        }
        self.backView = UIScrollView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
        self.backView?.backgroundColor = Constants.Color.Theme.Main
        self.backView?.contentSize = CGSize(viewWidth,viewHeight)
        self.addSubview(self.backView!)
        constrain(self.backView!) { view in
            view.height == view.superview!.height;
            view.width == view.superview!.width;
            view.bottom == view.superview!.bottom;
            view.left == view.superview!.left;
        }
        self.topUserInfoView = UIView(frame: CGRect(x: 0, y: 0, width: viewWidth, height: 200))
        self.topUserInfoView?.backgroundColor = Constants.Color.Theme.Main
        self.backView?.addSubview(self.topUserInfoView!)
        if(User.CurrentUser.loginType == .None || User.CurrentUser.loginType == .Guest){
            let titleLabel = UILabel(frame: CGRect(x: 30, y: 70, width: viewWidth-50, height: 40))
            titleLabel.text = "Buddies"
            titleLabel.textAlignment = .left
            titleLabel.font = Constants.Font.Side.MainTitle
            titleLabel.textColor = UIColor.white
            self.topUserInfoView?.addSubview(titleLabel)
            
            let OAuthLoginBtn = UIButton(type: .system)
            OAuthLoginBtn.frame = CGRect(x: 30, y: 110, width: viewWidth - 60, height: 40)
            OAuthLoginBtn.setTitle("Webex ID Login", for: .normal)
            OAuthLoginBtn.titleLabel?.font = Constants.Font.InputBox.Button
            OAuthLoginBtn.setTitleColor(UIColor.white, for: .normal)
            OAuthLoginBtn.setCorner(20)
            OAuthLoginBtn.layer.borderColor = UIColor.white.cgColor
            OAuthLoginBtn.layer.borderWidth = 1.0
            OAuthLoginBtn.tag = UserOptionType.UserLogin.rawValue
            OAuthLoginBtn.addTarget(self, action: #selector(processBtnAction(sender:)), for: .touchUpInside)
            self.topUserInfoView?.addSubview(OAuthLoginBtn)
            
            let JWTLoginBtn = UIButton(type: .custom)
            JWTLoginBtn.frame = CGRect(x: 30, y: 160, width: (viewWidth-60), height: 20)
            JWTLoginBtn.titleLabel?.font = Constants.Font.InputBox.Button
            JWTLoginBtn.tag = UserOptionType.GuestLogin.rawValue
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right
            if(User.CurrentUser.loginType == .Guest){
                JWTLoginBtn.frame = CGRect(x: 30, y: 160, width: (viewWidth-60), height: 40)
                JWTLoginBtn.titleLabel?.font = Constants.Font.InputBox.Button
                JWTLoginBtn.setTitleColor(UIColor.white, for: .normal)
                JWTLoginBtn.setCorner(20)
                JWTLoginBtn.layer.borderColor = UIColor.white.cgColor
                JWTLoginBtn.layer.borderWidth = 1.0
                JWTLoginBtn.setTitle("Guest Experience", for: .normal)
            }
            else {
                let attStringSaySomething1 = NSAttributedString.init(string: "Configure for guest Indentity Usage",
                                                                     attributes: [NSAttributedString.Key.font: Constants.Font.NavigationBar.Button, NSAttributedString.Key.foregroundColor:UIColor.white,
                                                                                  NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                                                  NSAttributedString.Key.paragraphStyle: paragraph])
                
                JWTLoginBtn.setAttributedTitle(attStringSaySomething1, for: .normal)
            }
            JWTLoginBtn.addTarget(self, action: #selector(processBtnAction(sender:)), for: .touchUpInside)
            self.topUserInfoView?.addSubview(JWTLoginBtn)
        }
        else {
            let avatorImageView = UIImageView(frame: CGRect(x: 15, y: 70, width: 60, height: 60))
            if let url = User.CurrentUser.avatorUrl {
                avatorImageView.sd_setImage(with: URL(string: url), placeholderImage: User.CurrentUser.placeholder)
            }
            else {
                avatorImageView.image = User.CurrentUser.placeholder
            }
            avatorImageView.setCorner(20)
            avatorImageView.layer.borderColor = UIColor.white.cgColor
            avatorImageView.layer.borderWidth = 2.0
            self.topUserInfoView?.addSubview(avatorImageView)
            
            let nameLabel = UILabel(frame: CGRect(x: 85, y: 80, width: viewWidth-50, height: 20))
            nameLabel.text = User.CurrentUser.name
            nameLabel.textAlignment = .left
            nameLabel.textColor = UIColor.white
            nameLabel.font = Constants.Font.Home.Title
            self.topUserInfoView?.addSubview(nameLabel)
            
            let emailLabel = UILabel(frame: CGRect(x: 85, y: 100, width: viewWidth-50, height: 20))
            emailLabel.text = User.CurrentUser.email
            emailLabel.textAlignment = .left
            emailLabel.textColor = UIColor.white
            emailLabel.font = Constants.Font.Home.Comment
            self.topUserInfoView?.addSubview(emailLabel)

            let buddiesButton = UIButton(type: .system)
            buddiesButton.frame = CGRect(x: 13, y: 160, width: viewWidth-60, height: 50)
            buddiesButton.setTitle("Buddies", for: .normal)
            buddiesButton.titleLabel?.font = Constants.Font.InputBox.Button
            buddiesButton.setTitleColor(UIColor.white, for: .normal)
            buddiesButton.contentHorizontalAlignment = .left
            buddiesButton.tag = UserOptionType.Buddies.rawValue
            buddiesButton.addTarget(self, action: #selector(processBtnAction(sender:)), for: .touchUpInside)
            let line1 = CALayer()
            line1.frame = CGRect(x: 0, y: 49, width: viewWidth-30, height: 0.5)
            line1.backgroundColor = UIColor.white.cgColor
            buddiesButton.layer.addSublayer(line1)
            self.backView?.addSubview(buddiesButton)
            
            let spacesButton = UIButton(type: .system)
            spacesButton.frame = CGRect(x: 13, y: 210, width: viewWidth-60, height: 50)
            spacesButton.setTitle("Spaces", for: .normal)
            spacesButton.titleLabel?.font = Constants.Font.InputBox.Button
            spacesButton.setTitleColor(UIColor.white, for: .normal)
            spacesButton.contentHorizontalAlignment = .left
            spacesButton.tag = UserOptionType.Spaces.rawValue
            spacesButton.addTarget(self, action: #selector(processBtnAction(sender:)), for: .touchUpInside)

            let line2 = CALayer()
            line2.frame = CGRect(x: 0, y: 49, width: viewWidth-30, height: 0.5)
            line2.backgroundColor = UIColor.white.cgColor
            spacesButton.layer.addSublayer(line2)
            self.backView?.addSubview(spacesButton)
//
//            let teamsButton = UIButton(type: .system)
//            teamsButton.frame = CGRect(x: 13, y: 260, width: viewWidth-60, height: 50)
//            
//            teamsButton.setTitle("Teams", for: .normal)
//            teamsButton.tag = UserOptionType.Teams.rawValue
//            teamsButton.titleLabel?.font = Constants.Font.InputBox.Button
//            teamsButton.setTitleColor(UIColor.white, for: .normal)
//            teamsButton.contentHorizontalAlignment = .left
//            teamsButton.addTarget(self, action: #selector(processBtnAction(sender:)), for: .touchUpInside)
//            let line3 = CALayer()
//            line3.frame = CGRect(x: 0, y: 49, width: viewWidth-30, height: 0.5)
//            line3.backgroundColor = UIColor.white.cgColor
//            teamsButton.layer.addSublayer(line3)
//            self.backView?.addSubview(teamsButton)
//            
            
            let logOutBtn = UIButton(type: .custom)
            logOutBtn.frame = CGRect(x: 15, y: viewHeight-80, width: viewWidth-60, height: 40)
            logOutBtn.setTitle("Log Out", for: .normal)
            logOutBtn.titleLabel?.font = Constants.Font.InputBox.Button
            logOutBtn.contentHorizontalAlignment = .left
            logOutBtn.setTitleColor(Constants.Color.Theme.Warning, for: .normal)
            logOutBtn.tag = UserOptionType.LogOut.rawValue
            logOutBtn.addTarget(self, action: #selector(processBtnAction(sender:)), for: .touchUpInside)
            self.backView?.addSubview(logOutBtn)
        }
        
        let versionLabel = UILabel(frame: CGRect(x: 15, y: viewHeight-20, width: viewWidth-60, height: 20))
        let strVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        versionLabel.text = "- Version:" + (strVersion as? String)!
        versionLabel.font = Constants.Font.InputBox.Options
        versionLabel.textAlignment = .left
        versionLabel.textColor = UIColor.white
        self.backView?.addSubview(versionLabel)
    }
    
    @objc private func processBtnAction(sender: UIButton){
        if let type = UserOptionType(rawValue: sender.tag) {
            delegate!.processUserAction(optionType: type)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
