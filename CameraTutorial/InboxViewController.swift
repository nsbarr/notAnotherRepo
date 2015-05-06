//
//  InboxViewController.swift
//  CameraTutorial
//
//  Created by nick barr on 3/30/15.
//  Copyright (c) 2015 JQ Software. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class InboxViewController: UIViewController, CardStackDelegate {
    
    //MARK: - Variables
    
    @IBOutlet weak var cardStackView:CardStack!
    
    var snapButton: UIButton!
    var l8rsById:[String:L8R]!
    
    
    var currentL8R:L8R! {
      //  println("Card Stack View:\(self.cardStackView)")
      //  println("Top Card: \(self.cardStackView.topCard)")
        if let topCard = self.cardStackView.topCard {
            
            if let cardId = topCard.cardId {
                
                return l8rsById[cardId]!
            }
            else {
                println("error, received topCard but no cardId")
            }
        }
        else {
            //possible error, topCard was nil
            println("possible error, topCard was nil")
        }
        return nil
    }
    
    var cardCount: Int {
        println("Card Count:\(self.l8rsById.count)")
        
        return self.l8rsById.count
    }
    
    var inboxNumber: UILabel!
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!

    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpCoreData()
        self.fetchL8rs()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        self.cardStackView.delegate = self
        self.cardStackView.updateStack()
        self.addInboxBadge()
        self.addLaterSnapButton()
        self.addDismissButton()
        self.addShareButton()
    }
    
    //TODO: App crashes if you cancel from the share sheet, because of UpdateStack
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func addInboxBadge(){
        
        let inboxFrame = UIButton(frame:CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxFrame.addTarget(self, action: Selector("inboxButtonPressed:"), forControlEvents: .TouchUpInside)
        
        
        inboxNumber = UILabel(frame: CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxNumber.font = UIFont(name: "Arial-BoldMT", size: 32)
        
        inboxNumber.textAlignment = .Center
        inboxNumber.textColor = UIColor.blackColor()
        inboxNumber.layer.shadowColor = UIColor.blackColor().CGColor
        inboxNumber.layer.shadowOffset = CGSizeMake(0, 1)
        inboxNumber.layer.shadowOpacity = 1
        inboxNumber.layer.shadowRadius = 1
        inboxNumber.text = "📷"
        cardStackView.addSubview(inboxNumber)
        cardStackView.addSubview(inboxFrame)
    }
    
    func addLaterSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-130, width: 100, height: 100))
        snapButton.center.x = view.center.x
        snapButton.tag = 0
        let buttonImage = UIImage(named: "laterSnapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        snapButton.hidden = false
        
        cardStackView.addSubview(snapButton)
    }
    
    
    func addDismissButton(){
        var dismissButton = UIButton(frame: CGRect(x: 28, y: view.frame.height-130, width: 60, height: 60))
        let buttonImage = UIImage(named: "dismissButton")
        dismissButton.center.x = snapButton.center.x-100
        dismissButton.setImage(buttonImage, forState: .Normal)
        dismissButton.addTarget(self, action: Selector("dismissTopCard"), forControlEvents: .TouchUpInside)
        cardStackView.addSubview(dismissButton)
    }
    
    func addShareButton(){
        var shareButton = UIButton(frame: CGRect(x: view.frame.width-80, y: view.frame.height-130, width: 60, height: 60))
        let buttonImage = UIImage(named: "shareButton")
        shareButton.center.x = snapButton.center.x+100
        shareButton.setImage(buttonImage, forState: .Normal)
        shareButton.addTarget(self, action: Selector("openShareSheet:"), forControlEvents: .TouchUpInside)
        cardStackView.addSubview(shareButton)
    }

    
    //MARK: - Actions
    
    func dismissTopCard(){
        self.cardStackView.swipeOutTopCardWithSpeed(1.0)
    }

    func inboxButtonPressed(sender:UIButton){
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    
    func openShareSheet(sender: UIButton){
        var sharingItems = [AnyObject]()
        
        let text = "Check out this L8R and create your own!"
        sharingItems.append(text)
        
        if let image = UIImage(data: self.currentL8R.imageData, scale: 0.0) {
            sharingItems.append(image)
        }
        
        let url = NSURL(string: "http://lthenumbereightr.com")
        sharingItems.append(url!)
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    
    
    
    func snapButtonPressed(sender: UIButton){
        
        if UIImage(data: self.currentL8R.imageData, scale: 0.0) != nil {
        
            let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
            avc.modalPresentationStyle = .OverCurrentContext
            avc.image = UIImage(data: self.currentL8R.imageData, scale: 0.0)!
            avc.viewToShow = "snooze"
            let nc = UINavigationController(rootViewController: avc)
            nc.navigationBar.hidden = true
            nc.modalPresentationStyle = .OverCurrentContext
            
            presentViewController(nc, animated: true, completion: nil)
            
        }
        else {
            println("current image is nil")
        }
    }


    //MARK: - Card delegate Methods

    func cardRemoved(card: Card) {
        println("The card \(card.cardId!) was removed!")
        
        if let cardToRemove = self.currentL8R as L8R? {
            
            
            dispatch_async(dispatch_get_main_queue(), {   ()->Void in
                
             //   println("Removing card\(self.l8rsById[card.cardId!])")

            
                self.managedContext.deleteObject(cardToRemove)
                    
                var error: NSError?
                    
                if !self.managedContext.save(&error) {
                    println("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
                
                self.l8rsById.removeValueForKey(card.cardId!)
                self.fetchL8rs()
//                self.cardStackView.updateStack()
                
            })
        }
        else {
            println("card to remove is nil! aieeee! \(card)")
        }
        

        
//        let vc = appDelegate.window!.rootViewController as! ViewController
//        vc.updateInboxCount()
        
    }
    
    
    func cardAtIndex(index: Int, frame: CGRect) -> Card {
        var l8rs:[L8R] = []
        l8rs = l8rsById.values.array
        println("Array Count: \(l8rs.count)")


        var dateDescriptor = NSSortDescriptor(key: "fireDateSort", ascending: true)
        
        l8rs.sort { $0.fireDate.compare($1.fireDate) == NSComparisonResult.OrderedAscending }
        var uniqueId = "help"
        //var uniqueId = l8rs[l8rs.count-1].objectIDString
  //      var uniqueId = l8rs[index].objectIDString
        //count - 1 is largest element
        if index > 1 {
            println("Next item in array:\(index)")
            uniqueId = l8rs[2].objectIDString
        }
        else {
            println("Seeding with first l8rs")
            uniqueId = l8rs[index].objectIDString
        }

        
//        var l8rs:[L8R] = l8rsById.values.array
        //    l8rs.sort({ $0.fireDate > $1.fireDate })
        //    println("L8R to display:\(l8rsById[cardId])")
        
        let imageData = l8rsById[uniqueId]?.imageData
        let image = UIImage(data: imageData!, scale: 0.0)!
        let ratio = frame.height/image.size.height
        
        let card: Card = Card(frame: frame)
        card.backgroundColor = UIColor(red: 0, green: 0, blue: 240, alpha: 0)
        card.cardId = uniqueId
        card.center.x = view.center.x
        card.image = image
        
        card.clipsToBounds = true
        card.contentMode = UIViewContentMode.ScaleAspectFill
        
        return card
    //    return createDemoCardView(uniqueId)
    }
    
    
//    func createDemoCardView(cardId: String) -> Card {
//        
//        var l8rs:[L8R] = l8rsById.values.array
//    //    l8rs.sort({ $0.fireDate > $1.fireDate })
//    //    println("L8R to display:\(l8rsById[cardId])")
//
//        let imageData = l8rsById[cardId]?.imageData
//        let image = UIImage(data: imageData!, scale: 0.0)!
//        let ratio = self.view.frame.height/image.size.height
//        
//        let card: Card = Card(frame: CGRect(x: 0, y: 0, width: image.size.width*ratio, height:image.size.height*ratio))
//        card.backgroundColor = UIColor(red: 0, green: 0, blue: 240, alpha: 0)
//        card.cardId = cardId
//        card.center.x = view.center.x
//        card.image = image
//        
//        card.clipsToBounds = true
//        card.contentMode = UIViewContentMode.ScaleAspectFit
//        
//        return card
//            
//    }
    
    
    func showAlbumList(sender:UIButton){
        
        let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
        
        
        
        avc.image = UIImage(data: self.currentL8R.imageData, scale: 0.0)!
        avc.modalPresentationStyle = .OverCurrentContext
        self.presentViewController(avc, animated: true, completion: {() -> Void in
                
            })
    }
    
    func flashConfirm(){
        let flashConfirm = UIImageView(frame: CGRect(x:0, y: 0, width: self.view.frame.width-100, height: self.view.frame.width-100))
        flashConfirm.center = self.view.center
        flashConfirm.image = UIImage(named: "altFlashConfirm")
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFit
        flashConfirm.alpha = 1
        self.view.addSubview(flashConfirm)
        
        
        UIView.animateKeyframesWithDuration(0.5, delay: 0.3, options: nil, animations: { () -> Void in
            flashConfirm.alpha = 0
            //flashConfirm.frame = CGRectMake(self.view.frame.width,0,0,0)
            }, completion: nil)
        
    }
    
    
    func fetchL8rs(){
        
        println("fetching")
        
        let fetchRequest = NSFetchRequest(entityName: "L8R")
        var error: NSError?
        
//        let fireDateSort = NSSortDescriptor(key: "fireDate", ascending: true)
//        let fireDateSorts = [fireDateSort]
//        
//        fetchRequest.sortDescriptors = fireDateSorts
        
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [NSManagedObject]?
        let currentDate = NSDate()
        
        self.l8rsById = [String:L8R]()

        if let results = fetchedResults {
            
            
            
            for anItem in results {
                if let l8rItem = anItem as? L8R {
                    //TODO: Diego doesn't like this
                    println("checking item at date  \(l8rItem.fireDate)")
                    if currentDate.compare(l8rItem.fireDate) == NSComparisonResult.OrderedDescending {
                        l8rsById[l8rItem.objectIDString] = l8rItem
                    }
                }
                else {
                    let cname = NSStringFromClass(anItem.dynamicType)
                    NSLog("item is not a L8R! class name is \(cname)")
                }
                
            }

//            let currentDate = NSDate()
//            for l8rItem in results as! [L8R] {
//                
//                //                //if you ever need to delete all of them, uncomment this
//                //
//                //                var error: NSError?
//                //
//                //                if !managedContext.save(&error) {
//                //                    println("Unresolved error \(error), \(error!.userInfo)")
//                //                    abort()
//                //                }
//                
//                if currentDate.compare(l8rItem.fireDate) == NSComparisonResult.OrderedDescending {
//                    l8rsById[l8rItem.objectIDString] = l8rItem
//                }
//                
//            }
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        
        //  [UIApplication sharedApplication].applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey: @"badgecount"] intValue];
        
    }
    

    func setUpCoreData(){
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

