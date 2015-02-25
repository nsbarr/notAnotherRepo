//
//  ViewController.swift
//  L8R
//

import UIKit
import CoreData

class ViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    //MARK: - Variables 
    
    var pageViewController: UIPageViewController?
    var cameraController: CameraController!
    
    var l8rsBeforeCurrentDate = [NSManagedObject]()
    var indexOfCurrentPage: Int!
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
        
    var inboxButton: UIButton!
    var inboxNumber: UILabel!
    
   // var dateButton: UIButton!
    var triggerButton: UIButton!
    var scheduleButton: UIButton!
   // var deleteButton: UIButton!
    var datePicker: UIDatePicker!
    
    var nc: UINavigationController?
    let vc = UIViewController()
    
    
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
            l8rReminderCategory.setActions(actionsArray, forContext: UIUserNotificationActionContext.Default)
            l8rReminderCategory.setActions(actionsArray, forContext: UIUserNotificationActionContext.Minimal)
            
            
            //convenience init(forTypes allowedUserNotificationTypes: UIUserNotificationType, categories actionSettings: NSSet?)
            
            
            let categoriesForSettings = NSSet(objects: l8rReminderCategory)
            
            
            let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: categoriesForSettings)
            
            UIApplication.sharedApplication().registerUserNotificationSettings(newNotificationSettings)
        }
    }
    
    func setUpCoreData(){
        appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        managedContext = appDelegate.managedObjectContext!
    }
    
    func fetchL8rs(){

        let fetchRequest = NSFetchRequest(entityName: "L8R")
        var error: NSError?
        
        let fireDateSort = NSSortDescriptor(key: "fireDate", ascending: true)
        let fireDateSorts = [fireDateSort]
        
        l8rsBeforeCurrentDate = []
        
        fetchRequest.sortDescriptors = fireDateSorts
        
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?

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
                
                println(l8r.valueForKey("fireDate"))
                
                if currentDate.compare(l8r.valueForKey("fireDate") as NSDate) == NSComparisonResult.OrderedDescending {
                    l8rsBeforeCurrentDate.append(l8r)
                    
                    
                }

            }
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    
    //MARK: - Set up overlay view
    
    func addInboxBadge(){
        
       let inboxFrame = UIImageView(frame:CGRectMake(self.view.frame.width - 44, 20, 40, 40))
//        inboxFrame.image = UIImage(named: "inboxFrame")
//        pageViewController!.view.addSubview(inboxFrame)
        
        inboxNumber = UILabel(frame: CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxNumber.font = UIFont(name: "Arial-BoldMT", size: 24)
        
        inboxNumber.textAlignment = .Center
        inboxNumber.textColor = UIColor.whiteColor()
        inboxNumber.layer.shadowColor = UIColor.blackColor().CGColor
        inboxNumber.layer.shadowOffset = CGSizeMake(0, 1)
        inboxNumber.layer.shadowOpacity = 1
        inboxNumber.layer.shadowRadius = 1
        self.updateInboxCount()
        pageViewController!.view.addSubview(inboxNumber)
        
        
    }
    
    func updateInboxCount(){
        if l8rsBeforeCurrentDate.count > 0 {
            inboxNumber.text = String(l8rsBeforeCurrentDate.count)
        }
        else {inboxNumber.text = "💎"}
    }
    
    func appearTriggerButtons(){
        let triggerButtons = ["Never Again", "Pick a Date", "Next Year", "Next Month", "Next Week", "Tomorrow", "In an Hour", "Right Now"]
        let triggerButtonTags = [86, 666, 365, 30, 7, 1, 60, 0]
        var buttonTag = 0
        let triggerButtonPadding:CGFloat = 20
        var triggerButtonYPos:CGFloat = 100
        
        for triggerButtonTitle in triggerButtons {
            triggerButton = MenuButton(frame: CGRectMake(0, triggerButtonYPos, 100, 44))
            triggerButton.setTitle(triggerButtonTitle, forState: .Normal)
            triggerButton.tag = triggerButtonTags[buttonTag]
            triggerButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: UIControlEvents.TouchUpInside)
            triggerButton.sizeToFit()
            pageViewController!.view.addSubview(triggerButton)
            triggerButtonYPos = triggerButtonYPos + triggerButton.frame.height + triggerButtonPadding
            buttonTag = buttonTag + 1
        }
        
        
    }
    
    func addActionButtons(){
        
        
//        dateButton = UIButton(frame: CGRectMake(20, self.view.frame.height-60, 116, 42))
//        dateButton.addTarget(self, action: Selector("openDateMenu:"), forControlEvents: UIControlEvents.TouchUpInside)
//        dateButton.center.x = self.view.center.x
//        let dateButtonImage = UIImage(named: "tomorrowButton")
//        dateButton.setImage(dateButtonImage, forState: .Normal)
//        dateButton.tag = 1
//        dateButton.hidden = false
//        pageViewController!.view.addSubview(dateButton)
        
        
        
//        scheduleButton = UIButton(frame: CGRectMake(self.view.frame.width-78, self.view.frame.height-62, 69, 50))
//        scheduleButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: UIControlEvents.TouchUpInside)
//        let scheduleButtonImage = UIImage(named: "scheduleButton")
//        scheduleButton.setImage(scheduleButtonImage, forState: .Normal)
//        scheduleButton.hidden = false
//        pageViewController!.view.addSubview(scheduleButton)
        
//        deleteButton = UIButton(frame: CGRectMake(20, 20, 40, 40))
//        deleteButton.addTarget(self, action: Selector("deleteL8r"), forControlEvents: UIControlEvents.TouchUpInside)
//     //   let deleteButtonImage = UIImage(named: "deleteButton")
//    //    deleteButton.setImage(deleteButtonImage, forState: .Normal)
//        deleteButton.setTitle("×", forState: .Normal)
//        deleteButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 40)
//        deleteButton.titleLabel?.textAlignment = .Center
//        deleteButton.titleLabel?.textColor = UIColor.whiteColor()
//        deleteButton.layer.shadowColor = UIColor.blackColor().CGColor
//        deleteButton.layer.shadowOffset = CGSizeMake(0, 1)
//        deleteButton.layer.shadowOpacity = 1
//        deleteButton.layer.shadowRadius = 1
//        deleteButton.hidden = false
//        pageViewController!.view.addSubview(deleteButton)

    }
    
    
    func hideButtons(toggle: Bool){
        println("changing hidden to \(toggle)")
        for button in pageViewController!.view.subviews as [UIView] {
            if (button.isKindOfClass(MenuButton)){
                button.hidden = toggle
            }
        }
    }
    
    func openDateMenu(sender: UIButton){
        
        vc.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        vc.modalPresentationStyle = .OverCurrentContext
        
        let rightNowButton = UIButton(frame: CGRectMake(20, 40, 116, 42))
        rightNowButton.setImage(UIImage(named: "rightNowButton"), forState: .Normal)
        rightNowButton.addTarget(self, action: Selector("updateDate:"), forControlEvents: .TouchUpInside)
        rightNowButton.tag = 2
        vc.view.addSubview(rightNowButton)
        
        let tmrwButton = UIButton(frame: CGRectMake(20, 90, 116, 42))
        tmrwButton.setImage(UIImage(named: "tomorrowButton"), forState: .Normal)
        tmrwButton.addTarget(self, action: Selector("updateDate:"), forControlEvents: .TouchUpInside)
        tmrwButton.tag = 1
        vc.view.addSubview(tmrwButton)
        
        let nextWeekButton = UIButton(frame: CGRectMake(20, 140, 116, 42))
        nextWeekButton.setImage(UIImage(named: "nextWeekButton"), forState: .Normal)
        nextWeekButton.addTarget(self, action: Selector("updateDate:"), forControlEvents: .TouchUpInside)
        nextWeekButton.tag = 7
        vc.view.addSubview(nextWeekButton)
        
        let pickDateButton = UIButton(frame: CGRectMake(20, 190, 116, 42))
        pickDateButton.setImage(UIImage(named: "pickDateButton"), forState: .Normal)
        pickDateButton.addTarget(self, action: Selector("openCalendarMenu:"), forControlEvents: .TouchUpInside)
        pickDateButton.tag = 999
        vc.view.addSubview(pickDateButton)

        
        
        nc = UINavigationController(rootViewController: vc)
        nc!.navigationBar.hidden = true
        nc!.modalPresentationStyle = .OverCurrentContext
        
        presentViewController(nc!, animated: false, completion: nil)
    }
    
