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
import Cartography
import SDWebImage

class ContactCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI variables
    var backView: UIView?
    var imageView: UIImageView?
    var nameLabel: UILabel?
    var onDeleteBlock: (()->())?
    var deleteBtn: UIButton?
    var contact: Contact?
    var seletionImageView : UIImageView?
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - UI Iplementation
    func updateContact(_ contact: Contact) {
        if let url = contact.avatorUrl {
            self.imageView?.sd_setImage(with: URL(string: url), placeholderImage: contact.placeholder)
        }
        else {
            self.imageView?.image = contact.placeholder
        }
        self.nameLabel?.text = contact.name
    }
    
    var onDelete: ((String?) -> Void)? {
        didSet {
            if self.onDelete == nil {
                self.deleteBtn?.isHidden = true
                self.deleteBtn?.isEnabled = false
            }
            else {
                self.deleteBtn?.isHidden = false
                self.deleteBtn?.isEnabled = true
            }
        }
    }
    
    func updateUIElements(cellWidth: Int , showDeleteBtn: Bool, contact: Contact?, onDelete: (()->())?){
        var imageViewWidth = Double(cellWidth)/3 * 2.0
        if(imageViewWidth > 70){
            imageViewWidth = 70
        }
        let labelViewHeight =  Double(cellWidth) - imageViewWidth
        if(self.backView == nil){
            self.backView = UIView(frame: CGRect(x: 0, y: 0, width: cellWidth, height: cellWidth))
            self.addSubview(self.backView!)
        }
        if(self.imageView == nil){
            
            self.imageView = UIImageView()
            self.imageView?.frame = CGRect(x: labelViewHeight/2, y: 0.0, width: imageViewWidth, height: imageViewWidth)

            self.imageView?.layer.cornerRadius = CGFloat(Double(imageViewWidth/2))
            self.imageView?.layer.masksToBounds = true
            self.imageView?.setShadow(color: UIColor.gray, radius: 1.0, opacity: 0.5, offsetX: 0, offsetY: 0)
            self.backView?.addSubview(self.imageView!)
        }
        if(self.nameLabel == nil){
            self.nameLabel = UILabel(frame: CGRect(x: 0.0, y:imageViewWidth, width: Double(cellWidth), height:20))
            self.nameLabel?.font = Constants.Font.Home.Comment
            self.nameLabel?.textAlignment = .center
            self.nameLabel?.textColor = Constants.Color.Theme.DarkControl
            self.nameLabel?.numberOfLines = 1;
            self.nameLabel?.lineBreakMode = .byTruncatingTail;
            self.backView?.addSubview(self.nameLabel!)
        }
        
        if(self.deleteBtn == nil && showDeleteBtn){
            let deleteBtnHeight = 30.0
            self.deleteBtn = UIButton(frame: CGRect(x: Double(cellWidth) - deleteBtnHeight, y: -5, width: deleteBtnHeight, height: deleteBtnHeight))
            self.deleteBtn?.titleLabel?.font = UIFont.fontAwesome(ofSize: 20)
            self.deleteBtn?.setTitle(String.fontAwesomeIcon(name: .timesCircle), for: .normal)
            self.deleteBtn?.setTitleColor(Constants.Color.Theme.Warning, for: .normal)
            self.deleteBtn?.addTarget(self, action:#selector(deleteBtnClicked), for: .touchUpInside)
            self.backView?.addSubview(self.deleteBtn!)
        }
        
        self.contact = contact
        if(self.contact != nil){
            if let url = self.contact?.avatorUrl {
                self.imageView?.sd_setImage(with: URL(string: url), placeholderImage: self.contact?.placeholder)
            }
            else {
                self.imageView?.image = self.contact?.placeholder
            }
            self.nameLabel?.text = self.contact?.name
        }
        if(onDelete == nil){
            self.updateSelection()
        }else{
            self.onDeleteBlock = onDelete
        }
    }
    
    func updateSelection(){
        if(self.contact?.isChoosed)!{
            if(self.seletionImageView == nil){
                self.seletionImageView = UIImageView(frame: CGRect(x:(self.imageView?.frame.origin.x)! + (self.imageView?.frame.size.width)! - 15, y: (self.imageView?.frame.origin.y)!, width: 30, height: 30))
                self.seletionImageView?.image = UIImage(named: "icon_choosed_people")
            }
            self.backView?.addSubview(self.seletionImageView!)
        }else{
            self.seletionImageView?.removeFromSuperview()
        }
    }
    
    @objc func deleteBtnClicked(){
        if(self.onDeleteBlock != nil){
            self.onDeleteBlock!()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
