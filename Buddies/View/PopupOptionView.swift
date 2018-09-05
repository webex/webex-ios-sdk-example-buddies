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
import WebexSDK
class PopupOptionView : UIView {
    
    class func buddyOptionPopUp(spaceModel: SpaceModel, actionColor: UIColor? = nil,  dismissHandler: @escaping (_ action: String) -> Void) {
        
        var inputBox = KTInputBox()
        if(spaceModel.type == SpaceType.direct){
            let contact = spaceModel.contact
            inputBox = KTInputBox(.Default(0), title: contact?.name, message: contact?.email);
            inputBox.customView = PopupOptionView(contact: contact!)
        }else{
            inputBox = KTInputBox(.Default(0), title:"Space Info", message: spaceModel.title);
            inputBox.customView = PopupOptionView(spaceModel: spaceModel)
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
    
    class func show(spaceModel: SpaceModel, action: String, actionColor: UIColor? = nil,  dismissHandler: @escaping () -> Void) {
        var inputBox = KTInputBox()
        if(spaceModel.type == SpaceType.direct){
            inputBox = KTInputBox(.Default(0), title: spaceModel.title, message: spaceModel.localSpaceId);
            inputBox.customView = PopupOptionView(spaceModel: spaceModel);
        }else{
            inputBox = KTInputBox(.Default(0), title:"Space Info", message: spaceModel.title);
            inputBox.customView = PopupOptionView(spaceModel: spaceModel);
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
    init(spaceModel: SpaceModel){
        super.init(frame:CGRect(0, 0, 10, 70))
    }
    
}
