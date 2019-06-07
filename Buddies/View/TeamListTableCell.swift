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

let teamTableCellHeight = 120

class TeamListTableCell: UITableViewCell {

    // MARK: - UI variables
    var teamModel: Team?
    var backView: UIView?
    
    // MARK: - UI Implementation
    init(teamModel: Team){
        super.init(style: .default, reuseIdentifier: "PeopleListTableCell")
        self.teamModel = teamModel
        self.setUpSubViews()
    }
    
    func setUpSubViews(){
        if(self.backView != nil){
            self.backView?.removeFromSuperview()
        }
        let viewWidth = Constants.Size.screenWidth
        let viewHeight = teamTableCellHeight
        self.backView = UIView(frame: CGRect(0, 0, Int(viewWidth),viewHeight))
        self.backView?.backgroundColor = Constants.Color.Theme.Background
        self.addSubview(self.backView!)
        
        let shapeLayer = CALayer()
        shapeLayer.frame = CGRect(x: 10, y: 5, width: Int(viewWidth-20), height: viewHeight-10)
        shapeLayer.backgroundColor = Constants.Color.Theme.LightBackground.cgColor
        self.backView?.layer.addSublayer(shapeLayer)
        
        
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 10, width: viewWidth-30, height: 50))
        titleLabel.text = teamModel?.name
        titleLabel.textAlignment = .center
        titleLabel.textColor = Constants.Color.Theme.DarkControl
        titleLabel.font = Constants.Font.NavigationBar.Title
        self.backView?.addSubview(titleLabel)
        
        if let createTime = teamModel?.created{
            let createdLabel = UILabel(frame: CGRect(x: 15, y: viewHeight-30, width: Int(viewWidth-50), height: 20))
            createdLabel.text = String(describing: createTime)
            createdLabel.textAlignment = .right
            createdLabel.textColor = Constants.Color.Theme.MediumControl
            createdLabel.font = Constants.Font.Home.Comment
            self.backView?.addSubview(createdLabel)
        }
        
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
