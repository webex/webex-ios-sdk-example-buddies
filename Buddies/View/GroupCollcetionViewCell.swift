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
import Cartography
import SDWebImage

class GroupCollcetionViewCell: UICollectionViewCell {
    
    // MARK: - UI variables
    let background: UIView
    let name: UILabel
    let email: UILabel
    let delete: UIButton
    var groupModel: Group?
    var groupImageBackView: UIView?
    var unreadedLabel: UILabel
    
    // MARK: - UI Impelementation
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required override init(frame: CGRect) {
        self.background = UIView(frame: CGRect.zero)
        self.name = UILabel()
        self.email = UILabel()
        self.delete = UIButton(type: .custom)
        self.unreadedLabel = UILabel(frame: CGRect.zero)
        super.init(frame: frame)
        
        
        self.addSubview(self.background)
        constrain(self.background) { view in
            view.center == view.superview!.center
            view.size == view.superview!.size
        }

        self.name.font = Constants.Font.Home.Title
        self.name.textAlignment = .center
        self.name.textColor = Constants.Color.Theme.DarkControl
        self.name.numberOfLines = 1;
        self.name.lineBreakMode = .byTruncatingTail;
        self.email.font = Constants.Font.Home.Comment
        self.email.textAlignment = .center
        self.email.textColor = Constants.Color.Theme.MediumControl
        self.email.numberOfLines = 1;
        self.email.lineBreakMode = .byTruncatingTail;
        self.delete.titleLabel?.font = UIFont.fontAwesome(ofSize: 20)
        self.delete.setTitle(String.fontAwesomeIcon(name: .timesCircle), for: .normal)
        self.delete.setTitleColor(Constants.Color.Theme.Warning, for: .normal)
        self.delete.addTarget(self, action: #selector(buttonTap(sender:)), for: .touchUpInside)
        self.delete.isHidden = true
        self.delete.isEnabled = false
        self.delete.setShadow(color: Constants.Color.Theme.Shadow, radius: 1, opacity: 0.5, offsetX: 1, offsetY: 1)

        self.unreadedLabel.backgroundColor = UIColor.red
        self.unreadedLabel.font = Constants.Font.InputBox.Options
        self.unreadedLabel.textColor = UIColor.white
        self.unreadedLabel.layer.cornerRadius = 10
        self.unreadedLabel.layer.masksToBounds = true
        self.unreadedLabel.isHidden = true
        self.unreadedLabel.textAlignment = .center
        
        
        self.addSubview(self.name)
        self.addSubview(self.email)

        self.addSubview(self.delete)
        self.addSubview(self.unreadedLabel)
        
        constrain(self.name) { view in
            view.top == view.superview!.top + 105
            view.centerX == view.superview!.centerX
            view.width == view.superview!.width
            view.height == 20
        }
        constrain(self.email) { view in
            view.bottom == view.superview!.bottom
            view.centerX == view.superview!.centerX
            view.width == view.superview!.width
            view.height == 20
        }
        constrain(self.delete) { view in
            view.top == view.superview!.top
            view.right == view.superview!.right
            view.width == 20
            view.height == 20
        }
        
        constrain(self.unreadedLabel) { view in
            view.bottom == view.superview!.bottom/2 + 30
            view.left == view.superview!.left + 10
            view.width == 20
            view.height == 20
        }
    }
    
    func setGroup(_ groupModel: Group) {
        self.groupModel = groupModel
        self.setUpGroupImageView()
        
        if(self.groupModel?.groupType == .singleMember){
            self.name.text = self.groupModel?[0]?.email
            self.email.text = self.groupModel?.groupName
            if((self.groupModel?.unReadedCount)! > 0){
                self.unreadedLabel.isHidden = false
                self.unreadedLabel.text = String(describing: (self.groupModel?.unReadedCount)!)
            }
        }else{
            self.name.text = self.groupModel?.groupName
            self.email.text = ""
            if((self.groupModel?.unReadedCount)! > 0){
                self.unreadedLabel.isHidden = false
                self.unreadedLabel.text = String(describing: (self.groupModel?.unReadedCount)!)
            }
        }

    }
    
    private func setUpGroupImageView(){
        self.groupImageBackView = UIView(frame: CGRect.zero)
        self.background.addSubview(self.groupImageBackView!)
        constrain(self.groupImageBackView!) { view in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY - 20
            view.width == view.superview!.width
            view.height == 100
        }
        self.drawShaowPath()

        if(self.groupModel?.grouMemberCount == 1){
            let imageView = UIImageView(frame: CGRect.zero)
            imageView.setCorner(45)
            imageView.layer.borderWidth = 4.0
            imageView.layer.borderColor = UIColor.white.cgColor
            self.groupImageBackView?.addSubview(imageView)
            let contact = self.groupModel?[0]
            if let url = contact?.avatorUrl {
                imageView.sd_setImage(with: URL(string: url), placeholderImage: contact?.placeholder)
                imageView.backgroundColor = Constants.Color.Theme.Background
            }else {
                imageView.image = contact?.placeholder
            }
            constrain(imageView) { view in
                view.centerX == view.superview!.centerX
                view.centerY == view.superview!.centerY
                view.width == 90
                view.height == 90
            }
//            constrain(self.unreadedLabel) { view in
//                view.top == view.superview!.top + 10
//                view.left == view.superview!.left + 25
//                view.width == 20
//                view.height == 20
//            }
            return;
 
        }
        
        if(self.groupModel?.grouMemberCount == 2){
            for index in 0..<2{
                let imageView = UIImageView(frame: CGRect.zero)
                imageView.setCorner(40)
                imageView.layer.borderWidth = 4.0
                imageView.layer.borderColor = UIColor.white.cgColor
                self.groupImageBackView?.addSubview(imageView)
                let contact = self.groupModel?[index]
                if let url = contact?.avatorUrl {
                    imageView.sd_setImage(with: URL(string: url), placeholderImage: contact?.placeholder)
                }else {
                    imageView.image = contact?.placeholder
                }
                switch index {
                case 0:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX - 30
                        view.centerY == view.superview!.centerY
                        view.width == 80
                        view.height == 80
                    }
                    break
                case 1:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX + 30
                        view.centerY == view.superview!.centerY
                        view.width == 80
                        view.height == 80
                    }
                    break
                default:
                    break
                }
            }
//            constrain(self.unreadedLabel) { view in
//                view.top == view.superview!.top + 10
//                view.left == view.superview!.left + 25
//                view.width == 20
//                view.height == 20
//            }
            return;
        }
        
