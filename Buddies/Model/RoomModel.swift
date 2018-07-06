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
 -note: Buddies use RoomModel to wrap room model from remote server
 */

class RoomModel: NSObject,NSCoding {
    
    var roomId: String //roomId reprents remote roomId
    
    var localGroupId: String //GroupId contain witch Group involved in
    
    var title: String?

    var type: RoomType?  ///  "group" Group room among multiple people, "direct"  1-to-1 room between two people
    
    var isLocked: Bool? = false
    
    var teamId: String?
    
    var roomMembers: [Contact]?

    init(roomId : String) {
        self.roomId = roomId
        self.localGroupId = ""
    }
    
    init(groupModel: Group){
        self.roomId = ""
        self.localGroupId = groupModel.groupId!
        self.title = groupModel.groupName
        self.roomMembers = groupModel.groupMembers
    }
    
    convenience init?(room: Room) {
        guard let roomId = room.id else {
            return nil
        }
        self.init(roomId: roomId)
        if let title = room.title{
            self.title = title
        }
        if let type = room.type{
            self.type = type
        }
        if let isLocked = room.isLocked{
            self.isLocked = isLocked
        }
        if let teamId = room.teamId{
            self.teamId = teamId
        }
    }
    public func encode(with aCoder: NSCoder){
        aCoder.encode(self.roomId, forKey: "RoomId")
        aCoder.encode(self.localGroupId, forKey: "localGroupId")
        
        if self.type != nil{
            aCoder.encode(self.type?.rawValue, forKey: "type")
        }
        if self.title != nil{
            aCoder.encode(self.title, forKey: "title")
        }
        if self.isLocked != nil{
            aCoder.encode(self.isLocked, forKey: "isLocked")
        }
        if self.teamId != nil{
            aCoder.encode(self.teamId, forKey: "teamId")
        }
    }
    
    public required init?(coder aDecoder: NSCoder){
        self.roomId = aDecoder.decodeObject(forKey: "RoomId") as! String
        self.localGroupId = aDecoder.decodeObject(forKey: "localGroupId") as! String
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.type = RoomType(rawValue: (aDecoder.decodeObject(forKey: "type") as? String)!)
        self.isLocked = aDecoder.decodeObject(forKey: "isLocked") as? Bool
        self.teamId = aDecoder.decodeObject(forKey: "teamId") as? String
    }
    
}
