//
//  AlbumViewController.swift
//  CameraTutorial
//
//  Created by nick barr on 4/20/15.
//  Copyright (c) 2015 JQ Software. All rights reserved.
//

import Foundation
import UIKit
import AssetsLibrary
import CoreData
import QuartzCore


class AlbumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
    
    //MARK: - variables
    
    var snoozeNames = [String]()
    var albumNames:[String]!
    var image = UIImage()
    var viewToShow: String = "nil"
    var tableView: UITableView!
    var datePicker: UIDatePicker!
    var managedContext: NSManagedObjectContext!
    let photoLibrary = ALAssetsLibrary()
    
    //MARK:- Lifecycle
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        if tableView != nil {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        view.frame = self.presentingViewController!.view.frame
        self.displayTheRightView()
    }
    
    func displayTheRightView(){
        
        if viewToShow == "album"{

            tableView = UITableView(frame: CGRectMake(0,60,self.view.frame.width,self.view.frame.height-240), style: UITableViewStyle.Plain)
            self.tableView.delegate=self
            self.tableView.dataSource=self
            tableView.tableFooterView = UIView(frame: CGRectZero)
            tableView.separatorColor = UIColor.clearColor()
            tableView.reloadData()
            self.view.addSubview(tableView)
            
        
        }

        
        else if viewToShow == "snooze"{
            self.getListOfSnoozeOptions()
            self.getListOfAlbums()
            tableView = UITableView(frame: CGRectMake(0,60,self.view.frame.width,self.view.frame.height-230), style: UITableViewStyle.Plain)
            self.tableView.delegate=self;
            self.tableView.dataSource=self;
            tableView.tableFooterView = UIView(frame: CGRectZero)
            tableView.separatorColor = UIColor.clearColor()
            self.view.addSubview(tableView)
            tableView.reloadData()
        }

        else {
            println("error, don't recognize \(viewToShow)")
        }
    }
    
    func getListOfSnoozeOptions(){
        
        snoozeNames = ["📅Pick Date", "🎂In a Year", "🌅Tomorrow", "⏰1 Hour", "⏳In a Minute", "Add to Album >"]
        
    }
    
    
    func getListOfAlbums(){
        println("getting List of albums")
        
        albumNames = [String]()
        
        photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
            usingBlock: {
                (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if group != nil {
                    let albumName = group.valueForProperty(ALAssetsGroupPropertyName) as! String
                    if !((albumName == "Snapchat") || (albumName == "Instagram") || (albumName == "Adobe Shape CC") || (albumName == "Seene")){
                        self.albumNames.append(albumName)
                    }
//                    
//                    group.enumerateAssetsUsingBlock({
//                        (asset: ALAsset!, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
//                        //  println(asset)
//                    })
                }
            },
            failureBlock: {
                (myerror: NSError!) -> Void in
                println("error occurred: \(myerror.localizedDescription)")
        })
        
        //TODO: Remove these. Whatever albums we want to keep should be at the top level
        for item in ["➕New Album"]{
            albumNames.append(item)
        }
        println(albumNames)
    }
    
    

    
    func prepareToDismissVc(){
        println("preparing to dismiss!")
        let pvc = self.presentingViewController
        self.dismissViewControllerAnimated(false, completion: {() -> Void in
            
            if pvc?.restorationIdentifier == "InboxViewController" {
                println("avc")
                let ivc = pvc as! InboxViewController
                ivc.flashConfirm()
                ivc.dismissTopCard()
                ivc.cardStackView.updateStack()
                ivc.fetchL8rs()
            }
            else if pvc?.restorationIdentifier == "ViewController" {
                println("camera presented")
                let vc = pvc as! ViewController
                let pageVc = vc.childViewControllers[0] as! UIPageViewController
                let cc = pageVc.childViewControllers[0] as! CameraController
                cc.flashConfirm()
                cc.previewLayer?.connection.enabled = true
                //TODO: Put this inside flashConfirm
                //TODO: Decide what to do with textView
                cc.addTextView()
                
                
            }
            else {
                println(pvc?.restorationIdentifier)
                
            }
            
        })
        
    }
    
    //MARK: - L8R Management
    
    func scheduleL8rWithDate(scheduledDate: NSDate){
        
        dispatch_async(dispatch_get_main_queue(), {   ()->Void in
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.managedContext = appDelegate.managedObjectContext!
            
            
            let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: self.managedContext)
//            let l8r = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: self.managedContext)
//            
//            
//            
//            
//            let imageData = UIImageJPEGRepresentation(self.image, 0)
//            l8r.setValue(imageData, forKey: "imageData")
//            l8r.setValue(scheduledDate, forKey: "fireDate")
            
            // let l8r = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: self.managedContext)
            // let imageData = UIImageJPEGRepresentation(self.image, 0)
            // l8r.setValue(imageData, forKey: "imageData")
            // l8r.setValue(scheduledDate, forKey: "fireDate")
            
            let l8rItem:L8R = NSEntityDescription.insertNewObjectForEntityForName("L8R", inManagedObjectContext: self.managedContext) as! L8R
            let imageData = UIImageJPEGRepresentation(self.image, 0)
            l8rItem.imageData = imageData
            l8rItem.fireDate = scheduledDate
            
            var error: NSError?
            if !self.managedContext.save(&error) {
                println("Coulnd't save \(error), \(error?.userInfo)")
            }
            let vc = appDelegate.window!.rootViewController as! ViewController
            vc.scheduleLocalNotificationWithFireDate(scheduledDate)
            vc.updateInboxCount()

        })
        
    }
    
    
    func getDatePickerDate(sender: UIButton){
        var scheduledDate = datePicker.date
        self.scheduleL8rWithDate(scheduledDate)
        //Schedule L8R
        self.prepareToDismissVc()
    }
    

    //MARK: - Delegate Methods
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = UIColor.clearColor()
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = bgView
        cell.backgroundView = nil
        cell.backgroundColor = UIColor.clearColor()
        
        //Blue for Album
    }
    

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return snoozeNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "mycell")
        
        
        //cell.textLabel?.font = UIFont(name: "Arial-BoldMT", size: 24)
        cell.textLabel?.font = UIFont(name: "Dosis-Bold", size: 24)
        cell.textLabel?.textColor = UIColor.whiteColor()//(red: 0, green: 206/255, blue: 1, alpha: 1)
        cell.textLabel!.text = snoozeNames[indexPath.row]
        
        cell.textLabel?.layer.shadowColor = UIColor.blackColor().CGColor
        cell.textLabel?.layer.shadowOffset = CGSizeMake(2.0, 2.0)
        
        cell.textLabel!.layer.shadowRadius = 3.0
        cell.textLabel!.layer.shadowOpacity = 1
        
        return cell
        
    }
    
    func showCreateAlbumAlert(){
        
        let alert = UIAlertView(title: "Give the album a name", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
        alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        alert.show()
        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter Name"
//        message:@"  "
//        delegate:self
//        cancelButtonTitle:@"Cancel"
//        otherButtonTitles:@"OK", nil];
//        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//        [alert show];
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            let albumName = alertView.textFieldAtIndex(0)?.text
            let photoLibrary = ALAssetsLibrary()
            var groupToAddTo: ALAssetsGroup = ALAssetsGroup()
            
            photoLibrary.addAssetsGroupAlbumWithName(albumName, resultBlock: {(group: ALAssetsGroup?) -> Void in
                if group == nil {
                    println("group is nil because it already exists")
                }
                else {
                    println("We've just created group \(group)")
                    
                }
                
            }, failureBlock: {(theError: NSError?) -> Void in
                    println(theError)
            })
            snoozeNames.append(albumName!)
            tableView.reloadData()

            
        }
        else {
            println("button index: \(buttonIndex)")
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(snoozeNames[indexPath.row])
        
        if self.snoozeNames[indexPath.row] == "➕New Album"{
            println("create new album")
            self.showCreateAlbumAlert()
        
        }
        

        else if viewToShow == "album" {
        
            //TODO: Create Album if one doesn't exist already
            
            let photoLibrary = ALAssetsLibrary()
            var groupToAddTo: ALAssetsGroup = ALAssetsGroup()
            
            photoLibrary.addAssetsGroupAlbumWithName(self.snoozeNames[indexPath.row], resultBlock: {(group: ALAssetsGroup?) -> Void in
                    if group == nil {
                        println("group is nil because it already exists. Just save it")
                        //enumerate albums
                        photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
                            usingBlock: {
                                (existingGroup: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                                
                                if existingGroup != nil {
                                    
                                    if existingGroup.valueForProperty(ALAssetsGroupPropertyName).isEqualToString(self.snoozeNames[indexPath.row]){
                                        println("Saving to existing group: \(existingGroup.valueForProperty(ALAssetsGroupPropertyName))")
                                        photoLibrary.writeImageToSavedPhotosAlbum(self.image.CGImage, metadata: nil, completionBlock: {
                                            (assetUrl: NSURL!, error: NSError!) -> Void in
                                            
                                            photoLibrary.assetForURL(assetUrl, resultBlock: { (asset: ALAsset!) -> Void in
                                                existingGroup.addAsset(asset)
                                                println("saved to \(existingGroup.valueForProperty(ALAssetsGroupPropertyName))")
                                                return
                                                }, failureBlock: {
                                                    (myerror: NSError!) -> Void in
                                                    println("error occurred: \(myerror.localizedDescription)")
                                            })
                                            })

                                    return
                                    }
                                }
                                else {
                                    println("existing group is nil for some reason")
                                }
                
                            },
                            failureBlock: {
                                (myerror: NSError!) -> Void in
                                println("error occurred: \(myerror.localizedDescription)")
                        })
                    }
                    else {
                        println("We've just created group \(group)")
                        photoLibrary.writeImageToSavedPhotosAlbum(self.image.CGImage, metadata: nil, completionBlock: {
                            (assetUrl: NSURL!, error: NSError!) -> Void in
                            
                            photoLibrary.assetForURL(assetUrl, resultBlock: { (asset: ALAsset!) -> Void in
                                group?.addAsset(asset)
                                println("saved to \(group?.valueForProperty(ALAssetsGroupPropertyName))")
                                return
                                }, failureBlock: {
                                    (myerror: NSError!) -> Void in
                                    println("error occurred: \(myerror.localizedDescription)")
                            })
                        })


                    }
                
                    }, failureBlock: {(theError: NSError?) -> Void in
                        println(theError)
                })
            self.prepareToDismissVc()
        }
            
                
        else if (viewToShow == "snooze"){
            
            //        albumNames = ["Pick Date", "1 Year", "Next Month", "Next Week", "Tomorrow", "1 Hour", "In a Minute", "Add to Album >"]
            
            let snoozeOptionPicked = self.snoozeNames[indexPath.row]
            println(snoozeOptionPicked)
            
            let currentTime = NSDate()
            var theCalendar = NSCalendar.currentCalendar()
            let timeComponent = NSDateComponents()
            
            if snoozeOptionPicked == "📅Pick Date" { // calendar
                //open calendar
                tableView.hidden = true
                self.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
                datePicker = UIDatePicker(frame: self.view.frame)
                datePicker.center.y = self.view.center.y
                self.view.addSubview(datePicker)
                
                let confirmButton = UIButton(frame: CGRectMake(0, 200, 100, 100))
                confirmButton.center.x = self.view.center.x
                confirmButton.center.y = datePicker.frame.maxY+60
                confirmButton.setImage(UIImage(named: "pickDateButton"), forState: .Normal)
                confirmButton.tag = 777
                confirmButton.addTarget(self, action: Selector("getDatePickerDate:"), forControlEvents: .TouchUpInside)
                self.view.addSubview(confirmButton)
            }
                
            else if snoozeOptionPicked == "Add to Album >" {
                println("trying to push to Album Names")
                let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
                avc.image = self.image
                avc.viewToShow = "album"
                println(avc.image)
                println(albumNames)
               // avc.tableView = nil

                avc.snoozeNames = albumNames
                self.navigationController?.pushViewController(avc, animated: true)
                //dumb thing we have to do bc of clearColor bg
                UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseOut,
                    animations: { () -> Void in
                        self.view.alpha = 0
                        
                    }, completion: { (done: Bool) -> Void in
                        UIView.animateWithDuration(0.1, delay: 0.5, options: nil, animations: { () -> Void in
                        self.view.alpha = 1
                            }, completion: { (done: Bool) -> Void in
                                println("animation complete")
                        })
                })

                
                
            }

            else {
                
                var scheduledDate: NSDate!
            
                if snoozeOptionPicked == "🌅Tomorrow" { // tomorrow
                    
                    timeComponent.day = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                else if snoozeOptionPicked == "Next Week" { // next week
                    timeComponent.day = 7
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "⏳In a Minute" { // In a Minute
                   // scheduledDate = NSDate()
                    timeComponent.second = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "⏰1 Hour" { // in an hour
                    timeComponent.hour = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "Next Month" { //in a month
                    timeComponent.month = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "🎂In a Year" { // in a year
                    timeComponent.year = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                

                

                //Schedule L8R
                self.scheduleL8rWithDate(scheduledDate)
                self.prepareToDismissVc()
            }
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}