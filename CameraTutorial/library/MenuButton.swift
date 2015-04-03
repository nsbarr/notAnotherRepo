//
//  MenuButton.swift
//  L8R
//


import Foundation
import UIKit

class MenuButton: UIButton {
    override init(frame: CGRect)  {
        super.init(frame: frame)
        
        self.titleLabel!.font = UIFont(name: "Arial-BoldMT", size: 24.0)
        self.titleLabel!.textAlignment = .Center
        self.titleLabel?.numberOfLines = 0
        self.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        self.titleLabel!.sizeToFit()
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.layer.borderColor = UIColor.whiteColor().CGColor
        self.layer.borderWidth = 2
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSizeMake(0, 1)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 1
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}