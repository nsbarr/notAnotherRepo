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

class AlbumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var albumNames = [String]()
    var image = UIImage()
    var viewToShow: String = "nil"
    var tableView: UITableView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        if tableView != nil {
            tableView.reloadData()
        }
        //WHYYYY
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        view.frame = self.presentingViewController!.view.frame

        self.displayTheRightView()

        println(albumNames)
        
        
        
    }
    
    func displayTheRightView(){
        
        if viewToShow == "album"{
            self.getListOfAlbums()

            tableView = UITableView(frame: self.view.frame, style: UITableViewStyle.Plain)
            self.tableView.delegate=self;
            self.tableView.dataSource=self;

            self.view.addSubview(tableView)
            tableView.reloadData()
        
        }
        else if viewToShow == "calendar"{
            println("cal")
            let datePicker = UIDatePicker(frame: self.view.frame)
            datePicker.center.y = self.view.center.y
            self.view.addSubview(datePicker)
            
            let confirmButton = UIButton(frame: CGRectMake(0, 200, 116, 42))
            confirmButton.center.x = self.view.center.x
            confirmButton.setImage(UIImage(named: "pickDateButton"), forState: .Normal)
            confirmButton.tag = 777
            confirmButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: .TouchUpInside)
            self.view.addSubview(confirmButton)
        
        }
        
        else if viewToShow == "snooze"{
            let triggerButtons = ["👋\nSeeya!", "📅\nCal", "🚀\n1 Year", "🚙\n1 Week", "☀️\nTmrw", "⏳\n1 Hour"]
            let triggerButtonTags = [86, 666, 365, 7, 1, 60]
            var buttonTag = 0
            let triggerButtonPadding:CGFloat = 20
            var triggerButtonYPos:CGFloat = self.view.frame.midY
            var triggerButtonXPos:CGFloat = 20
            
            for triggerButtonTitle in triggerButtons {
                var triggerButton = MenuButton(frame: CGRectMake(triggerButtonXPos, triggerButtonYPos, 100, 100))
                triggerButton.setTitle(triggerButtonTitle, forState: .Normal)
                triggerButton.tag = triggerButtonTags[buttonTag]
                triggerButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: UIControlEvents.TouchUpInside)
                // triggerButton.sizeToFit()
                self.view.addSubview(triggerButton)
                if buttonTag < 2 || buttonTag > 2 {
                    triggerButtonXPos = triggerButtonXPos + triggerButton.frame.width + triggerButtonPadding
                }
                else if buttonTag == 2 {
                    triggerButtonXPos = 20
                    triggerButtonYPos = triggerButtonYPos + triggerButton.frame.height + triggerButtonPadding
                }
                buttonTag = buttonTag + 1
            }
        }
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = UIColor.clearColor()
        cell.backgroundView = nil
        cell.backgroundColor = UIColor.clearColor()
    }
    

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "mycell")
        
        cell.textLabel!.text = albumNames[indexPath.row]
        println("b")
        
        return cell
        
    }
    

    
    func getListOfAlbums(){
        println("a")
        
        let photoLibrary = ALAssetsLibrary()
        photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
            usingBlock: {
                (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if group != nil {
                    let albumName = group.valueForProperty(ALAssetsGroupPropertyName) as! String
                    self.albumNames.append(albumName)
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
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(albumNames[indexPath.row])
        
        let photoLibrary = ALAssetsLibrary()
        
        var groupToAddTo: ALAssetsGroup = ALAssetsGroup()
        
        photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
            usingBlock: {
                (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                
                if group != nil {
                    if group.valueForProperty(ALAssetsGroupPropertyName).isEqualToString(self.albumNames[indexPath.row]){
                        groupToAddTo = group
                    }
                }
            },
            failureBlock: {
                (myerror: NSError!) -> Void in
                println("error occurred: \(myerror.localizedDescription)")
        })
        
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
        
        let pvc = self.presentingViewController
        

            self.dismissViewControllerAnimated(true, completion: {() -> Void in
                
                if pvc?.restorationIdentifier == "InboxViewController" {
                    println("avc")
                    let ivc = pvc as! InboxViewController
                    ivc.flashConfirm()
                    ivc.dismissTopCard()
                }
                else if pvc?.restorationIdentifier == "ViewController" {
                    println("camera presented")
                    let vc = pvc as! ViewController
                    let pageVc = vc.childViewControllers[0] as! UIPageViewController
                    let cc = pageVc.childViewControllers[0] as! CameraController
                    cc.flashConfirm()
                    cc.previewLayer?.connection.enabled = true
                
                }
                else {
                    println(pvc?.restorationIdentifier)
                    
                }
                
        })
    
    }
    


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}