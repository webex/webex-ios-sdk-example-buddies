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
import CoreImage
import CoreGraphics


extension UIImage {
    
    convenience init?(color:UIColor, size:CGSize) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        self.init(cgImage:UIGraphicsGetImageFromCurrentImageContext()!.cgImage!)
        UIGraphicsEndImageContext()
    }
    
    public func imageWithColor(color:UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
        let context = UIGraphicsGetCurrentContext();
        context!.translateBy(x: 0, y: self.size.height);
        context!.scaleBy(x: 1.0, y: -1.0);
        context!.setBlendMode(.normal);
        let rect = CGRect(0, 0, self.size.width, self.size.height);
        context!.clip(to: rect, mask: self.cgImage!);
        color.setFill();
        context!.fill(rect);
        let ret = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return ret!;
    }
    
    convenience init?(text: String, font: UIFont = UIFont.systemFont(ofSize: 18), color: UIColor = UIColor.white, backgroundColor: UIColor = UIColor.gray, size:CGSize = CGSize(100, 100)) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        label.font = font
        label.text = text
        label.textColor = color
        label.textAlignment = .center
        label.backgroundColor = backgroundColor
        let image = label.toImage();
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.init(cgImage:UIGraphicsGetImageFromCurrentImageContext()!.cgImage!)
        UIGraphicsEndImageContext()
    }
}
