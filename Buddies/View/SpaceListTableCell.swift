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

let spaceTableCellHeight = 80

class SpaceListTableCell: UITableViewCell {

    // MARK: - UI variabels
    var spaceModel: SpaceModel
    var backView: UIView?
    var callBtnClicked: (()->())?
    
    // MARK: - UI implementation
    init(spaceModel: SpaceModel){
        self.spaceModel = spaceModel
        super.init(style: .default, reuseIdentifier: "PeopleListTableCell")
        self.setUpSubViews()
    }
    
    func setUpSubViews(){
        if(self.backView != nil){
            self.backView?.removeFromSuperview()
        }
        let viewWidth = Constants.Size.screenWidth
        let viewHeight = spaceTableCellHeight
        self.backView = UIView(frame: CGRect(0, 0, Int(viewWidth),viewHeight))
        self.backView?.backgroundColor = Constants.Color.Theme.Background
        self.contentView.addSubview(self.backView!)
        let spaceTitle = spaceModel.title ?? "No Name Space"
        let spaceLogoImageView = UIImageView(frame: CGRect(x: 15, y: 15, width: Int(spaceTableCellHeight-30), height: Int(spaceTableCellHeight-30)))
        spaceLogoImageView.image = UIImage.getContactAvatorImage(name: spaceTitle, size: spaceTableCellHeight-30, fontName: "HelveticaNeue-UltraLight", backColor: UIColor.MKColor.BlueGrey.P600)
        spaceLogoImageView.layer.borderColor = UIColor.white.cgColor
        spaceLogoImageView.layer.cornerRadius = 25
        spaceLogoImageView.layer.masksToBounds = true
        spaceLogoImageView.layer.borderWidth = 2.0
        self.backView?.addSubview(spaceLogoImageView)
        
        let titleLabel = UILabel(frame: CGRect(x: 80, y: 10, width: Int(viewWidth-90), height: spaceTableCellHeight-20))
        titleLabel.text = spaceTitle
        titleLabel.textAlignment = .left
        titleLabel.textColor = Constants.Color.Theme.DarkControl
        titleLabel.font = Constants.Font.NavigationBar.BigTitle
        titleLabel.numberOfLines = 2
        self.backView?.addSubview(titleLabel)
        
        if spaceModel.unReadedCount > 0 {
            let unreadedCircle = CAShapeLayer()
            let path = UIBezierPath()
            path.addArc(withCenter: CGPoint.init(spaceTableCellHeight-22, 24), radius: 6.0, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
            unreadedCircle.path = path.cgPath
            unreadedCircle.fillColor = Constants.Color.Theme.Main.cgColor
            unreadedCircle.strokeColor = UIColor.white.cgColor
            unreadedCircle.lineWidth = 1.5
            self.backView?.layer.addSublayer(unreadedCircle)
        }

        let line = CALayer()
        line.frame = CGRect(x: 15.0, y: Double(spaceTableCellHeight)-1.0, width: Double(viewWidth-30.0), height: 0.5)
        line.backgroundColor = Constants.Color.Theme.MediumControl.cgColor
        self.backView?.layer.addSublayer(line)
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
