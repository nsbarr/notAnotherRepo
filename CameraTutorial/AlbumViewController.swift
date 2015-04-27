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


class AlbumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - variables
    
    var albumNames = [String]()
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
            self.getListOfAlbums()

            tableView = UITableView(frame: CGRectMake(0,60,self.view.frame.width,self.view.frame.height-240), style: UITableViewStyle.Plain)
            self.tableView.delegate=self;
            self.tableView.dataSource=self;
            tableView.tableFooterView = UIView(frame: CGRectZero)
            tableView.separatorColor = UIColor.clearColor()
            
            self.view.addSubview(tableView)
            tableView.reloadData()
        
        }

        
        else if viewToShow == "snooze"{
            self.getListOfSnoozeOptions()
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
        
        albumNames = ["Pick Date", "1 Year", "Next Month", "Next Week", "Tomorrow", "1 Hour", "In a Minute", "When I get home"]
        
    }
    
    
    func getListOfAlbums(){
        
        
        photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
            usingBlock: {
                (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if group != nil {
                    let albumName = group.valueForProperty(ALAssetsGroupPropertyName) as String
                    if !((albumName == "Snapchat") || (albumName == "Instagram") || (albumName == "Adobe Shape CC") || (albumName == "Seene") || (albumName == "💡 Inspiration") || (albumName == "🎥 To Watch") || albumName == "📖 To Read"){
                        self.albumNames.append(albumName)
                    }
                    
                    group.enumerateAssetsUsingBlock({
                        (asset: ALAsset!, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                        //  println(asset)
                    })
                }
            },
            failureBlock: {
                (myerror: NSError!) -> Void in
                println("error occurred: \(myerror.localizedDescription)")
        })
        for item in ["💡 Inspiration", "🎥 To Watch", "📖 To Read"]{
            albumNames.insert(item, atIndex: 0)
        }
      //  self.curateAlbumListFrom(albumNames)
    }
    
    
    func curateAlbumListFrom(listOfAlbums: [String]){
        var newListOfAlbums = [String]()
        for (index, element) in enumerate(listOfAlbums) {
            
            
            if !((element == "Snapchat") || (element == "Instagram") || (element == "Adobe Shape CC") || (element == "Seene")){
                println("didn't add element: \(element)")
            }
            else {
                newListOfAlbums.append(element)
                println("added element: \(element)")
            }
        }
        
        for item in ["💡 Inspiration", "🎥 To Watch", "📖 To Read"]{
            newListOfAlbums.insert(item, atIndex: 0)
        }
        albumNames = newListOfAlbums
        
    }
    
    func prepareToDismissVc(){
        println("preparing to dismiss!")
        let pvc = self.presentingViewController
        self.dismissViewControllerAnimated(false, completion: {() -> Void in
            
            if pvc?.restorationIdentifier == "InboxViewController" {
                println("avc")
                let ivc = pvc as InboxViewController
                ivc.flashConfirm()
                ivc.dismissTopCard()
            }
            else if pvc?.restorationIdentifier == "ViewController" {
                println("camera presented")
                let vc = pvc as ViewController
                let pageVc = vc.childViewControllers[0] as UIPageViewController
                let cc = pageVc.childViewControllers[0] as CameraController
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
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        managedContext = appDelegate.managedObjectContext!
        let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: managedContext)
        let l8r = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        let imageData = UIImageJPEGRepresentation(self.image, 0)
        l8r.setValue(imageData, forKey: "imageData")
        l8r.setValue(scheduledDate, forKey: "fireDate")
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Coulnd't save \(error), \(error?.userInfo)")
        }
        
        let vc = appDelegate.window!.rootViewController as ViewController
        vc.scheduleLocalNotificationWithFireDate(scheduledDate)
        vc.updateInboxCount()
        
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
        cell.backgroundView = nil
        cell.backgroundColor = UIColor.clearColor()
        
        //Gray out when I get home
        if indexPath.row == 7 && viewToShow == "snooze"{
            cell.textLabel?.textColor = UIColor.grayColor()
            println("disabled")
        }
        else {
            println("index:\(indexPath), text:\(cell.textLabel)")
        }
    }
    

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "mycell")
        
        if viewToShow == "album" {
        
            cell.textLabel?.font = UIFont(name: "Arial-BoldMT", size: 24)
            cell.textLabel?.textColor = UIColor(red: 0, green: 206/255, blue: 1, alpha: 1)
            cell.textLabel!.text = albumNames[indexPath.row]
            
            cell.textLabel?.layer.shadowColor = UIColor.blackColor().CGColor
            cell.textLabel?.layer.shadowOffset = CGSizeMake(0.0, 0.0)
            
            cell.textLabel!.layer.shadowRadius = 3.0
            cell.textLabel!.layer.shadowOpacity = 1
        }
        
        else if viewToShow == "snooze" {
            cell.textLabel?.font = UIFont(name: "Arial-BoldMT", size: 24)
            cell.textLabel?.textColor = UIColor(red: 252/255, green: 250/255, blue: 0, alpha: 1)
            cell.textLabel!.text = albumNames[indexPath.row]
            cell.textLabel?.textAlignment = NSTextAlignment.Right
            cell.textLabel?.layer.shadowColor = UIColor.blackColor().CGColor
            cell.textLabel?.layer.shadowOffset = CGSizeMake(0.0, 0.0)
            
            cell.textLabel!.layer.shadowRadius = 3.0
            cell.textLabel!.layer.shadowOpacity = 1
        }
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(albumNames[indexPath.row])
        
        
        if viewToShow == "album" {
        
            //TODO: Create Album if one doesn't exist already
            
            let photoLibrary = ALAssetsLibrary()
            var groupToAddTo: ALAssetsGroup = ALAssetsGroup()
            
            photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
                usingBlock: {
                    (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                    println(group)
                    
                    if group != nil {
                        if group.valueForProperty(ALAssetsGroupPropertyName).isEqualToString(self.albumNames[indexPath.row]){
                            groupToAddTo = group
                        }
                    }
                    else {
                        println("group is nil")
                        println(groupToAddTo.valueForProperty(ALAssetsGroupPropertyName))
                    }
                },
                failureBlock: {
                    (myerror: NSError!) -> Void in
                    println("error occurred: \(myerror.localizedDescription)")
            })
            
            if groupToAddTo.valueForProperty(ALAssetsGroupPropertyName) == nil {
                println("album doesn't exist yet")
                photoLibrary.addAssetsGroupAlbumWithName(self.albumNames[indexPath.row], resultBlock: {(group: ALAssetsGroup?) -> Void in
                    if group != nil {
                        groupToAddTo = group!
                    }
                    
                    }, failureBlock: {(theError: NSError?) -> Void in
                        println(theError)
                })
            }
            
            photoLibrary.writeImageToSavedPhotosAlbum(self.image.CGImage, metadata: nil, completionBlock: {
                (assetUrl: NSURL!, error: NSError!) -> Void in
                if error == nil {
                    println("saved image completed: \(assetUrl)")
                    
                    photoLibrary.assetForURL(assetUrl, resultBlock: { (asset: ALAsset!) -> Void in
                        groupToAddTo.addAsset(asset)
                        return
                        }, failureBlock: {
                            (myerror: NSError!) -> Void in
                            println("error occurred: \(myerror.localizedDescription)")
                    })
                } else {
                    println("saved image failed. \(error.localizedDescription) code \(error.code)")
                }
            } )
            self.prepareToDismissVc()

        }
        
        else if (viewToShow == "snooze") && (indexPath.row != 7) {
            
            //        albumNames = ["Pick Date", "1 Year", "Next Month", "Next Week", "Tomorrow", "1 Hour", "In a Minute", "When I get home"]
            
            let snoozeOptionPicked = self.albumNames[indexPath.row]
            println(snoozeOptionPicked)
            
            let currentTime = NSDate()
            var theCalendar = NSCalendar.currentCalendar()
            let timeComponent = NSDateComponents()
            
            if snoozeOptionPicked == "Pick Date" { // calendar
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
            else {
                
                var scheduledDate: NSDate!
            
                if snoozeOptionPicked == "Tomorrow" { // tomorrow
                    
                    timeComponent.day = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                else if snoozeOptionPicked == "Next Week" { // next week
                    timeComponent.day = 7
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "In a Minute" { // In a Minute
                   // scheduledDate = NSDate()
                    timeComponent.minute = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "1 Hour" { // in an hour
                    timeComponent.hour = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "Next Month" { //in a month
                    timeComponent.month = 1
                    scheduledDate = theCalendar.dateByAddingComponents(timeComponent, toDate: currentTime, options: NSCalendarOptions(0))
                }
                    
                else if snoozeOptionPicked == "1 Year" { // in a year
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