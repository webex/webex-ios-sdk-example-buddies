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

class AppearanceSetter {
    
    class func setup() {
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.font: Constants.Font.NavigationBar.Title
        ]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: Constants.Font.NavigationBar.Title], for: .normal);
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: Constants.Font.NavigationBar.Button], for: .highlighted);
    }
    
}

extension UINavigationBar {
    
    func updateAppearance() {
        self.barStyle = .black;
        self.barTintColor = Constants.Color.Theme.Main;
        self.tintColor = UIColor.white;
        self.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white, NSAttributedStringKey.font:Constants.Font.NavigationBar.Title];
        self.setTitleVerticalPositionAdjustment(-2, for: .default)
        self.isTranslucent = false
    }
    
}

extension UITableView {
    
    func updateAppearance() {
        self.autoresizingMask = [];
        self.separatorStyle = .none;
        self.sectionHeaderHeight = 0;
        self.sectionFooterHeight = 0;
        self.rowHeight = 40;
    }
    
    func createSectionView(title:String) -> UILabel {
        let sectionHeader = UILabel(frame: CGRect.zero);
        sectionHeader.backgroundColor = UIColor.clear;
        sectionHeader.font = Constants.Font.Table.SectionTitle;
        sectionHeader.textColor = Constants.Color.Table.SectionTitle;
        sectionHeader.text = "   " + title;
        return sectionHeader;
    }
    
}

extension UITableViewCell {
    
    func updateAppearance() {
        self.selectionStyle = .gray;
        self.accessoryType = .none;
        self.detailTextLabel?.text = nil;
        self.detailTextLabel?.textColor = Constants.Color.Table.ItemDetailTitle;
        self.detailTextLabel?.font = Constants.Font.Table.ItemDetailTitle;
        self.detailTextLabel?.numberOfLines = 1;
        self.detailTextLabel?.lineBreakMode = .byTruncatingHead;
        self.textLabel?.text = nil;
        self.textLabel?.textColor = Constants.Color.Table.ItemTitle;
        self.textLabel?.font = Constants.Font.Table.ItemTitle;
        self.textLabel?.numberOfLines = 1;
        self.textLabel?.lineBreakMode = .byTruncatingTail;
        self.alpha = 1.0;
        self.isUserInteractionEnabled = true;
        self.contentView.alpha = 1.0;
        self.accessoryView = nil;
        self.imageView?.image = nil;
        self.contentView.subviews.forEach() { view in
            view.removeFromSuperview();
        }
    }
    
}

