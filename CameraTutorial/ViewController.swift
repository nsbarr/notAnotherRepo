//
//  ViewController.swift
//  CameraTutorial
//
//  Created by Jameson Quave on 9/20/14.
//  Copyright (c) 2014 JQ Software. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UIPageViewControllerDataSource {
    
    var pageViewController: UIPageViewController?
    
    var l8rs = [NSManagedObject]()
    var inboxButton: UIButton!
    var inboxNumber: UILabel!
    
    //MARK: - Lifecycle
    
    //1 fetch l8rs from core data
    //2 create pageController
    //3 set up first itemController, which is the Camera
    //misc. generate itemControllers on the fly for l8rs in inbox
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchL8rs()
        self.createPageViewController()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    func fetchL8rs(){
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "L8R")
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
        
        if let results = fetchedResults {
            l8rs = results
            println("Number of l8rs:\(l8rs.count)")
            
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    func createInboxBadge(){


    }

    func createPageViewController() {
        
        //create PageViewController
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier("PageController") as UIPageViewController
        pageController.dataSource = self
        
        //create cameraController and set as first page
        let cameraController = self.storyboard!.instantiateViewControllerWithIdentifier("CameraController") as CameraController
        let startingViewControllers: NSArray = [cameraController]
        pageController.setViewControllers(startingViewControllers, direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        

        pageViewController = pageController
        addChildViewController(pageViewController!)
        
        inboxButton = UIButton(frame: CGRectMake(self.view.frame.width - 60, 60, 40, 40))
        inboxButton.addTarget(self, action: Selector("openInbox:"), forControlEvents:UIControlEvents.TouchUpInside)
        let inboxButtonImage = UIImage(named: "inboxButton")
        inboxButton.setImage(inboxButtonImage, forState: .Normal)
        pageViewController!.view.addSubview(inboxButton)
        
        
        //stupid. don't initialize in header, and shows 0 because this happens before viewwillappear
        inboxNumber = UILabel(frame: inboxButton.frame)
        inboxNumber.center.x = inboxButton.center.x + 15
        inboxNumber.font = UIFont(name: "Arial", size: 18)
        inboxNumber.textColor = UIColor.whiteColor()
        inboxNumber.text = String(l8rs.count)
        pageViewController!.view.addSubview(inboxNumber)
        
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        
        
        if viewController.restorationIdentifier == "CameraController" {
            println("nothing before camera")
            return nil // Camera is always first
        }
        
        else { // we got a PageItemController
            var itemController = viewController as PageItemController
            println(itemController.itemIndex)
            if itemController.itemIndex == 1 { //If we got the first ItemController, then go back to Camera
                println("this is the top of the item stack, going back to cam")
                let cameraController = self.storyboard!.instantiateViewControllerWithIdentifier("CameraController") as CameraController
                return cameraController
            }
            else {
                println("showing previous item")
                return getItemController(itemController.itemIndex-1) //Otherwise go back to previous ItemController
            }
        
            
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        println("VC is of Type:\(viewController.restorationIdentifier)")
        
        
        if viewController.restorationIdentifier == "CameraController" {
            println("going from cam to top of item stack")
            return getItemController(1) // top of Inbox
        }
        
        else {
            var itemController = viewController as PageItemController
            println("trying to leave item controller with index\(itemController.itemIndex)")

            if itemController.itemIndex+1 < l8rs.count {
                return getItemController(itemController.itemIndex+1)
            }
            println("bottom of the stack")
            return nil
        }
        
    }
    
    private func getItemController(itemIndex: Int) -> PageItemController? {
        
        if itemIndex < l8rs.count {
            let pageItemController = self.storyboard!.instantiateViewControllerWithIdentifier("ItemController") as PageItemController
            pageItemController.itemIndex = itemIndex
       //     pageItemController.imageName = contentImages[itemIndex]
            return pageItemController
        }
        
        return nil
    }
    


}

