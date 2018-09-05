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
import WebexSDK

/*
 -note: Buddies use Contact to wrap person model from remote server
 */
class Contact : NSObject, NSCoding {
    
    var id: String
    
    var name: String
    
    var email: String
    
    var avatorUrl: String?
    
    var isChoosed: Bool? = false
    
    var avator: UIImageView {
        let ret = UIImageView(frame: CGRect(0, 0, 28, 28))
        if let url = self.avatorUrl {
            ret.sd_setImage(with: URL(string: url), placeholderImage: self.placeholder)
        }
        else {
            ret.image = self.placeholder
        }
        ret.contentMode = UIViewContentMode.scaleAspectFill
        ret.clipsToBounds = true
        return ret
    }
    
    private(set) var placeholder: UIImage
    
    init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.placeholder = UIImage.getContactAvatorImage(name: name, size: 70)
        super.init()
    }
    
    convenience init?(person: Person) {
        guard let id = person.id, let name = person.displayName, let email = person.emails?.first?.toString() else {
            return nil
        }
        self.init(id: id, name: name, email: email)
        self.avatorUrl = person.avatar
    }
    
    
    // MARK: NSCoding Implementation
    public func encode(with aCoder: NSCoder){
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.email, forKey: "email")
        aCoder.encode(self.id, forKey: "contactId")
        if self.avatorUrl != nil{
            aCoder.encode(self.avatorUrl, forKey: "avatorUrl")
        }
    }
    
    public required init?(coder aDecoder: NSCoder){
        self.id = aDecoder.decodeObject(forKey: "contactId") as! String
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.email = aDecoder.decodeObject(forKey: "email") as! String
        self.avatorUrl = aDecoder.decodeObject(forKey: "avatorUrl") as? String
        self.isChoosed = false
        self.placeholder = UIImage.getContactAvatorImage(name: name, size: 70)
    }
}
