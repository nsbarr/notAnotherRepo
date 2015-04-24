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
    
    var currentImage: UIImage?
    var currentL8r: NSManagedObject?
    
    var l8rsBeforeCurrentDate = [NSManagedObject]()

    let colors:[UIColor] = [UIColor.redColor(), UIColor.blueColor(), UIColor.greenColor(), UIColor.yellowColor(), UIColor.magentaColor(), UIColor.purpleColor(), UIColor.blackColor()]
    
    var cardCount: Int {
        
        if l8rsBeforeCurrentDate.isEmpty {
        
            appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest(entityName: "L8R")
            var error: NSError?
            
            let fireDateSort = NSSortDescriptor(key: "fireDate", ascending: true)
            let fireDateSorts = [fireDateSort]
            
            
            
            fetchRequest.sortDescriptors = fireDateSorts
            
            
            let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [NSManagedObject]?
            
            if let results = fetchedResults {
                
                
                let currentDate = NSDate()
                for l8r in results {
                    
                    //                //if you ever need to delete all of them, uncomment this and comment the if statement below
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
                        println("appended!")
                        
                        
                    }
                    
                }
            }
            else {
                println("Could not fetch \(error), \(error!.userInfo)")
            }
        }
        
        //  [UIApplication sharedApplication].applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey: @"badgecount"] intValue];

        
        return self.l8rsBeforeCurrentDate.count
    }
    
    var inboxNumber: UILabel!
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!

    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpCoreData()
        self.fetchL8rs()
        self.cardStackView.delegate = self
        self.cardStackView.updateStack()
        self.addInboxBadge()
        self.addLaterSnapButton()
        self.addListSnapButton()
        self.addDismissButton()
        self.addShareButton()
    }
    
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
        var snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-130, width: 100, height: 100))
        snapButton.center.x = view.center.x+(snapButton.frame.width/2+5)
        snapButton.tag = 0
        let buttonImage = UIImage(named: "laterSnapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        snapButton.hidden = false
        
        cardStackView.addSubview(snapButton)
        
    }
    
    func addListSnapButton(){
        var listSnapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-130, width: 100, height: 100))
        listSnapButton.center.x = view.center.x-(listSnapButton.frame.width/2+5)
        listSnapButton.tag = 1234
        let buttonImage = UIImage(named: "listSnapButton")
        listSnapButton.setImage(buttonImage, forState: .Normal)
        listSnapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        listSnapButton.hidden = false
        
        cardStackView.addSubview(listSnapButton)
    }
    
    
    func addDismissButton(){
        var dismissButton = UIButton(frame: CGRect(x: 28, y: view.frame.height-130, width: 52, height: 52))
        let buttonImage = UIImage(named: "dismissButton")
        dismissButton.setImage(buttonImage, forState: .Normal)
        dismissButton.addTarget(self, action: Selector("dismissTopCard"), forControlEvents: .TouchUpInside)
        cardStackView.addSubview(dismissButton)
    }
    
    func addShareButton(){
        var shareButton = UIButton(frame: CGRect(x: view.frame.width-80, y: view.frame.height-130, width: 52, height: 52))
        let buttonImage = UIImage(named: "shareButton")
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
        
        if let image = currentImage {
            sharingItems.append(image)
        }
        
        let url = NSURL(string: "http://lthenumbereightr.com")
        sharingItems.append(url!)
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    
    
    
    func snapButtonPressed(sender: UIButton){
        
        let mvc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
        mvc.modalPresentationStyle = .OverCurrentContext
        
        
        if sender.tag == 1234{
            mvc.image = self.currentImage!
            mvc.viewToShow = "album"
        }
        else if sender.tag == 0{
            mvc.image = self.currentImage!
            mvc.viewToShow = "snooze"
        }
        else {
            println("don't recognize \(sender)")
        }
        
        self.presentViewController(mvc, animated: true, completion: nil)
        
    }
    
    //MARK: - Card delegate Methods
    
    func cardRemoved(card: Card) {
        println("The card \(card.cardId!) was removed!")
        
        //TODO: This is fucked

        if card.cardId > -1 { //why?🔥
        
            managedContext.deleteObject(l8rsBeforeCurrentDate[card.cardId!]) //just guessin
            
            var error: NSError?
            
            if !managedContext.save(&error) {
                println("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }

        
        
    }
    
    func cardAtIndex(index: Int, frame: CGRect) -> Card {
        
        return createDemoCardView(index, textColor: UIColor.blackColor())
    }
    
    
    func createDemoCardView(cardId: Int, textColor: UIColor) -> Card {
        println("creatingDemoCard\(cardId)")

        
        currentL8r = l8rsBeforeCurrentDate[cardId]
        println(currentL8r)
        
        if currentL8r!.valueForKey("imageData") != nil {
            let imageData = currentL8r!.valueForKey("imageData") as! NSData
            let image = UIImage(data: imageData, scale: 0.0)!
            let ratio = self.view.frame.height/image.size.height
            
            let card: Card = Card(frame: CGRect(x: 0, y: 0, width: image.size.width*ratio, height:image.size.height*ratio))
            card.backgroundColor = UIColor(red: 0, green: 0, blue: 240, alpha: 0)
            card.cardId = cardId
            card.center.x = view.center.x
            currentImage = image
            card.image = image
            
            card.clipsToBounds = true
            card.contentMode = UIViewContentMode.ScaleAspectFit
            
            return card
            
        }
        else {
            let card: Card = Card(frame: CGRect(x: 0, y: 0, width: 0, height:0))
            card.cardId = cardId
        
            
            let label: UILabel = UILabel(frame: card.frame)
            label.text = "Oops! I goofed 😔"
            label.textColor = UIColor.redColor()
            label.textAlignment = NSTextAlignment.Center
            
            card.addSubview(label)

            return card
        }
    }
    
    
    func showAlbumList(sender:UIButton){
        
        let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
        
        if currentImage != nil {
            avc.image = currentImage!
            avc.modalPresentationStyle = .OverCurrentContext
            self.presentViewController(avc, animated: true, completion: {() -> Void in
                
            })
        }
        else {println("no image to l8r")}
        
    }
    
    func flashConfirm(){
        let flashConfirm = UIImageView(frame: CGRect(x:0, y: 0, width: self.view.frame.width-200, height: self.view.frame.width-200))
        flashConfirm.center = self.view.center
        flashConfirm.image = UIImage(named: "flashConfirm")
        flashConfirm.contentMode = UIViewContentMode.ScaleAspectFit
        flashConfirm.alpha = 1
        self.view.addSubview(flashConfirm)
        
        
        UIView.animateKeyframesWithDuration(0.5, delay: 0.2, options: nil, animations: { () -> Void in
            flashConfirm.alpha = 0
            }, completion: nil)
        
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
                
                //                //if you ever need to delete all of them, uncomment this and comment the if statement below
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
                    println("appended!")
                    
                    
                }
                
            }
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

