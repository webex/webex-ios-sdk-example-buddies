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
import QuartzCore

extension UIView {
    
    func setShadow(color:UIColor, radius:CGFloat, opacity:Float, offsetX:CGFloat, offsetY:CGFloat) {
        self.layer.shadowColor = color.cgColor;
        self.layer.shadowRadius = radius;
        self.layer.shadowOpacity = opacity;
        self.layer.shadowOffset = CGSize(width: offsetX, height: offsetY)
        self.layer.shouldRasterize = true;
        self.layer.rasterizationScale = UIScreen.main.scale;
    }
    
    func setCorner(_ cr:Int) {
        self.layer.cornerRadius = CGFloat(cr);
        self.layer.masksToBounds = true;
        self.layer.shouldRasterize = true;
        self.layer.rasterizationScale = UIScreen.main.scale;
    }
    
    func subviews(of:AnyClass) -> [UIView] {
        return self.subviews.filter { view in
            return view.isKind(of: of)
        }
    }
    
    func firstSubView(of:AnyClass) -> UIView? {
        for view in self.subviews.lazy.reversed() {
            if view.isKind(of: of) {
                return view;
            }
        }
        return nil;
    }
    
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    func toImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0.0);
        //self.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!;
    }
    
}
