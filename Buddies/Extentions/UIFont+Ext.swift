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

extension UIFont {
    
    static func safeFont(_ name:String?, size:CGFloat, notNil:Bool = true) -> UIFont? {
        var ret:UIFont?;
        if name == Constants.Font.SystemFont || name == ".SFUIText" {
            ret = UIFont.systemFont(ofSize: size);
        }
        if ret == nil {
            if let name = name{
                ret = UIFont(name: name, size: size);
                if ret == nil {
                    let names = UIFont.fontNames(forFamilyName: name);
                    for n in names {
                        ret = UIFont(name: n, size: size);
                        if ret != nil {
                            break;
                        }
                    }
                }
            }
        }
        if ret == nil && notNil {
            ret = UIFont.systemFont(ofSize: size);
        }
        return ret;
    }

}
