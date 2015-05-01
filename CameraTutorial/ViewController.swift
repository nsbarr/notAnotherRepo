//
//  ViewController.swift
//  L8R
//

import UIKit
import CoreData
import Foundation

class ViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UITextViewDelegate {
    
    //MARK: - Variables 
    
    var pageViewController: UIPageViewController?
    var cameraController: CameraController!
    
    var l8rsBeforeCurrentDate = [NSManagedObject]()
    var indexOfCurrentPage: Int!
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
        
    var inboxNumber: UILabel!
    
    var scheduleButton: UIButton!
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNotificationSettings()
        self.setUpCoreData()
        self.fetchL8rs()
        self.createPageViewController()
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleViewNotification", name: "viewNotification", object: nil)
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    
    
    func setupNotificationSettings() {
        
        let notificationSettings: UIUserNotificationSettings! = UIApplication.sharedApplication().currentUserNotificationSettings()
        
        if (notificationSettings.types == UIUserNotificationType.None){
            
            var notificationTypes: UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Badge
            
            var ignoreAction = UIMutableUserNotificationAction()
            ignoreAction.identifier = "ignore"
            ignoreAction.title = "Ignore"
            ignoreAction.activationMode = UIUserNotificationActivationMode.Background
            ignoreAction.destructive = false
            ignoreAction.authenticationRequired = false
            
            var viewAction = UIMutableUserNotificationAction()
            viewAction.identifier = "view"
            viewAction.title = "View"
            viewAction.activationMode = UIUserNotificationActivationMode.Foreground
            viewAction.destructive = false
            viewAction.authenticationRequired = true
            
            let actionsArray = NSArray(objects: ignoreAction, viewAction)
            
            var l8rReminderCategory = UIMutableUserNotificationCategory()
            l8rReminderCategory.identifier = "l8rReminderCategory"
            l8rReminderCategory.setActions(actionsArray as [AnyObject], forContext: UIUserNotificationActionContext.Default)
            l8rReminderCategory.setActions(actionsArray as [AnyObject], forContext: UIUserNotificationActionContext.Minimal)

            
            let categoriesForSettings = NSSet(objects: l8rReminderCategory)
            
            
            let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: categoriesForSettings as Set<NSObject>)
            
            UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
        }
    }
    
    func setUpCoreData(){
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
    }
    
    func fetchL8rs(){
        
        println("fetching")

        let fetchRequest = NSFetchRequest(entityName: "L8R")
        var error: NSError?
        
        let fireDateSort = NSSortDescriptor(key: "fireDate", ascending: true)
        let fireDateSorts = [fireDateSort]
        
        l8rsBeforeCurrentDate = []
        
        fetchRequest.sortDescriptors = fireDateSorts
        
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [NSManagedObject]?

        if let results = fetchedResults {
            
            
            let currentDate = NSDate()
            for l8r in results {
                
//                //if you ever need to delete all of them
//                managedContext.deleteObject(l8r)
//                
//                var error: NSError?
//                
//                if !managedContext.save(&error) {
//                    println("Unresolved error \(error), \(error!.userInfo)")
//                    abort()
//                }
        
              //  println(l8r.valueForKey("fireDate"))
                
                if currentDate.compare(l8r.valueForKey("fireDate") as! NSDate) == NSComparisonResult.OrderedDescending {
                    l8rsBeforeCurrentDate.append(l8r)
                    
                    
                }

            }
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        
        self.updateInboxCount()
      //  [UIApplication sharedApplication].applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey: @"badgecount"] intValue];
        


    }
    
    
    //MARK: - Set up overlay view
    
    func addInboxBadge(){
        
       let inboxFrame = UIButton(frame:CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxFrame.addTarget(self, action: Selector("inboxButtonPressed:"), forControlEvents: .TouchUpInside)

        
        inboxNumber = UILabel(frame: CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxNumber.font = UIFont(name: "Arial-BoldMT", size: 32)
        
        inboxNumber.textAlignment = .Center
        inboxNumber.textColor = UIColor.clearColor()
        inboxNumber.layer.shadowColor = UIColor.blackColor().CGColor
        inboxNumber.layer.shadowOffset = CGSizeMake(0, 1)
        inboxNumber.layer.shadowOpacity = 1
        inboxNumber.layer.shadowRadius = 1
        self.updateInboxCount()
        pageViewController!.view.addSubview(inboxNumber)
        pageViewController!.view.addSubview(inboxFrame)
        
        
    }
    
    func inboxButtonPressed(sender:UIButton){
        let ivc = self.storyboard!.instantiateViewControllerWithIdentifier("InboxViewController") as! InboxViewController
        self.presentViewController(ivc, animated: true, completion: nil)
    }
    
    func updateInboxCount(){
        
        if inboxNumber != nil {
        
            if l8rsBeforeCurrentDate.count > 0 {
                inboxNumber.text = String(l8rsBeforeCurrentDate.count)
                UIApplication.sharedApplication().applicationIconBadgeNumber = l8rsBeforeCurrentDate.count
            }
            else {
                inboxNumber.text = "👍"
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0}
        }
    }
    
    
    
    
    //MARK: - L8R Management
    
    
    func deleteL8r(){
        
        
        //special case if the L8R being deleted is the photo we just took
        if self.pageViewController?.viewControllers[0].restorationIdentifier == "CameraController" {
            
            let currentPage = self.pageViewController?.viewControllers[0] as! CameraController
            currentPage.previewLayer?.connection.enabled = true
           // hideTriggerButtons(true)
        //    currentPage.textView.removeFromSuperview()
            currentPage.textButton.hidden = true
            currentPage.textToSave = ""

            
        }
            
        else {
            
            let currentPage = self.pageViewController?.viewControllers[0] as! PageItemController
            indexOfCurrentPage = currentPage.itemIndex
            
            
            //DELETE L8R
            managedContext.deleteObject(l8rsBeforeCurrentDate[indexOfCurrentPage])
            
            var error: NSError?
            
            if !managedContext.save(&error) {
                println("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
            
        }
        
    }

    
    func toggleTriggerButtonVisibility(sender: UIButton){
        
        
        
        for button in pageViewController!.view.subviews as! [UIView] {
            if (button.isKindOfClass(MenuButton)){
                if (sender.tag == 101){ // it's the textButton, so turn them off
                    button.hidden = true
                }
                else {
                    button.hidden = !button.hidden
                }
            }
            else {
            }
        }
    }

    
    func scheduleLocalNotificationWithFireDate(fireDate: NSDate) {
        println("scheduling notification with date \(fireDate)")
        var localNotification = UILocalNotification()
        localNotification.fireDate = fireDate
        localNotification.alertBody = "A L8R just arrived for you"
        localNotification.alertAction = "View"
        localNotification.category = "l8rReminderCategory"
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
    }
    
    func handleViewNotification(){
        println("foo")
        self.fetchL8rs()
        let ivc = self.storyboard!.instantiateViewControllerWithIdentifier("InboxViewController") as! InboxViewController
        self.presentViewController(ivc, animated: false, completion: nil)
    }
    
    
    // MARK: - UIPageViewControllerDataSource
    
    func createPageViewController() {
        
        //create PageViewController
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier("PageController") as! UIPageViewController
        pageController.delegate = self
        pageController.dataSource = self
        
        //create cameraController and set as first page
        cameraController = self.storyboard!.instantiateViewControllerWithIdentifier("CameraController") as! CameraController
        let startingViewControllers: NSArray = [cameraController]
        
        pageController.addChildViewController(cameraController)
        
        
        pageViewController = pageController
        addChildViewController(pageViewController!)
        
        self.addInboxBadge()
        
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
        
        pageController.setViewControllers(startingViewControllers as [AnyObject], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nil
        
//        if viewController.restorationIdentifier == "CameraController" {
//            return nil // Camera is always first
//        }
//        
//        else { // we got a PageItemController
//            var itemController = viewController as! PageItemController
//            if itemController.itemIndex == 0 { //If we got the first ItemController, then go back to Camera
//                return cameraController
//            }
//            else {
//                return getItemController(itemController.itemIndex-1) //Otherwise go back to previous ItemController
//            }
//        
//            
//        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        return nil
        
//        println("looking for next vc")
//
//        
//        if viewController.restorationIdentifier == "CameraController" {
//            println("a")
//            return getItemController(0) // top of Inbox
//        }
//        
//        else {
//            println("b")
//            var itemController = viewController as! PageItemController
//
//            if itemController.itemIndex+1 < l8rsBeforeCurrentDate.count {
//                println("c")
//                return getItemController(itemController.itemIndex+1)
//            }
//            println("d")
//            return nil
//        }
        
    }
    
    private func getItemController(itemIndex: Int) -> PageItemController? {
        

        if l8rsBeforeCurrentDate.count == 0 {
            println("no more items to show, so I should never be called")
            
            return nil
        }
        else {
            println("getting controller for index \(itemIndex)")
            let pageItemController = self.storyboard!.instantiateViewControllerWithIdentifier("ItemController") as! PageItemController
            pageItemController.itemIndex = itemIndex
            let l8r = l8rsBeforeCurrentDate[itemIndex]
            pageItemController.imageData = l8r.valueForKey("imageData") as! NSData
            return pageItemController
        }
        
    }
}

