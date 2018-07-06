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
import NVActivityIndicatorView

class KTActivityIndicator : UIView {
    
    static let singleton = KTActivityIndicator(frame:CGRect.zero);
    
    var title:String? = "" {
        didSet {
            if let label = self._titleLabel {
                if let title = self.title {
                    if label.isHidden {
                        label.isHidden = false;
                    }
                    label.text = title;
                }
                else {
                    label.isHidden = true;
                    label.text = "";
                }
            }
        }
    }
    
    var titleFont:UIFont = Constants.Font.Indicator;
    
    var titleColor:UIColor = Constants.Color.Theme.Main;
    
    var spinnerColor:UIColor = Constants.Color.Theme.Main;
    
    private var _background:UIView?;
    
    private var _coverView:UIVisualEffectView?;
    
    private var _titleLabel:UILabel?;
    
    private var _spinnerBack:UIView?;
    
    private var _spinnerView:NVActivityIndicatorView?;
    
    var showing: Bool {
        if let view = self._spinnerView, view.isAnimating {
            return true;
        }
        return false;
    }
    
    func show(title:String?, at:UIView = UIApplication.shared.keyWindow!, offset:CGFloat = 0, size:CGFloat = 156, allowUserInteraction:Bool = false) {
        self.hide();
        self.title = title;
        self.frame = CGRect.zero;
        self.backgroundColor = UIColor.clear;
        
        let background:UIView;
        if (allowUserInteraction) {
            background = at;
        }
        else {
            self._background = UIView(frame: CGRect.zero);
            self._background?.backgroundColor = UIColor.clear;
            at.addSubview(self._background!);
            constrain(self._background!) { view in
                view.size == view.superview!.size;
                view.center == view.superview!.center;
            }
            background = self._background!;
        }
        
        if size != 0 {
            self._coverView = KTVisualEffectView();
            background.addSubview(self._coverView!);
            constrain(self._coverView!) { view in
                if size == CGFloat.greatestFiniteMagnitude {
                    view.size == view.superview!.size;
                }
                else {
                    view.width == size;
                    view.height == size;
                }
                view.centerX == view.superview!.centerX;
                view.centerY == view.superview!.centerY + offset;
            }
            if size != CGFloat.greatestFiniteMagnitude {
                self._coverView?.setCorner(10);
            }
            self._coverView!.contentView.addSubview(self);
            constrain(self) { view in
                view.center == view.superview!.center;
            }
        }
        else {
            background.addSubview(self);
            constrain(self) { view in
                view.centerX == view.superview!.centerX;
                view.centerY == view.superview!.centerY + offset;
            }
        }
        constrain(self) { view in
            view.width == view.superview!.width;
            view.height == 60;
        }
        
        self._titleLabel = UILabel(frame: CGRect.zero);
        self._titleLabel?.text = self.title;
        self._titleLabel?.backgroundColor = UIColor.clear;
        self._titleLabel?.numberOfLines = 1
        self._titleLabel?.textAlignment = NSTextAlignment.center
        self._titleLabel?.font = self.titleFont;
        self._titleLabel?.textColor = self.titleColor;
        self._titleLabel?.isHidden = self.title == nil
        self.addSubview(self._titleLabel!);
        
        self._spinnerBack = UIView(frame: CGRect.zero);
        self._spinnerBack?.backgroundColor = UIColor.clear;
        self.addSubview(self._spinnerBack!);
        
        constrain(self._spinnerBack!, self._titleLabel!) { view1, view2 in
            view1.width == view1.superview!.width;
            view1.height == view1.superview!.height/2;
            view2.width == view2.superview!.width;
            view2.height == view2.superview!.height/2;
            view1.top == view1.superview!.top;
            view1.centerX == view1.superview!.centerX;
            view2.bottom == view1.superview!.bottom;
            view2.centerX == view2.superview!.centerX;
        }
        self._spinnerView = NVActivityIndicatorView(frame: CGRect.zero, type:.ballBeat, color:self.spinnerColor, padding:-8);
        //self._spinnerView?.hidesWhenStopped = false;
        self._spinnerBack!.addSubview(self._spinnerView!);
        self._spinnerView?.startAnimating();
    }
    
    func hide() {
        self._spinnerView?.stopAnimating();
        self._spinnerView?.removeFromSuperview();
        self._spinnerView = nil;
        self._spinnerBack?.removeFromSuperview();
        self._spinnerBack = nil;
        self._titleLabel?.removeFromSuperview();
        self._titleLabel = nil;
        self.removeFromSuperview();
        self._coverView?.removeFromSuperview();
        self._coverView = nil;
        self._background?.removeFromSuperview();
        self._background = nil;
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        if let spinner = self._spinnerView, spinner.isAnimating {
            spinner.stopAnimating();
            spinner.frame = self._spinnerBack!.bounds;
            spinner.startAnimating();
        }
    }
    
}

