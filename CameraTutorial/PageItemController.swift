//
//  PageItemController.swift
//  Paging_Swift
//
//  Created by Olga Dalton on 26/10/14.
//  Copyright (c) 2014 swiftiostutorials.com. All rights reserved.
//

import UIKit

class PageItemController: UIViewController {
    
    // MARK: - Variables
    var image: UIImage!
    var itemIndex: Int = 0
    var imageData: NSData = NSData() {
        didSet {
            
        }
    }
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addImageView()
       // contentImageView!.image = UIImage(named: imageName)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        let pageController = self.parentViewController?.parentViewController? as ViewController
        pageController.hideButtons(false)
    }
    
    func addImageView(){
        
        let imageView = UIImageView(frame: self.view.frame)
        image = UIImage(data: imageData)
        imageView.image = image
        self.view.addSubview(imageView)
    
    }
    

}