//    func updateDate(sender: UIButton){
//        dateButton.setImage(sender.imageForState(.Normal), forState: .Normal)
//        dateButton.tag = sender.tag
//        self.dismissViewControllerAnimated(false, completion: nil)
//    }
    
    func openCalendarMenu(){
        
        vc.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        vc.modalPresentationStyle = .OverCurrentContext
        

        
        datePicker = UIDatePicker(frame: self.view.frame)
        datePicker.center.y = self.view.center.y
        vc.view.addSubview(datePicker)
        
        let confirmButton = UIButton(frame: CGRectMake(0, self.view.frame.height-200, 116, 42))
        confirmButton.center.x = self.view.center.x
        confirmButton.setImage(UIImage(named: "pickDateButton"), forState: .Normal)
        confirmButton.tag = 777
        confirmButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: .TouchUpInside)
        vc.view.addSubview(confirmButton)
        
        nc = UINavigationController(rootViewController: vc)
        nc!.navigationBar.hidden = true
        nc!.modalPresentationStyle = .OverCurrentContext
        
        presentViewController(nc!, animated: false, completion: nil)
        
    }
    
    
    func getDateFromDateButton(tag: Int) -> NSDate? {
        
        let currentTime = NSDate()
        var theCalendar = NSCalendar.currentCalendar()
        let timeComponent = NSDateComponents()
        //let triggerButtonTags = [86, 666, 365, 30, 7, 1, 60, 0]
        if tag == 1 { // tomorrow

            timeComponent.day = 1
            var scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
            return scheduledDate
        }
        else if tag == 7 { // next week
            timeComponent.day = 7
            var scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
            return scheduledDate
        }
        
        else if tag == 0 { // right now
            return NSDate()
        }
        
        else if tag == 60 { // in an hour
            timeComponent.hour = 1
            var scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
            return scheduledDate
        }
        
        else if tag == 30 { //in a month
            timeComponent.month = 1
            var scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
            return scheduledDate
        }
            
        else if tag == 365 { // in a year
            timeComponent.year = 1
            var scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
            return scheduledDate
        }
            
        else if tag == 777 { // calendar
            return datePicker.date
        }
        else {
            return NSDate()

        }
    }
    
    //MARK: - L8R Management
    
    func deleteL8r(){
        
        
        //special case if the L8R being deleted is the photo we just took
        if self.pageViewController?.viewControllers[0].restorationIdentifier == "CameraController" {
            
            let currentPage = self.pageViewController?.viewControllers[0] as CameraController
            currentPage.previewLayer?.connection.enabled = true
            hideButtons(true)
            currentPage.snapButton.hidden = false
            
        }
            
        else {
            
            let currentPage = self.pageViewController?.viewControllers[0] as PageItemController
            indexOfCurrentPage = currentPage.itemIndex
            
            
            //DELETE L8R
            managedContext.deleteObject(l8rsBeforeCurrentDate[indexOfCurrentPage])
            
            var error: NSError?
            
            if !managedContext.save(&error) {
                println("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
            
            self.moveOnToNextL8r()
        }
        
        
    }
    
    
    
    func scheduleL8r(sender: UIButton){
        
        if sender.tag == 777 {
            nc?.dismissViewControllerAnimated(false, completion: nil)
        }
        
        if sender.tag == 86 {
            println("never again")
            deleteL8r()
        }
        
        else if sender.tag == 666 {
            self.openCalendarMenu()
        }
        
        //SPECIAL CASE IF L8R BEING SCHEDULED IS THE ONE WE JUST TOOK
        else if self.pageViewController?.viewControllers[0].restorationIdentifier == "CameraController" {
            
            let currentPage = self.pageViewController?.viewControllers[0] as CameraController
            currentPage.previewLayer?.connection.enabled = true
            hideButtons(true)
            currentPage.snapButton.hidden = false
            let imageToSchedule = currentPage.image
            
            //SAVE NEW L8R
            let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: managedContext)
            let l8r = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            let imageData = UIImageJPEGRepresentation(imageToSchedule, 0)
            l8r.setValue(imageData, forKey: "imageData")
            l8r.setValue(getDateFromDateButton(sender.tag), forKey: "fireDate")
            
            var error: NSError?
            if !managedContext.save(&error) {
                println("Coulnd't save \(error), \(error?.userInfo)")
            }
            
            //UPDATE L8RS
            self.fetchL8rs()
            self.updateInboxCount()
            
            //Current thinking is that the app caches the page left and right (nil) on the first schedule, and doesn't refresh. Workaround below is to setViewController
            
            self.scheduleLocalNotificationWithFireDate(getDateFromDateButton(sender.tag)!)

            pageViewController?.setViewControllers([cameraController], direction: UIPageViewControllerNavigationDirection.Reverse, animated: false, completion: nil)
            
            
            
        }
            
        else {
            
            let currentPage = self.pageViewController?.viewControllers[0] as PageItemController
            indexOfCurrentPage = currentPage.itemIndex
            
            //RESCHEDULE L8R
            
            let imageToSchedule = currentPage.image
            let imageData = UIImageJPEGRepresentation(imageToSchedule, 0)
            let itemIndex = currentPage.itemIndex
            let l8r = l8rsBeforeCurrentDate[itemIndex]
            l8r.setValue(imageData, forKey: "imageData")
            l8r.setValue(getDateFromDateButton(sender.tag), forKey: "fireDate")
            
            var error: NSError?
            if !managedContext.save(&error) {
                println("Coulnd't save \(error), \(error?.userInfo)")
            }
            
            self.scheduleLocalNotificationWithFireDate(getDateFromDateButton(sender.tag)!)
            self.moveOnToNextL8r()
            
        }
        
        
        
    }
    
    func moveOnToNextL8r(){
        //REFRESH LIST
        self.fetchL8rs()
        self.updateInboxCount()
        
        
        //SHOW CAMERA IF NO MORE L8RS TO SHOW
        if l8rsBeforeCurrentDate.count == 0 {
            println("show camera")
            //   cameraController = self.storyboard!.instantiateViewControllerWithIdentifier("CameraController") as CameraController
            //     pageViewController?.addChildViewController(cameraController)
            pageViewController?.setViewControllers([cameraController], direction: UIPageViewControllerNavigationDirection.Reverse, animated: false, completion: nil)
        }
            
            //SHOW PREVIOUS L8R IF WE DELETED/SCHEDULED THE LAST ONE
            
        else if indexOfCurrentPage > (l8rsBeforeCurrentDate.count-1) {
            
            println("show prev l8r")
            let targetViewController = getItemController(l8rsBeforeCurrentDate.count-1) as PageItemController!
            let arrayVC : NSArray = [targetViewController]
            pageViewController?.setViewControllers(arrayVC, direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        }
            
            //OTHERWISE SHOW L8R AT CURRENT INDEX
        else {
            
            println("show new l8r at current index")
            let targetViewController = getItemController(indexOfCurrentPage) as PageItemController!
            let arrayVC : NSArray = [targetViewController]
            pageViewController?.setViewControllers(arrayVC, direction: UIPageViewControllerNavigationDirection.Reverse, animated: false, completion: nil)
            
        }
        
    }

    
    func scheduleLocalNotificationWithFireDate(fireDate: NSDate) {
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
        let targetViewController = getItemController(0) as PageItemController!
        let arrayVC : NSArray = [targetViewController]
        pageViewController?.setViewControllers(arrayVC, direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    }
    
    
    // MARK: - UIPageViewControllerDataSource
    
    func createPageViewController() {
        
        //create PageViewController
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier("PageController") as UIPageViewController
        pageController.delegate = self
        pageController.dataSource = self
        
        //create cameraController and set as first page
        cameraController = self.storyboard!.instantiateViewControllerWithIdentifier("CameraController") as CameraController
        let startingViewControllers: NSArray = [cameraController]
        
        pageController.addChildViewController(cameraController)
        
        
        pageViewController = pageController
        addChildViewController(pageViewController!)
        
        self.addInboxBadge()
        self.appearTriggerButtons()
        
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
        
        pageController.setViewControllers(startingViewControllers, direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        
        if viewController.restorationIdentifier == "CameraController" {
            return nil // Camera is always first
        }
        
        else { // we got a PageItemController
            var itemController = viewController as PageItemController
            if itemController.itemIndex == 0 { //If we got the first ItemController, then go back to Camera
                return cameraController
            }
            else {
                return getItemController(itemController.itemIndex-1) //Otherwise go back to previous ItemController
            }
        
            
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        println("looking for next vc")

        
        if viewController.restorationIdentifier == "CameraController" {
            println("a")
            return getItemController(0) // top of Inbox
        }
        
        else {
            println("b")
            var itemController = viewController as PageItemController

            if itemController.itemIndex+1 < l8rsBeforeCurrentDate.count {
                println("c")
                return getItemController(itemController.itemIndex+1)
            }
            println("d")
            return nil
        }
        
    }
    
    private func getItemController(itemIndex: Int) -> PageItemController? {
        

        if l8rsBeforeCurrentDate.count == 0 {
            println("no more items to show, so I should never be called")
            
            return nil
        }
        else {
            println("getting controller for index \(itemIndex)")
            let pageItemController = self.storyboard!.instantiateViewControllerWithIdentifier("ItemController") as PageItemController
            pageItemController.itemIndex = itemIndex
            let l8r = l8rsBeforeCurrentDate[itemIndex]
            pageItemController.imageData = l8r.valueForKey("imageData") as NSData
            return pageItemController
        }
        
    }
}

