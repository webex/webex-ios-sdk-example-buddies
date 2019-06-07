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

class BaseViewController: UIViewController {
    
    // MARK: UI variables
    var mainController: MainViewController?
    var avator: UIImageView?
    let acitivtyIndicator = KTActivityIndicator()

    // MARK: Life Circle
    init(){
       super.init(nibName: nil, bundle: nil)
    }
    init(mainViewController: MainViewController){
        super.init(nibName: nil, bundle: nil)
        self.mainController = mainViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate();
        self.view.backgroundColor = Constants.Color.Theme.Background
        self.automaticallyAdjustsScrollViewInsets = false;
        self.edgesForExtendedLayout = [.bottom, .left, .right];
        self.navigationController?.navigationBar.updateAppearance();
        let backImage = UIImage(named: "icon_back")
        self.navigationController?.navigationBar.backIndicatorImage = backImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
    }
    
    // updateViewController need to overrided by sub view controller
    func updateViewController(){}
    
    // MARK: other functions
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class HomeViewController: BaseViewController {
    
    func updateNavigationItems() {
        if(User.CurrentUser.loginType == .User){
            avator = User.CurrentUser.avator
            if let avator = avator {
                avator.setCorner(Int(avator.frame.height / 2))
            }
        }else {
            avator = UIImageView(frame: CGRect(0, 0, 28, 28))
            avator?.image = UIImage.fontAwesomeIcon(name: .userCircleO, textColor: UIColor.white, size: CGSize(width: 28, height: 28))
            self.navigationItem.rightBarButtonItem = nil
        }
        if let avator = avator {
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(showUserOptionView))
            singleTap.numberOfTapsRequired = 1;
            avator.isUserInteractionEnabled = true
            avator.addGestureRecognizer(singleTap)
            let widthConstraint = avator.widthAnchor.constraint(equalToConstant: 28)
            let heightConstraint = avator.heightAnchor.constraint(equalToConstant: 28)
            widthConstraint.isActive = true
            heightConstraint.isActive = true
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avator)
        }
    }
    
    @objc private func showUserOptionView() {
        self.mainController?.slideInUserOptionView()
    }
}

