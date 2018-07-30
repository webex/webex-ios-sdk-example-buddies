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

let spaceTableCellHeight = 80

class SpaceListTableCell: UITableViewCell {

    // MARK: - UI variabels
    var spaceModel: SpaceModel
    var backView: UIView?
    var unreadedLabel: UILabel?
    
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
        
        let titleLabel = UILabel(frame: CGRect(x: 15, y: 10, width: viewWidth-30, height: 50))
        if let spacetitle = spaceModel.title{
            titleLabel.text = spacetitle
        }else{
            titleLabel.text = "No Name"
        }
        titleLabel.textAlignment = .center
        titleLabel.textColor = Constants.Color.Theme.DarkControl
        titleLabel.font = Constants.Font.NavigationBar.Title
        titleLabel.numberOfLines = 2
        self.backView?.addSubview(titleLabel)
        
        let lastActLabel = UILabel(frame: CGRect(x: 15, y: viewHeight-20, width: Int(viewWidth-40), height: 20))
        lastActLabel.textAlignment = .right
        lastActLabel.textColor = Constants.Color.Theme.MediumControl
        lastActLabel.font = Constants.Font.Home.Comment
        self.backView?.addSubview(lastActLabel)
        
        let line = CALayer()
        line.frame = CGRect(x: 15.0, y: Double(spaceTableCellHeight)-1.0, width: Double(viewWidth-30.0), height: 0.5)
        line.backgroundColor = Constants.Color.Theme.MediumControl.cgColor
        self.backView?.layer.addSublayer(line)
        
        if let spaceGroup = User.CurrentUser[(self.spaceModel.localGroupId)]{
            if(spaceGroup.unReadedCount > 0){
                self.unreadedLabel = UILabel(frame: CGRect(Int(viewWidth - 50),viewHeight/2-10,20,20))
                self.unreadedLabel?.backgroundColor = UIColor.red
                self.unreadedLabel?.font = Constants.Font.InputBox.Options
                self.unreadedLabel?.textColor = UIColor.white
                self.unreadedLabel?.layer.cornerRadius = 10
                self.unreadedLabel?.layer.masksToBounds = true
                self.unreadedLabel?.textAlignment = .center
                self.unreadedLabel?.text = String(describing: (spaceGroup.unReadedCount))
                self.backView?.addSubview(self.unreadedLabel!)
            }
        }else{
            self.unreadedLabel?.removeFromSuperview()
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
