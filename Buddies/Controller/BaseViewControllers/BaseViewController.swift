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

class BaseViewController: UIViewController {

    // MARK: UI variables
    var mainController: MainViewController?
    
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
    func updateViewController(){
        
    }
    
    // MARK: other functions
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
