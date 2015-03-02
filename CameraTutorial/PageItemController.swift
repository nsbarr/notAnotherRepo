//
//  PageItemController.swift
//  L8R
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
        super.viewWillAppear(true)
        let pvc = self.parentViewController?.parentViewController as ViewController
        pvc.cameraButtonsAreHidden(true)
        
    }
    
    
    func addImageView(){
        
        image = UIImage(data: imageData)
        
        let ratio = self.view.frame.height/image.size.height
        
        let imageView = UIImageView(frame: CGRectMake(0,0, image.size.width*ratio, image.size.height*ratio))
        imageView.image = image
        imageView.center = self.view.center
        imageView.clipsToBounds = true
        self.view.clipsToBounds = true
        self.view.addSubview(imageView)
    
    }
    



}
