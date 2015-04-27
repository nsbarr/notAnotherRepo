//
//  ModalViewController.swift
//  CameraTutorial
//
//  Created by nick barr on 4/22/15.
//  Copyright (c) 2015 JQ Software. All rights reserved.
//

import Foundation
import UIKit
import AssetsLibrary

class ModalViewController: UIViewController{
    
    var viewToShow: String = "nil"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        view.frame = self.presentingViewController!.view.frame
        self.showViewWithTitle(viewToShow)
    }
    
    func showViewWithTitle(subview:String){
        if subview == "calendar"{
            println("cal")
            let datePicker = UIDatePicker(frame: self.view.frame)
            datePicker.center.y = self.view.center.y
            self.view.addSubview(datePicker)
            
            let confirmButton = UIButton(frame: CGRectMake(0, 200, 116, 42))
            confirmButton.center.x = self.view.center.x
            confirmButton.setImage(UIImage(named: "pickDateButton"), forState: .Normal)
            confirmButton.tag = 777
            confirmButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: .TouchUpInside)
            self.view.addSubview(confirmButton)
        }
        else if subview == "snooze"{
        
        }
        else if subview == "album"{
            let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as AlbumViewController
            //    avc.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
            //avc.image = nil
            
            
            
            
            
            
            avc.modalPresentationStyle = .OverCurrentContext
            self.presentViewController(avc, animated: true, completion: nil)
        
        }
        else {
            println("fail")
        }
        
    }


}