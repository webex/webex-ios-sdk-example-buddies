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
import Photos
class SelectedAssetCollectionCell: UICollectionViewCell {
    private let color1 = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.3)
    private let color2 = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.6)
    private let X : CGFloat = 2.5
    private let Y : CGFloat = 2.5
    private var width : CGFloat = 0
    private var height : CGFloat = 0
    private var choosed: Bool = false
    
    var imageView : UIImageView?
    var maskLayer : CAGradientLayer?
    var cancelImageView : UIImageView?
    var assetModel : BDAssetModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.width = self.frame.size.width
        self.height = self.frame.size.height
    }
    
    public func updateImageCell(_ asset: BDAssetModel){
        self.assetModel = asset
        if let imageView = self.imageView{
            imageView.removeFromSuperview()
            self.maskLayer?.removeFromSuperlayer()
        }
        self.imageView = UIImageView()
        self.imageView?.layer.masksToBounds = true
        self.imageView?.layer.cornerRadius = 12
        self.imageView?.frame = CGRect(self.X, self.Y, self.width-5, self.height-5)
        self.addSubview(self.imageView!)
        self.layer.masksToBounds = true
        if let image = self.assetModel?.image{
            self.imageView?.image = image
        }else{
            if let asset = self.assetModel?.asset{
                let manager = PHImageManager.default()
                manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil) { (result, info) in
                    self.imageView?.image = result
                }
            }
        }
        
        self.maskLayer = CAGradientLayer()
        self.maskLayer?.frame = CGRect(0, 0, self.width, self.height)
        self.maskLayer?.colors = [self.color1.cgColor,self.color2.cgColor]
        self.maskLayer?.locations = [0,1.0]
        self.maskLayer?.startPoint = CGPoint(0.5, 0);
        self.maskLayer?.endPoint = CGPoint(0.5, 1.0);
        self.imageView?.layer.addSublayer(self.maskLayer!)
        self.choosed = self.isSelected
        
        self.cancelImageView = UIImageView(frame: CGRect(width-25,5,20.0,20.0))
        self.cancelImageView?.image = UIImage(named:"icon_cancel")
        self.cancelImageView?.layer.cornerRadius = 10
        self.cancelImageView?.layer.borderWidth = 2.0
        self.cancelImageView?.layer.borderColor = UIColor.white.cgColor
        self.cancelImageView?.backgroundColor = UIColor.white
        self.addSubview(self.cancelImageView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
