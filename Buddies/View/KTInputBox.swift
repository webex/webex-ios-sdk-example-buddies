import UIKit
import Cartography

class KTInputBox: UIView, UITextFieldDelegate {
    
    public enum Style {
        case Default(Int)
        case Alert;
    }
    
    public let style:KTInputBox.Style;
    
    public var isShowing:Bool {
        return self.alpha > 0 && self.superview != nil && self.converView.superview != nil;
    }
    
    public var title: String?
    
    public var message: String?
    
    public var messageColor:UIColor? {
        didSet {
            if (self.messageLabel != nil) {
                self.messageLabel.textColor = self.messageColor;
            }
        }
    }
    
    public var customiseInputElement: ((UIView, Int) -> UIView)!
    
    public var customiseButton: ((UIButton, Int) -> UIButton)!
    
    public var customiseLabel: ((UILabel)->())!
    
    public var customiseMessageLabel: ((UILabel)->())!
    
    public var onSubmit: ((_ value: [AnyObject]) -> Bool)!
    
    public var onCancel: (() -> Void)!
    
    public var onMiddle: ((UIButton) -> Bool)?
    
    public var titleLabel: UILabel!
    
    public var messageLabel: UILabel!
    
    public var customView:UIView?
    
    public var elements = [UIView]();
    
    public var cancelButton:UIButton!
    
    public var submitButton:UIButton?
    
    public var middleButton:UIButton?
    
    public var blurEffectStyle: UIBlurEffectStyle?
    
    private let textFieldNumber:Int;
    
    private var visualEffectView: UIVisualEffectView?
    
    private var buttonBackgroundView:UIView!;
    
    private var converView:KTVisualEffectView!;
    
    private var _space = ConstraintGroup();
    
    class func alert(error:Error) {
        KTInputBox.alert(title: "Oops", message:  error.localizedDescription);
    }
    
    class func alert(title:String, message:String? = nil, completion:(()->())? = nil) {
        let inputBox = KTInputBox(.Alert, title: title, message: message);
        inputBox.customiseButton = { button, tag in
            if tag == 0 {
                button.setTitle("OK", for: UIControlState.normal)
            }
            return button;
        }
        if let block = completion {
            inputBox.onCancel = {
                block();
            }
        }
        inputBox.show();
    }
    
    class func dismissAndCancel() {
        if let views = UIWindow.main?.subviews(of: KTVisualEffectView.self), views.count > 0{
            for view in views {
                if let view = (view as? UIVisualEffectView)?.contentView {
                    if let box = view.firstSubView(of: KTInputBox.self) as? KTInputBox {
                        box.cancelButtonTapped();
                    }
                }
            }
        }
    }
    
