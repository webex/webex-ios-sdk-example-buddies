//
//  MKTextField.swift
//  MaterialKit
//
//  Created by LeVan Nghia on 11/14/14.
//  Copyright (c) 2014 Le Van Nghia. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable
open class MKTextField : UITextField {
    
    @IBInspectable open var padding: CGSize = CGSize(width: 5, height: 5)
    @IBInspectable open var floatingLabelBottomMargin: CGFloat = 2.0
    @IBInspectable public var labelTitle: String? {
        didSet {
            updateFloatingLabelText()
        }
    }
    
    @IBInspectable open var floatingPlaceholderEnabled: Bool = false {
        didSet {
            self.updateFloatingLabelText()
        }
    }
    
    @IBInspectable open var maskEnabled: Bool = true {
        didSet {
            mkLayer.maskEnabled = maskEnabled
        }
    }
    @IBInspectable open var cornerRadius: CGFloat = 0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
            mkLayer.superLayerDidResize()
        }
    }
    @IBInspectable open var elevation: CGFloat = 0 {
        didSet {
            mkLayer.elevation = elevation
        }
    }
    @IBInspectable open var shadowOffset: CGSize = CGSize.zero {
        didSet {
            mkLayer.shadowOffset = shadowOffset
        }
    }
    @IBInspectable open var roundingCorners: UIRectCorner = UIRectCorner.allCorners {
        didSet {
            mkLayer.roundingCorners = roundingCorners
        }
    }
    @IBInspectable open var rippleEnabled: Bool = true {
        didSet {
            mkLayer.rippleEnabled = rippleEnabled
        }
    }
    @IBInspectable open var rippleDuration: CFTimeInterval = 0.35 {
        didSet {
            mkLayer.rippleDuration = rippleDuration
        }
    }
    @IBInspectable open var rippleScaleRatio: CGFloat = 1.0 {
        didSet {
            mkLayer.rippleScaleRatio = rippleScaleRatio
        }
    }
    @IBInspectable open var rippleLayerColor: UIColor = UIColor(hex: 0xEEEEEE) {
        didSet {
            mkLayer.setRippleColor(rippleLayerColor)
        }
    }
    @IBInspectable open var backgroundAnimationEnabled: Bool = true {
        didSet {
            mkLayer.backgroundAnimationEnabled = backgroundAnimationEnabled
        }
    }
    
    override open var bounds: CGRect {
        didSet {
            mkLayer.superLayerDidResize()
        }
    }
    
    // floating label
    @IBInspectable open var floatingLabelFont: UIFont = UIFont.boldSystemFont(ofSize: 10.0) {
        didSet {
            floatingLabel.font = floatingLabelFont
        }
    }
    @IBInspectable open var floatingLabelTextColor: UIColor = UIColor.lightGray {
        didSet {
            floatingLabel.textColor = floatingLabelTextColor
        }
    }
    
    @IBInspectable open var bottomBorderEnabled: Bool = true {
        didSet {
            bottomBorderLayer?.removeFromSuperlayer()
            bottomBorderLayer = nil
            if bottomBorderEnabled {
                bottomBorderLayer = CALayer()
                bottomBorderLayer?.frame = CGRect(x: 0, y: layer.bounds.height - 1, width: bounds.width, height: 1)
                bottomBorderLayer?.backgroundColor = UIColor.MKColor.Grey.P500.cgColor
                layer.addSublayer(bottomBorderLayer!)
            }
        }
    }
    @IBInspectable open var bottomBorderWidth: CGFloat = 1.0
    @IBInspectable open var bottomBorderColor: UIColor = UIColor.lightGray {
        didSet {
            if bottomBorderEnabled {
                bottomBorderLayer?.backgroundColor = bottomBorderColor.cgColor
            }
        }
    }
    @IBInspectable open var bottomBorderHighlightWidth: CGFloat = 1.75
    override open var attributedPlaceholder: NSAttributedString? {
        didSet {
            updateFloatingLabelText()
        }
    }
    
    fileprivate lazy var mkLayer: MKLayer = MKLayer(withView: self)
    fileprivate var floatingLabel: UILabel!
    fileprivate var bottomBorderLayer: CALayer?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    fileprivate func setupLayer() {
        mkLayer.elevation = self.elevation
        self.layer.cornerRadius = self.cornerRadius
        mkLayer.elevationOffset = self.shadowOffset
        mkLayer.roundingCorners = self.roundingCorners
        mkLayer.maskEnabled = self.maskEnabled
        mkLayer.rippleScaleRatio = self.rippleScaleRatio
        mkLayer.rippleDuration = self.rippleDuration
        mkLayer.rippleEnabled = self.rippleEnabled
        mkLayer.backgroundAnimationEnabled = self.backgroundAnimationEnabled
        mkLayer.setRippleColor(self.rippleLayerColor)
        
        layer.borderWidth = 1.0
        borderStyle = .none
        
        // floating label
        floatingLabel = UILabel()
        floatingLabel.font = floatingLabelFont
        floatingLabel.alpha = 0.0
        updateFloatingLabelText()
        
        addSubview(floatingLabel)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        bottomBorderLayer?.backgroundColor = isFirstResponder ? tintColor.cgColor : bottomBorderColor.cgColor
        let borderWidth = isFirstResponder ? bottomBorderHighlightWidth : bottomBorderWidth
        bottomBorderLayer?.frame = CGRect(x: 0, y: layer.bounds.height - borderWidth, width: layer.bounds.width, height: borderWidth)
        
        if !floatingPlaceholderEnabled {
            return
        }
        
        if let text = text , text.isEmpty == false {
            floatingLabel.textColor = isFirstResponder ? tintColor : floatingLabelTextColor
            if floatingLabel.alpha == 0 {
                showFloatingLabel()
            }
        } else {
            hideFloatingLabel()
        }
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        var newRect = CGRect(x: rect.origin.x + padding.width, y: rect.origin.y,
                             width: rect.size.width - 2 * padding.width, height: rect.size.height)
        
        if !floatingPlaceholderEnabled {
            return newRect
        }
        
        if let text = text , text.isEmpty == false {
            let dTop = floatingLabel.font.lineHeight + floatingLabelBottomMargin
            newRect = newRect.inset(by: UIEdgeInsets(top: dTop, left: 0.0, bottom: 0.0, right: 0.0))
        }
        
        return newRect
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    // MARK: Touch
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        mkLayer.touchesBegan(touches, withEvent: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        mkLayer.touchesEnded(touches, withEvent: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        mkLayer.touchesCancelled(touches, withEvent: event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        mkLayer.touchesMoved(touches, withEvent: event)
    }
}

// MARK - private methods
private extension MKTextField {
    func setFloatingLabelOverlapTextField() {
        let textRect = self.textRect(forBounds: bounds)
        var originX = textRect.origin.x
        switch textAlignment {
        case .center:
            originX += textRect.size.width / 2 - floatingLabel.bounds.width / 2
        case .right:
            originX += textRect.size.width - floatingLabel.bounds.width
        default:
            break
        }
        floatingLabel.frame = CGRect(x: originX, y: padding.height,
                                     width: floatingLabel.frame.size.width, height: floatingLabel.frame.size.height)
    }
    
    func showFloatingLabel() {
        let curFrame = floatingLabel.frame
        floatingLabel.frame = CGRect(x: curFrame.origin.x, y: bounds.height / 2, width: curFrame.width, height: curFrame.height)
        UIView.animate(withDuration: 0.45, delay: 0.0, options: .curveEaseOut,
                       animations: {
                        self.floatingLabel.alpha = 1.0
                        self.floatingLabel.frame = curFrame
        }, completion: nil)
    }
    
    func hideFloatingLabel() {
        floatingLabel.alpha = 0.0
    }
    
    func updateFloatingLabelText() {
        //floatingLabel.attributedText = attributedPlaceholder
        floatingLabel.text = self.labelTitle ?? self.placeholder;
        floatingLabel.sizeToFit()
        setFloatingLabelOverlapTextField()
    }
}


let kMKClearEffectsDuration = 0.3

open class MKLayer: CALayer  , CAAnimationDelegate{
    
    open var maskEnabled: Bool = true {
        didSet {
            self.mask = maskEnabled ? maskLayer : nil
        }
    }
    open var rippleEnabled: Bool = true
    open var rippleScaleRatio: CGFloat = 1.0 {
        didSet {
            self.calculateRippleSize()
        }
    }
    
    open var rippleDuration: CFTimeInterval = 0.35
    open var elevation: CGFloat = 0 {
        didSet {
            self.enableElevation()
        }
    }
    open var elevationOffset: CGSize = CGSize.zero {
        didSet {
            self.enableElevation()
        }
    }
    open var roundingCorners: UIRectCorner = UIRectCorner.allCorners {
        didSet {
            self.enableElevation()
        }
    }
    open var backgroundAnimationEnabled: Bool = true
    
    fileprivate var superView: UIView?
    fileprivate var superLayer: CALayer?
    fileprivate var rippleLayer: CAShapeLayer?
    fileprivate var backgroundLayer: CAShapeLayer?
    fileprivate var maskLayer: CAShapeLayer?
    fileprivate var userIsHolding: Bool = false
    fileprivate var effectIsRunning: Bool = false
    
    fileprivate override init(layer: Any) {
        super.init()
    }
    
    public init(superLayer: CALayer) {
        super.init()
        self.superLayer = superLayer
        setup()
    }
    
    public init(withView view: UIView) {
        super.init()
        self.superView = view
        self.superLayer = view.layer
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.superLayer = self.superlayer
        self.setup()
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            if keyPath == "bounds" {
                self.superLayerDidResize()
            } else if keyPath == "cornerRadius" {
                if let superLayer = superLayer {
                    setMaskLayerCornerRadius(superLayer.cornerRadius)
                }
            }
        }
    }
    
    open func superLayerDidResize() {
        if let superLayer = self.superLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.frame = superLayer.bounds
            self.setMaskLayerCornerRadius(superLayer.cornerRadius)
            self.calculateRippleSize()
            CATransaction.commit()
        }
    }
    
    
    
    
    open  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim == self.animation(forKey: "opacityAnim") {
            self.opacity = 0
        } else if flag {
            if userIsHolding {
                effectIsRunning = false
            } else {
                self.clearEffects()
            }
        }
    }
    
    open func startEffects(atLocation touchLocation: CGPoint) {
        userIsHolding = true
        if let rippleLayer = self.rippleLayer {
            rippleLayer.timeOffset = 0
            rippleLayer.speed = backgroundAnimationEnabled ? 1 : 1.1
            if rippleEnabled {
                startRippleEffect(nearestInnerPoint(touchLocation))
            }
        }
    }
    
    open func stopEffects() {
        userIsHolding = false
        if !effectIsRunning {
            self.clearEffects()
        } else if let rippleLayer = rippleLayer {
            rippleLayer.timeOffset = rippleLayer.convertTime(CACurrentMediaTime(), from: nil)
            rippleLayer.beginTime = CACurrentMediaTime()
            rippleLayer.speed = 1.2
        }
    }
    
    open func stopEffectsImmediately() {
        userIsHolding = false
        effectIsRunning = false
        if rippleEnabled {
            if let rippleLayer = self.rippleLayer,
                let backgroundLayer = self.backgroundLayer {
                rippleLayer.removeAllAnimations()
                backgroundLayer.removeAllAnimations()
                rippleLayer.opacity = 0
                backgroundLayer.opacity = 0
            }
        }
    }
    
    open func setRippleColor(_ color: UIColor,
                             withRippleAlpha rippleAlpha: CGFloat = 0.3,
                             withBackgroundAlpha backgroundAlpha: CGFloat = 0.3) {
        if let rippleLayer = self.rippleLayer,
            let backgroundLayer = self.backgroundLayer {
            rippleLayer.fillColor = color.withAlphaComponent(rippleAlpha).cgColor
            backgroundLayer.fillColor = color.withAlphaComponent(backgroundAlpha).cgColor
        }
    }
    
    // MARK: Touches
    open func touchesBegan(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let first = touches.first, let superView = self.superView {
            let point = first.location(in: superView)
            startEffects(atLocation: point)
        }
    }
    
    open func touchesEnded(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.stopEffects()
    }
    
    open func touchesCancelled(_ touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.stopEffects()
    }
    
    open func touchesMoved(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
    }
    
    // MARK: Private
    fileprivate func setup() {
        rippleLayer = CAShapeLayer()
        rippleLayer!.opacity = 0
        self.addSublayer(rippleLayer!)
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer!.opacity = 0
        backgroundLayer!.frame = superLayer!.bounds
        self.addSublayer(backgroundLayer!)
        
        maskLayer = CAShapeLayer()
        self.setMaskLayerCornerRadius(superLayer!.cornerRadius)
        self.mask = maskLayer
        
        self.frame = superLayer!.bounds
        superLayer!.addSublayer(self)
        superLayer!.addObserver(
            self,
            forKeyPath: "bounds",
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: nil)
        superLayer!.addObserver(
            self,
            forKeyPath: "cornerRadius",
            options: NSKeyValueObservingOptions(rawValue: 0),
            context: nil)
        
        self.enableElevation()
        self.superLayerDidResize()
    }
    
    fileprivate func setMaskLayerCornerRadius(_ radius: CGFloat) {
        if let maskLayer = self.maskLayer {
            maskLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: radius).cgPath
        }
    }
    
    fileprivate func nearestInnerPoint(_ point: CGPoint) -> CGPoint {
        let centerX = self.bounds.midX
        let centerY = self.bounds.midY
        let dx = point.x - centerX
        let dy = point.y - centerY
        let dist = sqrt(dx * dx + dy * dy)
        if let backgroundLayer = self.rippleLayer { // TODO: Fix it
            if dist <= backgroundLayer.bounds.size.width / 2 {
                return point
            }
            let d = backgroundLayer.bounds.size.width / 2 / dist
            let x = centerX + d * (point.x - centerX)
            let y = centerY + d * (point.y - centerY)
            return CGPoint(x: x, y: y)
        }
        return CGPoint.zero
    }
    
    fileprivate func clearEffects() {
        if let rippleLayer = self.rippleLayer,
            let backgroundLayer = self.backgroundLayer {
            rippleLayer.timeOffset = 0
            rippleLayer.speed = 1
            
            if rippleEnabled {
                rippleLayer.removeAllAnimations()
                backgroundLayer.removeAllAnimations()
                self.removeAllAnimations()
                
                let opacityAnim = CABasicAnimation(keyPath: "opacity")
                opacityAnim.fromValue = 1
                opacityAnim.toValue = 0
                opacityAnim.duration = kMKClearEffectsDuration
                opacityAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                opacityAnim.isRemovedOnCompletion = false
                opacityAnim.fillMode = CAMediaTimingFillMode.forwards
                opacityAnim.delegate = self
                
                self.add(opacityAnim, forKey: "opacityAnim")
            }
        }
    }
    
    fileprivate func startRippleEffect(_ touchLocation: CGPoint) {
        self.removeAllAnimations()
        self.opacity = 1
        if let rippleLayer = self.rippleLayer,
            let backgroundLayer = self.backgroundLayer,
            let superLayer = self.superLayer {
            rippleLayer.removeAllAnimations()
            backgroundLayer.removeAllAnimations()
            
            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 0
            scaleAnim.toValue = 1
            scaleAnim.duration = rippleDuration
            scaleAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            scaleAnim.delegate = self
            
            let moveAnim = CABasicAnimation(keyPath: "position")
            moveAnim.fromValue = NSValue(cgPoint: touchLocation)
            moveAnim.toValue = NSValue(cgPoint: CGPoint(
                x: superLayer.bounds.midX,
                y: superLayer.bounds.midY))
            moveAnim.duration = rippleDuration
            moveAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            
            effectIsRunning = true
            rippleLayer.opacity = 1
            if backgroundAnimationEnabled {
                backgroundLayer.opacity = 1
            } else {
                backgroundLayer.opacity = 0
            }
            
            rippleLayer.add(moveAnim, forKey: "position")
            rippleLayer.add(scaleAnim, forKey: "scale")
        }
    }
    
    fileprivate func calculateRippleSize() {
        if let superLayer = self.superLayer {
            let superLayerWidth = superLayer.bounds.width
            let superLayerHeight = superLayer.bounds.height
            let center = CGPoint(
                x: superLayer.bounds.midX,
                y: superLayer.bounds.midY)
            let circleDiameter =
                sqrt(
                    powf(Float(superLayerWidth), 2)
                        +
                        powf(Float(superLayerHeight), 2)) * Float(rippleScaleRatio)
            let subX = center.x - CGFloat(circleDiameter) / 2
            let subY = center.y - CGFloat(circleDiameter) / 2
            
            if let rippleLayer = self.rippleLayer {
                rippleLayer.frame = CGRect(
                    x: subX, y: subY,
                    width: CGFloat(circleDiameter), height: CGFloat(circleDiameter))
                rippleLayer.path = UIBezierPath(ovalIn: rippleLayer.bounds).cgPath
                
                if let backgroundLayer = self.backgroundLayer {
                    backgroundLayer.frame = rippleLayer.frame
                    backgroundLayer.path = rippleLayer.path
                }
            }
        }
    }
    
    fileprivate func enableElevation() {
        if let superLayer = self.superLayer {
            superLayer.shadowOpacity = 0.5
            superLayer.shadowRadius = elevation / 4
            superLayer.shadowColor = UIColor.black.cgColor
            superLayer.shadowOffset = elevationOffset
        }
    }
}