        if(self.groupModel?.grouMemberCount == 3){
            for index in 0..<3{
                let imageView = UIImageView(frame: CGRect.zero)
                imageView.backgroundColor = Constants.Color.Theme.Background
                imageView.setCorner(35)
                imageView.layer.borderWidth = 4.0
                imageView.layer.borderColor = UIColor.white.cgColor
                self.groupImageBackView?.addSubview(imageView)
                let contact = self.groupModel?[index]
                if let url = contact?.avatorUrl {
                    imageView.sd_setImage(with: URL(string: url), placeholderImage: contact?.placeholder)
                }else {
                    imageView.image = contact?.placeholder
                }
                switch index {
                case 0:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX - 30
                        view.centerY == view.superview!.centerY + 15
                        view.width == 70
                        view.height == 70
                    }
                    break
                case 1:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX + 30
                        view.centerY == view.superview!.centerY + 15
                        view.width == 70
                        view.height == 70
                    }
                    break
                case 2:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX
                        view.centerY == view.superview!.centerY - 30
                        view.width == 70
                        view.height == 70
                    }
                    break
                default:
                    break
                }
            }
//            constrain(self.unreadedLabel) { view in
//                view.top == view.superview!.top - 5
//                view.left == view.superview!.left+30
//                view.width == 20
//                view.height == 20
//            }
            return;
        }
        
        if(self.groupModel?.grouMemberCount == 4){
            for index in (0..<4).reversed(){
                let imageView = UIImageView(frame: CGRect.zero)
                imageView.backgroundColor = Constants.Color.Theme.Background
                imageView.setCorner(30)
                imageView.layer.borderWidth = 4.0
                imageView.layer.borderColor = UIColor.white.cgColor
                self.groupImageBackView?.addSubview(imageView)
                let contact = self.groupModel?[index]
                if let url = contact?.avatorUrl {
                    imageView.sd_setImage(with: URL(string: url), placeholderImage: contact?.placeholder)
                }else {
                    imageView.image = contact?.placeholder
                }
                switch index {
                case 0:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX - 30
                        view.centerY == view.superview!.centerY + 15
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 1:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX + 30
                        view.centerY == view.superview!.centerY + 15
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 2:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX - 30
                        view.centerY == view.superview!.centerY - 30
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 3:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX + 30
                        view.centerY == view.superview!.centerY - 30
                        view.width == 60
                        view.height == 60
                    }
                    break
                default:
                    break
                }
                
            }
