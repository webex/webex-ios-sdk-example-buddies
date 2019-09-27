//
//  UIViewController+Ext.swift
//  Buddies
//
//  Created by yonshi on 2019/9/4.
//  Copyright © 2019 spark-ios-sdk. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func presentFullScreen(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        viewControllerToPresent.modalPresentationStyle = .fullScreen
        self.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
}
