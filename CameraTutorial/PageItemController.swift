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
        self.addTriggerShelf()

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
        
        let imageView = UIImageView(frame: CGRectMake(0,0, image.size.width*ratio, image.size.height*ratio))
        imageView.image = image
        imageView.center = self.view.center
        imageView.clipsToBounds = true
        self.view.clipsToBounds = true
        self.view.addSubview(imageView)
    
    }
    
    func addTriggerShelf(){
        let triggerShelf = UIButton(frame: CGRect(x: 10, y: view.frame.height-54, width: 44, height: 44))
        triggerShelf.addTarget(self, action: Selector("toggleButtonVisibility:"), forControlEvents: UIControlEvents.TouchUpInside)
        triggerShelf.setImage(UIImage(named: "triggerShelf"), forState: .Normal)
        self.view.addSubview(triggerShelf)
    }
    
    func toggleButtonVisibility(sender: UIButton){
        let pageController = self.parentViewController? as UIPageViewController
        for button in pageController.view.subviews as [UIView] {
            if (button.isKindOfClass(MenuButton)){
                println("hiding!")
                button.hidden = !button.hidden
            }
            else {
                println("not hiding!")
            }
        }
    }
    


}
