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
    
    @IBOutlet weak var cardStackView:CardStack!
    
    
    let colors:[UIColor] = [UIColor.redColor(), UIColor.blueColor(), UIColor.greenColor(), UIColor.yellowColor(), UIColor.magentaColor(), UIColor.purpleColor(), UIColor.blackColor()]
    
    var cardCount: Int {
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
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

        
        return self.l8rsBeforeCurrentDate.count
    }
    
    var inboxNumber: UILabel!
    var l8rsBeforeCurrentDate = [NSManagedObject]()
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpCoreData()
        self.fetchL8rs()
        self.cardStackView.delegate = self
        self.cardStackView.updateStack()
        self.addInboxBadge()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    func cardRemoved(card: Card) {
        println("The card \(card.cardId!) was removed!")
    }
    
    func cardAtIndex(index: Int, frame: CGRect) -> Card {
        
        return createDemoCardView(index, textColor: UIColor.blackColor())
    }
    
    
    func createDemoCardView(cardId: Int, textColor: UIColor) -> Card {
        println("creating in demoCard")

        
        let l8r = l8rsBeforeCurrentDate[cardId]
        let imageData = l8r.valueForKey("imageData") as! NSData
        let image = UIImage(data: imageData, scale: 0.0)!
        let ratio = self.view.frame.height/image.size.height
        
        let card: Card = Card(frame: CGRect(x: 0, y: 0, width: image.size.width*ratio, height:image.size.height*ratio))
        card.backgroundColor = UIColor(red: 0, green: 0, blue: 240, alpha: 0)
        card.cardId = cardId
        card.center.x = view.center.x
        
        card.image = image
        card.clipsToBounds = true
        card.contentMode = UIViewContentMode.ScaleAspectFit
        
        return card

        
        
//        let label: UILabel = UILabel(frame: card.frame)
//      //  label.text = "\(cardId)"
//        label.textColor = textColor
//        label.textAlignment = NSTextAlignment.Center
//        println(l8rsBeforeCurrentDate.count)
//        println(l8rsBeforeCurrentDate[0])
    
        
    }
    
    func addInboxBadge(){
        
        let inboxFrame = UIButton(frame:CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxFrame.addTarget(self, action: Selector("inboxButtonPressed:"), forControlEvents: .TouchUpInside)
        
        
        inboxNumber = UILabel(frame: CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxNumber.font = UIFont(name: "Arial-BoldMT", size: 24)
        
        inboxNumber.textAlignment = .Center
        inboxNumber.textColor = UIColor.blackColor()
        inboxNumber.layer.shadowColor = UIColor.blackColor().CGColor
        inboxNumber.layer.shadowOffset = CGSizeMake(0, 1)
        inboxNumber.layer.shadowOpacity = 1
        inboxNumber.layer.shadowRadius = 1
        inboxNumber.text = "<-"
        cardStackView.addSubview(inboxNumber)
        cardStackView.addSubview(inboxFrame)
    }
    
    func inboxButtonPressed(sender:UIButton){
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
        self.presentViewController(vc, animated: true, completion: nil)
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

