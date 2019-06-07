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
import Cartography
import Photos

/*
 -note: Buddies use MessageModel to wrap message model from remote server
 */
enum MessageState : Int{
    case idle
    case sending
    case received
    case willSend
    case sendFailed
}

class BDSMessage: NSObject {

    public var messageId: String?
    
    public var personId: String?
    
    public var personEmail: EmailAddress?
    
    public var spaceId: String?
    
    public var text: String?
    
    public var localFiles: [LocalFile]?
    
    public var remoteFiles: [BDSRemoteFile]?
    
    public var fileNames: [String]?
    
    public var toPersonId: String?
    
    public var toPersonEmail: EmailAddress?
    
    public var created: Date?
    
    public var messageState: MessageState?
    
    public var localSpaceId: String? //SpaceId contain witch Space it is involved in
    
    public var mentionList: [Mention]?
    
    public var imageDataDict: Dictionary<String, Data>?
    
    public var avator: String?
    
    convenience init?(messageModel: Message) {
        self.init()
        if let spaceId = messageModel.spaceId{
            self.spaceId = spaceId
        }
        if let messageId = messageModel.id{
            self.messageId = messageId
        }
        if let personId = messageModel.personId{
            self.personId = personId
        }
        if let personEmail = messageModel.personEmail{
            self.personEmail = EmailAddress.fromString(personEmail)
        }
        if let text = messageModel.text{
            self.text = text
        }
        if let messageId = messageModel.id{
            self.messageId = messageId
        }
        if let files = messageModel.files{
            self.remoteFiles = [BDSRemoteFile]()
            self.fileNames = []
            for file in files{
                if let fileName = file.displayName{
                    self.fileNames?.append(fileName)
                }else{
                    self.fileNames?.append("Unkwon")
                }
                let tempFile = BDSRemoteFile(remoteFile: file)
                self.remoteFiles?.append(tempFile)
            }
        }
        if let toPersonId = messageModel.toPersonId{
            self.toPersonId = toPersonId
        }
        if let toPersonEmail = messageModel.toPersonEmail{
            self.toPersonEmail = toPersonEmail
        }
        if let created = messageModel.created{
            self.created = created
        }
        self.messageState = MessageState.received
    }
}

class BDSRemoteFile: NSObject{
    public var displayName: String?{
        get {
            return self.remoteFile.displayName
        }
    }
    public var mimeType: String?{
        get {
            return self.remoteFile.mimeType
        }
    }
    public var size: UInt64?{
        get {
            return self.remoteFile.size
        }
    }
    public  var thumbnail: RemoteFile.Thumbnail?{
        get {
            return self.remoteFile.thumbnail
        }
    }
    public var remoteFile : RemoteFile
    public var localUrl: String?
    init(remoteFile: RemoteFile){
        self.remoteFile = remoteFile
    }
}
