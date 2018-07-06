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

class PopupOptionView : UIView {
    
    class func buddyOptionPopUp(groupModel: Group, actionColor: UIColor? = nil,  dismissHandler: @escaping (_ action: String) -> Void) {
        
        var inputBox = KTInputBox()
        if(groupModel.groupType == GroupType.singleMember){
            let contact = groupModel[0]
            inputBox = KTInputBox(.Default(0), title: contact?.name, message: contact?.email);
            inputBox.customView = PopupOptionView(contact: contact!)
        }else{
            inputBox = KTInputBox(.Default(0), title:"Group Info", message: groupModel.groupName);
            inputBox.customView = PopupOptionView(group: groupModel)
        }
        inputBox.customiseButton = { button, tag in
            if tag == 1 {
                button.setTitle("Call", for: .normal)
            }
            if tag == 2 {
                button.setTitle("Message", for: .normal)
                if let color = actionColor {
                    button.setTitleColor(color, for: .normal)
                }
            }
            return button;
        }
        inputBox.onMiddle = { (_ btn: UIButton) in
            dismissHandler("Message")
            return true;
        }
        inputBox.onSubmit = {(value: [AnyObject]) in
            dismissHandler("Call")
            return true;
        }
        inputBox.show()
    }
    
    class func show(group: Group, action: String, actionColor: UIColor? = nil,  dismissHandler: @escaping () -> Void) {
        var inputBox = KTInputBox()
        if(group.groupType == GroupType.singleMember){
            inputBox = KTInputBox(.Default(0), title: group[0]?.name, message: group[0]?.email);
            inputBox.customView = PopupOptionView(contact: group[0]!);
        }else{
            inputBox = KTInputBox(.Default(0), title:"Group Info", message: group.groupName);
            inputBox.customView = PopupOptionView(group: group);
        }
        
        inputBox.customiseButton = { button, tag in
            if tag == 1 {
                button.setTitle(action, for: .normal)
                if let color = actionColor {
                    button.setTitleColor(color, for: .normal)
                }
            }
            return button;
        }
        inputBox.onSubmit = {(value: [AnyObject]) in
            dismissHandler()
            return true;
        }
        inputBox.show()
    }
    
    class func show(contact: Contact, left: (String, UIColor, () -> Void), right: (String, UIColor, () -> Void)) {
        let inputBox = KTInputBox(.Default(0), title: contact.name, message: contact.email);
        inputBox.customView = PopupOptionView(contact: contact);
        inputBox.customiseButton = { button, tag in
            if tag == 0 {
                button.setTitle(left.0, for: .normal)
                button.setTitleColor(left.1, for: .normal)
            }
            else if tag == 1 {
                button.setTitle(right.0, for: .normal)
                button.setTitleColor(right.1, for: .normal)
            }
            return button;
        }
        inputBox.onCancel = {
            left.2()
        }
        inputBox.onSubmit = {(value: [AnyObject]) in
            right.2()
            return true;
        }
        inputBox.show()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(contact: Contact) {
        super.init(frame:CGRect(0, 0, 10, 70));
        let avator = contact.avator
        self.addSubview(avator);
        constrain(avator) { view in
            view.width == 50;
            view.height == 50;
            view.center == view.superview!.center;
        }
        avator.layer.borderWidth = 2.0
        avator.layer.borderColor = Constants.Color.Theme.LightControl.cgColor
        avator.setCorner(25)
    }
    init(group: Group){
        super.init(frame:CGRect(0, 0, 10, 70))
        let imageCount = group.grouMemberCount >= 5 ? 5 : group.grouMemberCount
        for index in (0..<imageCount).reversed() {
            var avator: UIImageView?
            if(index == 4 && group.grouMemberCount != 5){
                avator = UIImageView()
                avator?.image = UIImage(cgImage: (UIImage(named:"icon_more")?.cgImage)!, scale: 2.0, orientation: .up)
                avator?.contentMode = .center
                avator?.backgroundColor = UIColor.MKColor.BlueGrey.P800
            }else{
                avator = group[index]?.avator
                avator?.backgroundColor = UIColor.white
            }
            avator?.frame = CGRect(self.center.x - 25, 0, 50, 50)
            avator?.layer.borderWidth = 2.0
            avator?.layer.borderColor = Constants.Color.Theme.LightControl.cgColor
            avator?.setCorner(25)
            self.addSubview(avator!);
            constrain(avator!) { view in
                view.width == 50;
                view.height == 50;
                view.center == (view.superview?.center)!
            }
            if(index%2 == 0){
                avator?.transform = CGAffineTransform(translationX: CGFloat(36*(index/2)), y: 0).scaledBy(x: 1 - (CGFloat(Int((index + 1)/2)) * 0.1), y: 1 - (CGFloat(Int((index + 1)/2)) * 0.1))
            }else{
                avator?.transform = CGAffineTransform(translationX: CGFloat(-36*(index+1)/2), y: 0).scaledBy(x: 1 - (CGFloat(Int((index + 1)/2)) * 0.1), y: 1 - (CGFloat(Int((index + 1)/2)) * 0.1))
            }
        }
    }
    
    
}
