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
import WebexSDK

/*
 -note: Buddies use SpaceModel to wrap space model from remote server
 */

class SpaceModel: NSObject,NSCoding {
    
    var spaceId: String //spaceId reprents remote spaceId
    
    var localSpaceId: String //SpaceId contain witch Space involved in
    
    var title: String?

    var type: SpaceType?  ///  "space" Space space among multiple people, "direct"  1-to-1 space between two people
    
    var isLocked: Bool? = false
    
    var teamId: String?
    
    var spaceMembers = [Contact]()
    
    var contact: Contact?
    
    var unReadedCount: Int = 0
    
    init(contact: Contact){
        self.spaceId = ""
        self.localSpaceId = contact.email
        self.title = contact.name
        self.contact = contact
        self.type = SpaceType.direct
    }
    
    init(space: Space) {
        
        if let spaceId = space.id {
            self.spaceId = spaceId
            self.localSpaceId = spaceId
        }else {
            self.spaceId = ""
            self.localSpaceId = ""
        }
        
        if let title = space.title{
            self.title = title
        }
        if let type = space.type{
            self.type = type
        }
        if let isLocked = space.isLocked{
            self.isLocked = isLocked
        }
        if let teamId = space.teamId{
            self.teamId = teamId
        }
        
        super.init()
    }
    public func encode(with aCoder: NSCoder){
        aCoder.encode(self.spaceId, forKey: "SpaceId")
        aCoder.encode(self.localSpaceId, forKey: "localSpaceId")
        aCoder.encode(self.unReadedCount, forKey:"unReadedCount")
        
        if let type = self.type {
            aCoder.encode(type.rawValue, forKey: "type")
        }
        if let title = self.title {
            aCoder.encode(title, forKey: "title")
        }
        if let isLocked = self.isLocked{
            aCoder.encode(isLocked, forKey: "isLocked")
        }
        if let teamId = self.teamId{
            aCoder.encode(teamId, forKey: "teamId")
        }
        if let contact = self.contact{
            aCoder.encode(contact, forKey: "contact")
        }
        
    }
    
    public required init?(coder aDecoder: NSCoder){
        self.spaceId = aDecoder.decodeObject(forKey: "SpaceId") as! String
        self.localSpaceId = aDecoder.decodeObject(forKey: "localSpaceId") as! String
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.type = SpaceType(rawValue: (aDecoder.decodeObject(forKey: "type") as? String)!)
        self.isLocked = aDecoder.decodeObject(forKey: "isLocked") as? Bool
        self.teamId = aDecoder.decodeObject(forKey: "teamId") as? String
        self.contact = aDecoder.decodeObject(forKey: "contact") as? Contact
        self.unReadedCount = aDecoder.decodeObject(forKey: "unReadedCount") as? Int ?? 0
    }
    
}
