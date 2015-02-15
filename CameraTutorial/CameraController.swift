//
//  PageItemController.swift
//  Paging_Swift
//
//  Created by Olga Dalton on 26/10/14.
//  Copyright (c) 2014 swiftiostutorials.com. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class CameraController: UIViewController {
    
    var snapButton: UIButton!
//    var inboxButton: UIButton!
//    var inboxNumber: UILabel!

    var dateButton: UIButton!
    var scheduleButton: UIButton!
    var deleteButton: UIButton!
    
    let session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
    
    var l8rs = [NSManagedObject]()
    var l8rCount = Int()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as [AVCaptureDevice] {
            if device.position == .Back {
                backCameraDevice = device
            }
            else if device.position == .Front {
                frontCameraDevice = device
            }
        }
        
        var error:NSError?
        let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(backCameraDevice, error: &error)
        if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
            if self.session.canAddInput(backCameraInput) {
                self.session.addInput(backCameraInput)
            }
        }
        
        stillCameraOutput = AVCaptureStillImageOutput()
        
        if self.session.canAddOutput(self.stillCameraOutput) {
            self.session.addOutput(self.stillCameraOutput)
        }
        
        //this auto-handles focus, WB, exposure, etc.
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        dispatch_async(sessionQueue) { () -> Void in
            self.session.startRunning()
        }
        
        self.addSnapButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: "L8R")
        
        var error: NSError?
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
        
        if let results = fetchedResults {
            l8rs = results
            l8rCount = l8rs.count
            println("Number of l8rs:\(l8rs.count)")
            
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    func addSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-100, width: 80, height: 80))
        snapButton.center.x = view.center.x
        let buttonImage = UIImage(named: "snapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchUpInside)
        view.addSubview(snapButton)
        
        dateButton = UIButton(frame: CGRectMake(20, self.view.frame.height-60, 116, 42))
        dateButton.addTarget(self, action: Selector("openDateMenu:"), forControlEvents: UIControlEvents.TouchUpInside)
        dateButton.center.x = self.view.center.x
        let dateButtonImage = UIImage(named: "tomorrowButton")
        dateButton.setImage(dateButtonImage, forState: .Normal)
        dateButton.hidden = true
        view.addSubview(dateButton)
        
        scheduleButton = UIButton(frame: CGRectMake(self.view.frame.width-78, self.view.frame.height-60, 58, 42))
        scheduleButton.addTarget(self, action: Selector("scheduleL8r:"), forControlEvents: UIControlEvents.TouchUpInside)
        let scheduleButtonImage = UIImage(named: "scheduleButton")
        scheduleButton.setImage(scheduleButtonImage, forState: .Normal)
        scheduleButton.hidden = true
        view.addSubview(scheduleButton)
        
        deleteButton = UIButton(frame: CGRectMake(20, self.view.frame.height-60, 42, 42))
        deleteButton.addTarget(self, action: Selector("deleteL8r:"), forControlEvents: UIControlEvents.TouchUpInside)
        let deleteButtonImage = UIImage(named: "deleteButton")
        deleteButton.setImage(deleteButtonImage, forState: .Normal)
        deleteButton.hidden = true
        view.addSubview(deleteButton)
    }
    
    func openInbox(sender: UIButton){
        
    }
    
    func openDateMenu(sender: UIButton){
        
    }
    
    func deleteL8r(sender: UIButton){
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "L8R")
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
        if let results = fetchedResults {
            l8rs = results
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        managedContext.deleteObject(l8rs[l8rs.count-1])
        println("just deleted a l8r")
        
        previewLayer?.connection.enabled = true
        self.swapInNewButtons()
        
    }
    
    
    func scheduleL8r(sender: UIButton){
        self.swapInNewButtons()
        self.previewLayer?.connection.enabled = true
    }
    
    
    func snapButtonPressed(sender: UIButton){
        println("snapped")
        
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            // update the video orientation to the device one
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    
                    // if the session preset .Photo is used, or if explicitly set in the device's outputSettings we get the data already compressed as JPEG
                    
                    // freeze display
                    self.previewLayer?.connection.enabled = false
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    
                    // the sample buffer also contains the metadata, in case we want to modify it
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    let currentDate = NSDate()
                    
                    
                    if let image = UIImage(data: imageData) {
                        // save the image or do something interesting with it
                        
                        self.saveImageWithData(imageData, fireDate:currentDate)
                        self.swapInNewButtons()
                        //  do this if you want to save the Image
                        //  UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        
                        //problems with this: 1) delay, 2) image is not saved at view bounds
                        //                        let imageView = UIImageView(frame:self.view.frame)
                        //                        imageView.image = image
                        //                        self.view.addSubview(imageView)
                        
                    }
                }
                else {
                    NSLog("error while capturing still image: \(error)")
                }
            }
        }
    }
    
    func saveImageWithData(data:NSData, fireDate:NSDate){
        //   println("l8r data:\(data)")
        //   println("l8r fireData:\(fireDate)")
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        let entity = NSEntityDescription.entityForName("L8R", inManagedObjectContext: managedContext)
        
        let l8r = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        l8r.setValue(data, forKey: "imageData")
        l8r.setValue(fireDate, forKey: "fireDate")
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Coulnd't save \(error), \(error?.userInfo)")
        }
        
        l8rs.append(l8r)
    }
    
    func swapInNewButtons(){
        
        for button in [snapButton, scheduleButton, dateButton, deleteButton] {
            button.hidden = !button.hidden
        }
        
        
    }
}
