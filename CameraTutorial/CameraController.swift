//
//  CameraController.swift
//  L8R
//


import UIKit
import AVFoundation
import CoreData
import Foundation
import AssetsLibrary


class CameraController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // MARK: - Variables
    
    var snapButton: UIButton!
    var flipButton: UIButton!
    var textButton: UIButton!
    
    var attr = [String:NSObject]()
    let session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var textView: UITextView!
    var tempView: UIView!
    var listOfAlbumNames = [String]()
    
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    
    var textToSave = NSString()
    
    var image: UIImage!
    
    var nc: UINavigationController!

    
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
    
    var l8rs = [NSManagedObject]()
    var l8rCount = Int()
    
    @IBOutlet weak var tableView: UITableView!
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        println("new branch")
        super.viewDidLoad()
        self.determinePermissions()
        self.setUpCamera()
        self.addLaterSnapButton()
        self.addListSnapButton()
        self.addTextView()

        self.addFlipButton()
        self.addTextButton()
        self.addImagePickerButton()
        self.addInboxBadge()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        previewLayer?.connection.enabled = true
        textToSave = ""


    }
    
    // MARK: - Set up the Camera
    
    func determinePermissions(){
        let status = ALAssetsLibrary.authorizationStatus()
        
        switch (status) {
        case ALAuthorizationStatus.Authorized:
            println("authorized")
            break
            
        case ALAuthorizationStatus.Denied:
            println("denied")
            break
            
        case ALAuthorizationStatus.NotDetermined:
            println("no idea")
            
            let photoLibrary = ALAssetsLibrary()
            photoLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAlbum),
                usingBlock: {
                    (group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                    if group != nil {
//                        group.enumerateAssetsUsingBlock({
//                            (asset: ALAsset!, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
//                            //  println(asset)
//                        })
                    }
                },
                failureBlock: {
                    (myerror: NSError!) -> Void in
                    println("error occurred: \(myerror.localizedDescription)")
            })

            break
        default:
            println("default")
            break
        }
    }
    
    func setUpCamera(){
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
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
                currentInput = backCameraInput
                self.session.addInput(currentInput)
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
        previewLayer?.connection.enabled = true

        
    }
    
    //MARK: - Add and configure capture button
    
    func addTextView(){
        
        if textView != nil {
            textView.removeFromSuperview()
        }
        
        textView = UITextView(frame: CGRectMake(0, 80, self.view.frame.width, self.view.frame.height-200))
        textView.backgroundColor = UIColor.clearColor()
        textView.returnKeyType = UIReturnKeyType.Done
        textView.delegate = self
        
        let font = UIFont(name: "Dosis-Bold", size: 42.0)!
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        textStyle.alignment = NSTextAlignment.Center
        let textColor = UIColor.whiteColor()
        
        var shadow = NSShadow()
        shadow.shadowColor = UIColor.blackColor()
        shadow.shadowOffset = CGSizeMake(2.0,2.0)
        
        attr = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: textStyle,
            NSShadowAttributeName: shadow
        ]
  //      let placeholderText = NSMutableAttributedString(string:"", attributes: attr as [NSObject: AnyObject]?)
        let placeholderText = NSAttributedString(string: " ", attributes: attr)
        textView.attributedText = placeholderText
        textView.textAlignment = .Center
        textView.text = ""
        textView.textContainerInset = UIEdgeInsets(top: self.view.center.y-200, left: 0, bottom: 0, right: 0)
        let offset:CGPoint = self.view.center
        textView.contentOffset = offset
        
        let pan = UIPanGestureRecognizer(target: self, action: Selector("handlePan:"))
        textView.addGestureRecognizer(pan)
        //  textView.font = UIFont(name: "Arial-BoldMT", size: 36)
        //  textView.textColor = UIColor.whiteColor()
      //  tempView = UIView(frame: self.view.frame)
      //  tempView.addSubview(textView)
        self.view.addSubview(textView)
        self.view.insertSubview(textView, belowSubview: snapButton)
    }
    
    func handlePan(sender: UIPanGestureRecognizer){
        let touchLocation = sender.locationInView(self.view)
        //let translation = sender.translationInView(self.view)
        self.textView.center = touchLocation
     //   self.textView.center = CGPointMake(translation.x, translation.y)
     //   sender.setTranslation(CGPointMake(0.0,0.0), inView: self.view)
    }
    

    
    func addLaterSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-120, width: 100, height: 100))
        snapButton.center.x = view.center.x
        snapButton.tag = 0
        let buttonImage = UIImage(named: "laterSnapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        snapButton.hidden = false
        
        view.addSubview(snapButton)
        
    }
    
    func addListSnapButton(){
        var listSnapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-120, width: 100, height: 100))
        listSnapButton.center.x = view.center.x-(listSnapButton.frame.width/2+30)
        listSnapButton.tag = 1234
        let buttonImage = UIImage(named: "listSnapButton")
        listSnapButton.setImage(buttonImage, forState: .Normal)
        listSnapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        listSnapButton.hidden = false
        
     //   view.addSubview(listSnapButton)
    }
    
    
    
    func addFlipButton(){
        flipButton = UIButton(frame: CGRectMake(10, 20, 40, 40))
        flipButton.setTitle("😎", forState: .Normal)
        flipButton.setTitle("🌎", forState: .Selected)
      //  flipButton.setImage(UIImage(named: "flipButton"), forState: .Normal)
        flipButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
        flipButton.addTarget(self, action: Selector("toggleCamera:"), forControlEvents: .TouchUpInside)
        flipButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        flipButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        flipButton.titleLabel!.layer.shadowOpacity = 1
        flipButton.titleLabel!.layer.shadowRadius = 1
     //   flipButton.sizeToFit()

        view.addSubview(flipButton)
    }
    
    
    func addInboxBadge(){
        
        let inboxFrame = UIButton(frame:CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxFrame.addTarget(self, action: Selector("inboxButtonPressed:"), forControlEvents: .TouchUpInside)
        //   inboxFrame.setImage(UIImage(named: "inboxFrame"), forState: .Normal)
        
        
        let inboxNumber = UILabel(frame: CGRectMake(self.view.frame.width - 44, 20, 40, 40))
        inboxNumber.font = UIFont(name: "Arial-BoldMT", size: 32)
        inboxNumber.text = "🌴"
        inboxNumber.textAlignment = .Center
        inboxNumber.textColor = UIColor.whiteColor()
        inboxNumber.layer.shadowColor = UIColor.blackColor().CGColor
        inboxNumber.layer.shadowOffset = CGSizeMake(0, 1)
        inboxNumber.layer.shadowOpacity = 1
        inboxNumber.layer.shadowRadius = 1
        self.view.addSubview(inboxFrame)
        self.view.addSubview(inboxNumber)
    }
    
    func addImagePickerButton(){
        var imagePickerButton = UIButton(frame: CGRect(x: 70, y: 20, width: 40, height: 40))
        imagePickerButton.setImage(UIImage(named: "imageGalleryButton"), forState: .Normal)
        imagePickerButton.addTarget(self, action: Selector("imagePickerButtonPressed:"), forControlEvents: .TouchUpInside)
        imagePickerButton.enabled = true // doesn't work yet
        imagePickerButton.alpha = 1
        imagePickerButton.tag = 101
      //  view.addSubview(imagePickerButton)
    }
    
    
    func addTextButton(){
        
        if textButton != nil {
            textButton.removeFromSuperview()
        }
        textButton = UIButton(frame: CGRect(x: 130, y: 20, width: 40, height: 40))
        textButton.center.x = self.view.center.x
        textButton.setImage(UIImage(named: "altAddTextButton"), forState: .Normal)
        textButton.addTarget(self, action: Selector("openKeyboard:"), forControlEvents: .TouchUpInside)
        textButton.tag = 101

        view.addSubview(textButton)
    }
    
    func openKeyboard(sender: UIButton){
        textView.becomeFirstResponder()
    }
    
    
    
    func openTransparentModal(sender: UIButton){
        
        //instantiate vc from storyboard
        //make vc.view blureffect
        
        if sender.tag == 1234 {
            //show snooze view
        }
        
    }
    

    
    
    func snapButtonPressed(sender: UIButton){
        println("snapped")
        
        self.previewLayer?.connection.enabled = false
        self.takeScreenSnapshotFromButton(sender)
    

    }
    
    func takeScreenSnapshotFromButton(sender: UIButton){
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    println("should be disabling connection...")
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    //TODO: Reduce image size here maybe? Or at least make them the same size.
                    if let theImage = UIImage(data: imageData) {
                        
                        //TODO: figure out low image quality
                        
                        //let imageView = UIImageView(frame: CGRectMake(0, 0, theImage.size.width*self.view.frame.height/theImage.size.height, self.view.frame.height))
                        
                        let imageView = UIImageView(frame: CGRectMake(0, 0, theImage.size.width*self.view.frame.height/theImage.size.height, self.view.frame.height))
                        
                        if !self.currentDeviceIsBack {
                            imageView.image = UIImage(CGImage: theImage.CGImage, scale: theImage.scale, orientation: UIImageOrientation.LeftMirrored)
                        }
                        else {
                            imageView.image = theImage
                        }
                        self.textView.frame.origin.x = self.textView.frame.origin.x + (imageView.frame.width-self.view.frame.width)/2
                        imageView.contentMode = UIViewContentMode.ScaleToFill
                        imageView.addSubview(self.textView)
                        
                        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.opaque, 0.0)
                        imageView.layer.renderInContext(UIGraphicsGetCurrentContext())
                        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        self.image = snapshotImage
                        //TODO: we shouldn't have to wait for the snapshot to bring up the modal
                        self.bringUpSnapModalFromButton(sender)
                    }
                }
                    
                else {
                    NSLog("error while capturing still image: \(error)")
                }
            }
        }
    }
    
    func bringUpSnapModalFromButton(sender: UIButton){
            
            let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
            avc.image = self.image
            avc.viewToShow = "snooze"
            
            let nc = UINavigationController(rootViewController: avc)
            nc.navigationBar.hidden = true
            nc.modalPresentationStyle = .OverCurrentContext
            
            presentViewController(nc, animated: true, completion: nil)
            
    }
    
    
    func toggleCamera(sender: UIButton) {
        
        if currentDeviceIsBack {
            var error:NSError?
            let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(frontCameraDevice, error: &error)
            if let frontCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
                    self.session.beginConfiguration()
                    self.session.removeInput(currentInput)
                    currentInput = frontCameraInput
                    self.session.addInput(currentInput)
                    self.session.commitConfiguration()
                currentDeviceIsBack = false
                sender.selected = !sender.selected
            }
            else {
                println("front camera not possible i guess?")
            }
        }
        else {
            var error:NSError?
            let possibleCameraInput: AnyObject? = AVCaptureDeviceInput.deviceInputWithDevice(backCameraDevice, error: &error)
            if let backCameraInput = possibleCameraInput as? AVCaptureDeviceInput {
                self.session.beginConfiguration()
                self.session.removeInput(currentInput)
                currentInput = backCameraInput
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                currentDeviceIsBack = true
                sender.selected = !sender.selected
            }
            else {
                println("back camera not possible i guess?")
            }

        }

    }
    
    func imagePickerButtonPressed(sender: UIButton){
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = false
        
        self.presentViewController(imagePicker, animated: true,
            completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        picker.dismissViewControllerAnimated(true, completion: nil)
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
            flashConfirm.frame = CGRectMake(self.view.frame.midX, self.view.frame.midY, 0, 0)
            }, completion: nil)
        
    }

    
    func inboxButtonPressed(sender:UIButton){
        let ivc = self.storyboard!.instantiateViewControllerWithIdentifier("InboxViewController") as! InboxViewController
        self.presentViewController(ivc, animated: false, completion: nil)
    }
    

    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            let pvc = self.parentViewController?.parentViewController as! ViewController
         //   pvc.toggleTriggerButtonVisibility(pvc.triggerToggleButton)
            return false
        }
        return true
    }
    
    
    func textViewDidEndEditing(textView: UITextView) {
        var newFrame = textView.frame
        var originalCenter = textView.center
     //   newFrame.size.height = textView.contentSize.height
        textView.frame = newFrame
        textView.center = originalCenter
        
     //   textView.layer.borderColor = UIColor.redColor().CGColor
     //   textView.layer.borderWidth = 2.0
        
        
        //  textToSave = textView.text
      //  let originalCenter = textView.center
      //  textView.sizeThatFits(self.view.frame.size)
     //   textView.sizeToFit()
     //   textView.center = originalCenter
        //textView.frame.origin = origin
        println(textToSave)
    }

}
