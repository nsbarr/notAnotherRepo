//
//  MenuButton.swift
//  L8R
//


import Foundation
import UIKit

class MenuButton: UIButton {
    override init(frame: CGRect)  {
        super.init(frame: frame)
        
        self.titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 24.0)
        self.titleLabel!.textAlignment = .Center
        self.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        self.titleLabel!.sizeToFit()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSizeMake(0, 1)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 1
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}