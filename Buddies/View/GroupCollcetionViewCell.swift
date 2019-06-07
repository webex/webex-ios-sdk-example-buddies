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
import SDWebImage
import WebexSDK

class SpaceCollcetionViewCell: UICollectionViewCell {
    
    // MARK: - UI variables
    let background: UIView
    let name: UILabel
    let email: UILabel
    let delete: UIButton
    var spaceModel: SpaceModel?
    var spaceImageBackView: UIView?
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

        self.unreadedLabel.backgroundColor = Constants.Color.Theme.Main
        self.unreadedLabel.font = Constants.Font.InputBox.Options
        self.unreadedLabel.textColor = UIColor.white
        self.unreadedLabel.layer.cornerRadius = 9.0
        self.unreadedLabel.layer.borderColor = UIColor.white.cgColor
        self.unreadedLabel.layer.borderWidth = 2.0
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
            view.top == view.superview!.top + 20
            view.right == view.superview!.right - 20
            view.width == 20
            view.height == 20
        }
        
        constrain(self.unreadedLabel) { view in
            view.top == view.superview!.top + 10
            view.right == view.superview!.right/2 + 45
            view.width == 18
            view.height == 18
        }
    }
    
    func setSpace(_ spaceModel: SpaceModel) {
        self.spaceModel = spaceModel
        self.setUpSpaceImageView()
        
        if(self.spaceModel?.type == .direct){
            self.name.text = self.spaceModel?.title
            self.email.text = self.spaceModel?.localSpaceId
            if((self.spaceModel?.unReadedCount)! > 0){
                self.unreadedLabel.isHidden = false
            }
        }else{
            self.name.text = self.spaceModel?.title
            self.email.text = ""
            if((self.spaceModel?.unReadedCount)! > 0){
                self.unreadedLabel.isHidden = false
            }
        }
    }
    
    private func setUpSpaceImageView(){
        self.spaceImageBackView = UIView(frame: CGRect.zero)
        self.background.addSubview(self.spaceImageBackView!)
        constrain(self.spaceImageBackView!) { view in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY - 20
            view.width == view.superview!.width
            view.height == 100
        }
        self.drawShaowPath()
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.setCorner(45)
        imageView.layer.borderWidth = 2.0
        imageView.layer.borderColor = UIColor.white.cgColor
        self.spaceImageBackView?.addSubview(imageView)
        let contact = self.spaceModel?.contact
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
        return;
    }
    
    // MARK: draw shadow path for cell
    func drawShaowPath(){
        let shadowPath = CGMutablePath()
        let tempPath = UIBezierPath()
        tempPath.addArc(withCenter: CGPoint(70,50), radius: 45, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
        shadowPath.addPath(tempPath.cgPath)
        self.spaceImageBackView?.layer.shadowPath = shadowPath
        self.spaceImageBackView?.layer.shadowColor = UIColor.black.cgColor
        self.spaceImageBackView?.layer.shadowOffset = CGSize(1, 1)
        self.spaceImageBackView?.layer.shadowOpacity = 0.5
        self.spaceImageBackView?.layer.shadowRadius = 3.0
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
        self.spaceImageBackView?.removeFromSuperview()
        self.spaceImageBackView = nil
        self.name.text = nil
        self.email.text = nil
        self.unreadedLabel.isHidden = true
    }
    
    @objc private func buttonTap(sender: UIButton) {
        self.onDelete?(self.spaceModel?.localSpaceId)
    }
    
}
