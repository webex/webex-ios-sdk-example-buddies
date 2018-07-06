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

import Foundation
import UIKit
func ~=(lhs: String, rhs: String) -> Bool {
    return lhs.caseInsensitiveCompare(rhs) == ComparisonResult.orderedSame
}

extension String {
    
    static func stringFrom(timeInterval: TimeInterval) -> String {
        let interval = Swift.abs(Int(timeInterval))
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    func base64Decoded() -> String? {
        var encoded64 = self
        let remainder = encoded64.count % 4
        if remainder > 0 {
            encoded64 = encoded64.padding(toLength: encoded64.count + 4 - remainder, withPad: "=", startingAt: 0)
        }
        if let data = Data(base64Encoded: encoded64) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    var length: Int {
        return self.count;
    }
    
    subscript (i: Int) -> Character? {
        if (i >= self.length) {
            return nil;
        }
        return self[self.index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String? {
        if let c = self[i] as Character? {
            return String(c);
        }
        return nil;
    }
    
    subscript (range: Range<Int>) -> String? {
        if range.lowerBound < 0 || range.upperBound > self.length {
            return nil
        }
        let range = self.index(startIndex, offsetBy: range.lowerBound) ..< self.index(startIndex, offsetBy: range.upperBound)
        return String(self[range]);
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    var md5: String! {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deallocate(capacity: digestLen)
        
        return String(format: hash as String)
    }
        
    func calculateSringHeight(width: Double, font : UIFont)->CGFloat{
        let textAttributes = [NSAttributedStringKey.font: font]
        let textRect = self.boundingRect(with: CGSize(Int(width), 3000), options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        return textRect.height
    }
    
    
    func calculateSringSize(width: Double, font : UIFont)->CGSize{
        let textAttributes = [NSAttributedStringKey.font: font]
        var textRect = self.boundingRect(with: CGSize(Int(width), 3000), options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        if(textRect.size.width < 30){
            textRect.size.width = 30
        }
        return textRect.size
    }
    
    func getLineTrimedString() ->String{
        var linesArray: [String] = []
        self.enumerateLines { line, _ in linesArray.append(line) }
        let result = linesArray.filter{!$0.isEmpty}.joined(separator: "\n")
        return result
    }
    
    func getEmptyLineCount() -> Int{
        var linesArray: [String] = []
        self.enumerateLines { line, _ in linesArray.append(line) }
        let result = linesArray.filter{$0.isEmpty}.count
        return result
    }
 }