//            constrain(self.unreadedLabel) { view in
//                view.top == view.superview!.top - 5
//                view.left == view.superview!.left
//                view.width == 20
//                view.height == 20
//            }
            return;
        }
        
        if((self.groupModel?.grouMemberCount)! >= 5){
            for index in (0..<5).reversed(){
                let imageView = UIImageView(frame: CGRect.zero)
                imageView.backgroundColor = Constants.Color.Theme.Background
                imageView.setCorner(30)
                imageView.layer.borderWidth = 4.0
                imageView.layer.borderColor = UIColor.white.cgColor
                self.groupImageBackView?.addSubview(imageView)
                if(index == 4 && (self.groupModel?.grouMemberCount)! > 5){
                    imageView.image = UIImage(cgImage: (UIImage(named:"icon_more")?.cgImage)!, scale: 2.0, orientation: .up)
                    imageView.contentMode = .center
                    imageView.backgroundColor = UIColor.MKColor.BlueGrey.P800
                    imageView.frame.insetBy(dx: 30.0, dy: 10.0);
                }else{
                    let contact = self.groupModel?[index]
                    if let url = contact?.avatorUrl {
                        imageView.sd_setImage(with: URL(string: url), placeholderImage: contact?.placeholder)
                    }else {
                        imageView.image = contact?.placeholder
                    }
                }
          
                switch index {
                case 0:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX
                        view.centerY == view.superview!.centerY - 10
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 1:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX + 30
                        view.centerY == view.superview!.centerY - 35
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 2:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX - 33
                        view.centerY == view.superview!.centerY - 35
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 3:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX - 33
                        view.centerY == view.superview!.centerY + 15
                        view.width == 60
                        view.height == 60
                    }
                    break
                case 4:
                    constrain(imageView) { view in
                        view.centerX == view.superview!.centerX + 30
                        view.centerY == view.superview!.centerY + 15
                        view.width == 60
                        view.height == 60
                    }
                    break
                default:
                    break
                }
            }
//            constrain(self.unreadedLabel) { view in
//                view.top == view.superview!.top - 5
//                view.left == view.superview!.left
//                view.width == 20
//                view.height == 20
//            }
            return;
        }
    }
    
    // MARK: draw shadow path for cell
    func drawShaowPath(){
    
        let shadowPath = CGMutablePath()
        let tempPath = UIBezierPath()
    
        let memberCount = self.groupModel?.grouMemberCount
        switch memberCount! {
        case 1:
            tempPath.addArc(withCenter: CGPoint(70,50), radius: 45, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            break
        case 2:
            tempPath.addArc(withCenter: CGPoint(40,50), radius: 40, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(100,50), radius: 40, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            break
        case 3:
            tempPath.addArc(withCenter: CGPoint(70,20), radius: 35, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(40,65), radius: 35, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(100,65), radius: 35, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            break
        case 4:
            tempPath.addArc(withCenter: CGPoint(40,65), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(100,65), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(40,20), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(100,20), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            break
        default:
            tempPath.addArc(withCenter: CGPoint(70,40), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(100,15), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(37,15), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(37,65), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            tempPath.addArc(withCenter: CGPoint(100,65), radius: 30, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            break
        }
        shadowPath.addPath(tempPath.cgPath)
        self.groupImageBackView?.layer.shadowPath = shadowPath
        self.groupImageBackView?.layer.shadowColor = UIColor.black.cgColor
        self.groupImageBackView?.layer.shadowOffset = CGSize(1, 1)
        self.groupImageBackView?.layer.shadowOpacity = 0.5
        self.groupImageBackView?.layer.shadowRadius = 3.0
    }
    
    var onDelete: ((String?) -> Void)? {
        didSet {
            if self.onDelete == nil {
                self.delete.isHidden = true
                self.delete.isEnabled = false
            }
            else {
                self.delete.isHidden = false
                self.delete.isEnabled = true
            }
        }
    }
    
    func reset() {
        self.onDelete = nil
        self.groupImageBackView?.removeFromSuperview()
        self.groupImageBackView = nil
        self.name.text = nil
        self.email.text = nil
        self.unreadedLabel.isHidden = true
    }
    
    @objc private func buttonTap(sender: UIButton) {
        self.onDelete?(self.groupModel?.groupId)
    }
    
}