    public init(_ style:Style = .Default(1), title:String? = nil, message:String? = nil) {
        self.style = style;
        switch style {
        case .Default(let num):
            self.textFieldNumber = num;
        case .Alert:
            self.textFieldNumber = 0
        }
        super.init(frame: CGRect.zero);
        self.backgroundColor = UIColor.white
        self.converView = KTVisualEffectView();
        self.title = title;
        self.message = message;
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show () {
        if self.converView.superview == nil {
            guard let window = UIWindow.main else { return }
            self.converView.alpha = 0.0
            self.alpha = 0.0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            window.addSubview(self.converView)
            window.bringSubview(toFront: self.converView)
            window.addSubview(self)
            window.bringSubview(toFront:self)
            
            constrain(self.converView) { view in
                view.size == view.superview!.size;
                view.center == view.superview!.center;
            }
            let weight = min(325, window.frame.size.width - 50);
            let height = self.setupView(width: weight);

            constrain(self) { view in
                view.width == weight;
                view.height == height;
                view.centerX == view.superview!.centerX;
            }
            constrain(self, replace: self._space) { view in
                view.centerY == view.superview!.centerY;
            }
            UIView.animate(withDuration: 0.15, animations: { () -> Void in
                UIView.setAnimationCurve(.easeInOut)
                self.converView.alpha = 0.8
                self.alpha = 1
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
 
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(KTInputBox.keyboardDidShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(KTInputBox.keyboardDidHide(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        }
    }
    
    public func hide () {
        self.alpha = 0.4
        self.converView.alpha = 0.5
        UIView.animate(withDuration: 0.15, animations: { () -> Void in
            self.alpha = 0
            self.converView.alpha = 0
            self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (completed) -> Void in
            self.removeFromSuperview()
            self.converView.removeFromSuperview();
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        }
    }
    
    private func setupView(width:CGFloat) -> CGFloat {
        self.layer.cornerRadius = 4.0
        self.setShadow(color: Constants.Color.Theme.Shadow, radius: 1, opacity: 0.5, offsetX: 0, offsetY: 1);
        //self.layer.masksToBounds = true
        self.visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: self.blurEffectStyle ?? UIBlurEffectStyle.extraLight))
        
        let padding: CGFloat = 20.0
        let width = width - padding * 2
        
        self.titleLabel = UILabel(frame: CGRect(padding, padding, width, 20))
        self.titleLabel.font = Constants.Font.InputBox.Title
        self.titleLabel.text = self.title
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = (self.blurEffectStyle == .dark) ? UIColor.white : Constants.Color.Theme.DarkControl
        self.visualEffectView?.contentView.addSubview(self.titleLabel)
        _ = self.titleLabel.reCenter()
        if let block = self.customiseLabel {
            block(self.titleLabel)
        }
        
        var previousView:UIView = self.titleLabel;
        
        for index in 0 ..< self.textFieldNumber {
            let textInput = MKTextField(frame: CGRect(padding, previousView.frame.bottom + (index == 0 ? 15 : 10), width, 40))
            textInput.delegate = self;
            textInput.textAlignment = .center
            textInput.tintColor = Constants.Color.Theme.Main;
            textInput.layer.borderColor = UIColor.clear.cgColor
            textInput.font = Constants.Font.InputBox.Input
            textInput.bottomBorderEnabled = true;
            textInput.floatingPlaceholderEnabled = true
            textInput.rippleEnabled = false;
            textInput.returnKeyType = .next;
            if index == self.textFieldNumber - 1 {
                textInput.returnKeyType = .default;
            }
            var view:UIView = textInput;
            if let block = self.customiseInputElement {
                view = block(view, index)
            }
            self.elements.append(view)
            self.visualEffectView?.contentView.addSubview(view)
            previousView = view;
        }
        
        previousView = self.elements.last ?? self.titleLabel
        
        if let view = self.customView {
            view.frame = CGRect(padding, previousView.frame.bottom + 15, width, view.bounds.height);
            self.visualEffectView?.contentView.addSubview(view);
            previousView = view;
        }
        
        let isComments = self.elements.count > 0 || self.customView != nil;
        
        self.messageLabel = UILabel(frame: CGRect(padding, previousView.frame.bottom + 15, width, 20))
        self.messageLabel.numberOfLines = 5;
        self.messageLabel.font = isComments ? Constants.Font.InputBox.Comments : Constants.Font.InputBox.Message;
        self.messageLabel.text = self.message
        self.messageLabel.textAlignment = .center
        self.messageLabel.textColor = (self.blurEffectStyle == .dark) ? UIColor.white : Constants.Color.Theme.DarkControl
        self.visualEffectView?.contentView.addSubview(self.messageLabel)
        _ = self.messageLabel.reCenter();
        if let block = self.customiseMessageLabel {
            block(self.messageLabel);
        }
        
        let buttonNum:CGFloat;
        switch self.style {
        case .Alert:
            buttonNum = 1;
        default:
            if let _ = self.onMiddle {
                buttonNum = 3;
            }
            else {
                buttonNum = 2;
            }
        }
        
        let buttonHeight: CGFloat = 45.0
        let buttonWidth = (width + padding * 2)  / buttonNum
        
        self.buttonBackgroundView = UIView(frame:CGRect(0, self.messageLabel.frame.bottom + 10, width, buttonHeight));
        self.visualEffectView?.contentView.addSubview(self.buttonBackgroundView)
        
        self.cancelButton = UIButton(frame: CGRect(0, 0, buttonWidth, buttonHeight))
        self.cancelButton.setTitle("Cancel", for: UIControlState.normal)
        self.cancelButton.addTarget(self, action: #selector(KTInputBox.cancelButtonTapped), for: .touchUpInside)
        self.cancelButton.titleLabel?.font = Constants.Font.InputBox.Button;
        self.cancelButton.setTitleColor((self.blurEffectStyle == .dark) ? UIColor.white : Constants.Color.Theme.DarkControl, for: .normal)
        self.cancelButton.setTitleColor(Constants.Color.Theme.Main, for: .highlighted)
        self.cancelButton.backgroundColor = (self.blurEffectStyle == .dark) ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.2)
        self.cancelButton.layer.borderColor = Constants.Color.Theme.LightBackground.cgColor //UIColor(white: 0, alpha: 0.1).CGColor
        self.cancelButton.layer.borderWidth = 0.5
        if let block = self.customiseButton {
            self.cancelButton = block(self.cancelButton, 0);
        }
        self.buttonBackgroundView.addSubview(self.cancelButton);
        
        if buttonNum == 3 {
            self.middleButton = UIButton(frame: CGRect(buttonWidth, 0, buttonWidth, buttonHeight))
            self.middleButton?.setTitle("Middle", for: UIControlState.normal)
            self.middleButton?.addTarget(self, action: #selector(KTInputBox.middleButtonTapped(button:)), for: .touchUpInside)
            self.middleButton?.titleLabel?.font = Constants.Font.InputBox.Button;
            self.middleButton?.setTitleColor((self.blurEffectStyle == .dark) ? UIColor.white : Constants.Color.Theme.DarkControl, for: .normal)
            self.middleButton?.setTitleColor(Constants.Color.Theme.Main, for: .highlighted)
            self.middleButton?.backgroundColor = (self.blurEffectStyle == .dark) ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.2)
            self.middleButton?.layer.borderColor = Constants.Color.Theme.LightBackground.cgColor //UIColor(white: 0, alpha: 0.1).CGColor
            self.middleButton?.layer.borderWidth = 0.5
            self.middleButton?.addTarget(self, action: #selector(KTInputBox.cancelButtonTapped), for: .touchUpInside)
            if let block = self.customiseButton {
                self.middleButton = block(self.middleButton!, 2);
            }
            self.buttonBackgroundView.addSubview(self.middleButton!)
        }
        
        if buttonNum >= 2 {
            self.submitButton = UIButton(frame: CGRect(buttonWidth * (buttonNum - 1), 0, buttonWidth, buttonHeight))
            self.submitButton?.setTitle("OK", for: UIControlState.normal)
            self.submitButton?.addTarget(self, action: #selector(KTInputBox.submitButtonTapped), for: .touchUpInside)
            self.submitButton?.titleLabel?.font = Constants.Font.InputBox.Button;
            self.submitButton?.setTitleColor((self.blurEffectStyle == .dark) ? UIColor.white : Constants.Color.Theme.DarkControl, for: .normal)
            self.submitButton?.setTitleColor(Constants.Color.Theme.Main, for: .highlighted)
            self.submitButton?.backgroundColor = (self.blurEffectStyle == .dark) ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.2)
            self.submitButton?.layer.borderColor = Constants.Color.Theme.LightBackground.cgColor //UIColor(white: 0, alpha: 0.1).CGColor
            self.submitButton?.layer.borderWidth = 0.5
            if let block = self.customiseButton {
                self.submitButton = block(self.submitButton!, 1);
            }
            self.buttonBackgroundView.addSubview(self.submitButton!);
        }
        
        let height = self.buttonBackgroundView.frame.bottom;
        self.visualEffectView!.frame = CGRect(0, 0, width, height)
        self.addSubview(self.visualEffectView!)
        constrain(self.visualEffectView!) { view in
            view.size == view.superview!.size;
            view.center == view.superview!.center;
        }
        return height;
    }
    
    @objc
    func cancelButtonTapped () {
        if self.onCancel != nil {
            self.onCancel()
        }
        self.hide()
    }
    
    @objc func submitButtonTapped () {
        if let block = self.onSubmit {
            let values:[String] = self.elements.compactMap { element in
                if let textField = element as? UITextField {
                    return textField.text;
                }
                return nil;
            }
            if block(values as [AnyObject]) {
                self.hide()
            }
        }
        else {
            self.hide()
        }
    }
    
    @objc
    func middleButtonTapped(button:UIButton) {
        if let block = self.onMiddle {
            if block(button) {
                self.hide()
            }
        }
        else {
            self.hide()
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let index = self.elements.index(of: textField) {
            if index < self.textFieldNumber - 1 {
                if let view = self.elements.safeObjectAtIndex(index + 1) {
                    view.becomeFirstResponder();
                }
            }
            else if index == self.textFieldNumber - 1 {
                self.submitButtonTapped();
            }
        }
        return true;
    }
    
    // MARK: Keyboard Changes
    @objc
    func keyboardDidShow (notification: NSNotification) {
        if let superview = self.superview {
            let keyboardFrame = self._keyboardFrame(noti: notification);
            let bottom = superview.center.y + self.frame.height/2;
            let distance:CGFloat;
            if keyboardFrame.top > bottom {
                distance = 0;
            }
            else if keyboardFrame.top == bottom {
                distance = 20;
            }
            else {
                distance = bottom - keyboardFrame.top + 20;
            }
            constrain(self, replace: self._space) { view in
                view.centerY == view.superview!.centerY - distance;
            }
            self._animate(notification);
        }
    }
    @objc
    func keyboardDidHide (notification: NSNotification) {
        if let _ = self.superview {
            constrain(self, replace: self._space) { view in
                view.centerY == view.superview!.centerY;
            }
            self._animate(notification);
        }
    }
    
    private func _keyboardFrame(noti:NSNotification) -> CGRect {
        if let userInfo = noti.userInfo, let value = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardEndFrame = value.cgRectValue;
            let convertedKeyboardEndFrame = self.converView.convert(keyboardEndFrame, from: self.converView.window)
            return convertedKeyboardEndFrame;
        }
        return CGRect.zero;
    }
    
    private func _animate(_ noti:NSNotification) {
        if let userInfo = noti.userInfo, let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let rawAnimationCurve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uint32Value {
            let curve = UIViewAnimationOptions(rawValue:UInt(rawAnimationCurve << 15));
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.beginFromCurrentState, curve], animations: {
                self.converView.layoutIfNeeded()
            }, completion: nil)
        }
        else {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.converView.layoutIfNeeded()
            })
        }
    }
    
    //    class BackgroundView : UIView {
    //
    //        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    //            self.endEditing(true)
    //        }
    //    }
}

class KTVisualEffectView : UIVisualEffectView {
    
    init() {
        super.init(effect: UIBlurEffect(style: .extraLight))
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.clear
        self.layer.masksToBounds = true
        let offset = 20.0
        let motionEffectsX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        motionEffectsX.maximumRelativeValue = offset
        motionEffectsX.minimumRelativeValue = -offset
        let motionEffectsY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        motionEffectsY.maximumRelativeValue = offset
        motionEffectsY.minimumRelativeValue = -offset
        let space = UIMotionEffectGroup()
        space.motionEffects = [motionEffectsX, motionEffectsY]
        self.addMotionEffect(space)
    }
}
