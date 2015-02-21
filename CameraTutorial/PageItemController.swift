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
        
        image = UIImage(data: imageData)
        
        let ratio = self.view.frame.height/image.size.height
        println(ratio)
        
        let imageView = UIImageView(frame: CGRectMake(0,0, image.size.width*ratio, image.size.height*ratio))
        imageView.image = image
        imageView.center = self.view.center
        imageView.clipsToBounds = true
        self.view.clipsToBounds = true
        self.view.addSubview(imageView)
    
    }
    

}
