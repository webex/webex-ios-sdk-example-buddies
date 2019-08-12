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

extension NSAttributedString {
    
    
    static func convertAttributeStringToPretty(attributedString: NSAttributedString)->NSAttributedString?{
        if attributedString.length == 0{
            return NSAttributedString(string:"")
        }
        let attributeBody : NSMutableAttributedString = attributedString.mutableCopy() as! NSMutableAttributedString
        let fullRannge = NSMakeRange(0, attributeBody.length)
        
        let boldFont = UIFont(name: "AvenirNext-Medium", size: 14)
        let linkFont = UIFont(name: "AvenirNext-Italic", size: 14)
        let mentionFont = UIFont(name: "AvenirNext-DemiBold", size: 14)
        let lightFont = UIFont(name: "AvenirNext-Medium", size: 14)

        let personMentionColor = Constants.Color.Message.PersonMention
        let spaceMentionColor = Constants.Color.Message.SpaceMention
        let contentColor = Constants.Color.Message.Text
        
        let fontSize = boldFont?.pointSize
        let fontName = boldFont?.fontName
        
        let fontDescriptor = UIFontDescriptor(name: fontName!, size: fontSize!)
        let atttiDict = [NSAttributedString.Key.font : lightFont!,
                         NSAttributedString.Key.foregroundColor :contentColor] as [NSAttributedString.Key : Any]

        let activeLinkAttributes = [NSAttributedString.Key.font : mentionFont!,
                                    NSAttributedString.Key.foregroundColor :personMentionColor] as [NSAttributedString.Key : Any]
        
        let mentionAllAttributes = [NSAttributedString.Key.font : mentionFont!,
                                    NSAttributedString.Key.foregroundColor :spaceMentionColor] as [NSAttributedString.Key : Any]
        

        let linkAttritutes = [NSAttributedString.Key.font  : linkFont!,
                              NSAttributedString.Key.foregroundColor :personMentionColor,
                              NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        
        attributeBody.beginEditing()
        attributeBody.addAttributes(atttiDict, range: fullRannge)
        
        attributeBody.enumerateAttributes(in: fullRannge, options: .longestEffectiveRangeNotRequired) { (attrs, range, YES) in
            let keyStr = NSAttributedString.Key.init(kMessageParserStyleKey)
            if let htmlTraitRaw = attrs[keyStr]{
                let htmlTraits =  htmlTraitRaw as! UInt
                var updatedFontSize = fontSize
                var updatedFontName = fontName
                // Update font
                if ((htmlTraits == UInt(FontTrait.code.rawValue)) || (htmlTraits == UInt(FontTrait.preformat.rawValue))){
                    updatedFontName = "Menlo-Regular"
                    updatedFontSize = fontSize!
//                    updatedFontSize = fontSize! * 0.875
                }
                if ((htmlTraits & UInt(FontTrait.headingOne.rawValue))>0) {
                    updatedFontSize = fontSize!
//                    updatedFontSize = fontSize! * 2.00
                } else if (htmlTraits & UInt(FontTrait.headingTwo.rawValue)>0) {
                    updatedFontSize = fontSize!
//                    updatedFontSize = fontSize! * 1.50
                } else if (htmlTraits & UInt(FontTrait.headingThree.rawValue)>0) {
                    updatedFontSize = fontSize!
//                    updatedFontSize = fontSize! * 1.25
                }
                let font = UIFont(name: updatedFontName!, size: updatedFontSize!)
                let updatedFontDescriptor = fontDescriptor.addingAttributes([kCTForegroundColorAttributeName as UIFontDescriptor.AttributeName : font!])
                var symbolicTraits = updatedFontDescriptor.symbolicTraits.rawValue
                
                // Apply symbolicTraits to font
                if (htmlTraits & UInt(FontTrait.italic.rawValue) > 0) {
                    symbolicTraits |= UInt32(FontTrait.bold.rawValue)
                }
                if (htmlTraits & UInt(FontTrait.bold.rawValue) > 0) {
                    symbolicTraits |= UInt32(FontTrait.italic.rawValue);
                }
                if (symbolicTraits != fontDescriptor.symbolicTraits.rawValue || updatedFontSize != fontSize || updatedFontName !=  fontName) {
                    let finalFontDescriptor = updatedFontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(rawValue: symbolicTraits))
                    let font = UIFont(descriptor: finalFontDescriptor!, size: updatedFontSize!)
                    attributeBody.addAttribute(NSAttributedString.Key.font , value: font, range: range)
                }
            }
            
            let attrStr = NSAttributedString.Key.init(kMessageParserBlockPaddingKey)
            if let _ = attrs[attrStr] {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineHeightMultiple = 0.1
                if let indentLevel = attrs[attrStr]{
                    if let indetL = indentLevel as? UInt{
                        paragraph.firstLineHeadIndent = fontSize! * CGFloat(indetL)
                        paragraph.headIndent = fontSize! * CGFloat(indetL)
                    }
                }
                attributeBody.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: range)
            }
            
            let attrStr1 = NSAttributedString.Key.init(kConversationMessageMentionTagName)
            if let value = attrs[attrStr1]{
                let valueDict = value as! Dictionary<String, String>
                if (valueDict[kConversationMessageMentionTypeKey] == kConversationMessageMentionTypePersonValue) {
                    attributeBody.addAttributes(activeLinkAttributes, range: range)
                }
                else if (valueDict[kConversationMessageMentionTypeKey] == kConversationMessageMentionTypeSpaceMentionValue){
                    attributeBody.addAttributes(mentionAllAttributes, range: range)
                }
            }
            
            let attrStr2 = NSAttributedString.Key.init(kMessageParserLinkKey)
            if let _ = attrs[attrStr2]{
                attributeBody.addAttributes(linkAttritutes, range: range)
            }
        }
        attributeBody.endEditing()
        return attributeBody
    }
}
