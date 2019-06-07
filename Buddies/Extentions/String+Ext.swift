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

import Foundation
import UIKit
import WebexSDK

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
    
    // MARK: - Markup string
    static func processMentionString(contentStr: String?, mentions: [Mention], mentionsArr: [Range<Int>])-> String{
        var result: String = ""
        if let contentStr = contentStr{
            var markedUpContent = contentStr
            var mentionStringLength = 0
            for index in 0..<mentionsArr.count{
                let mention = mentions[index]
                let mentionItem = mentionsArr[index]
                let startPosition = (mentionItem.lowerBound) + mentionStringLength
                let endPostion = (mentionItem.upperBound) + mentionStringLength
                if markedUpContent.length < startPosition || markedUpContent.length < markedUpContent.startIndex.hashValue + endPostion{
                    continue
                }
                let startIndex = markedUpContent.index(markedUpContent.startIndex, offsetBy: startPosition)
                let endIndex = markedUpContent.index(markedUpContent.startIndex, offsetBy: endPostion)
                let mentionContent = markedUpContent[startPosition..<endPostion]
                switch mention{
                case .all:
                    let markupStr = markUpString(mentionContent: mentionContent, spaceType: "all", mentionType: "groupMention")
                    markedUpContent = markedUpContent.replacingCharacters(in: startIndex..<endIndex, with: markupStr)
                    mentionStringLength += (markupStr.count - (mentionContent?.count)!)
                    break
                case .person(let personId):
                    let markupStr = markUpString(mentionContent: mentionContent, mentionId: personId, mentionType: "person")
                    markedUpContent = markedUpContent.replacingCharacters(in: startIndex..<endIndex, with: markupStr)
                    mentionStringLength += (markupStr.count - (mentionContent?.count)!)
                    break
                }
            }
            result = markedUpContent
        }
        return result
    }
    
    static func markUpString(mentionContent: String?, mentionId: String? = nil, spaceType: String?=nil, mentionType: String)->String{
        var result = "<spark-mention"
        if let mentionid = mentionId{
            result = result + " data-object-id=" + mentionid
        }
        if let spacetype = spaceType{
            result = result + " data-group-type=" + spacetype
        }
        
        result = result + " data-object-type=" + mentionType
        result = result + ">"
        if let content = mentionContent{
            result = result + content
        }
        result = result + "</spark-mention>"
        return result
    }
 }

