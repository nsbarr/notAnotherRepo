//
//  CameraController.swift
//  L8R
//


import UIKit
import AVFoundation
import CoreData

class CameraController: UIViewController, UITextViewDelegate {
    
    
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
        self.setUpCamera()
        self.addTextView()
        self.addLaterSnapButton()
        self.addListSnapButton()
        self.addFlipButton()
        self.addTextButton()
        self.addImagePickerButton()
        self.addInboxBadge()

        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        let pvc = self.parentViewController?.parentViewController as! ViewController
        pvc.cameraButtonsAreHidden(false)
        previewLayer?.connection.enabled = true
        textToSave = ""


    }
    
    // MARK: - Set up the Camera
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
        
        let font = UIFont(name: "Arial-BoldMT", size: 42.0)!
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
        //  textView.font = UIFont(name: "Arial-BoldMT", size: 36)
        //  textView.textColor = UIColor.whiteColor()
      //  tempView = UIView(frame: self.view.frame)
      //  tempView.addSubview(textView)
        self.view.addSubview(textView)
    }
    
    func addLaterSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-120, width: 100, height: 100))
        snapButton.center.x = view.center.x+(snapButton.frame.width/2+5)
        snapButton.tag = 0
        let buttonImage = UIImage(named: "laterSnapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        snapButton.hidden = false
        
        view.addSubview(snapButton)
        
    }
    
    func addListSnapButton(){
        var listSnapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-120, width: 100, height: 100))
        listSnapButton.center.x = view.center.x-(listSnapButton.frame.width/2+5)
        listSnapButton.tag = 1234
        let buttonImage = UIImage(named: "listSnapButton")
        listSnapButton.setImage(buttonImage, forState: .Normal)
        listSnapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        listSnapButton.hidden = false
        
        view.addSubview(listSnapButton)
    }
    
    
    
    func addFlipButton(){
        flipButton = UIButton(frame: CGRectMake(10, 20, 50, 50))
      //  flipButton.setTitle("Flip", forState: .Normal)
        flipButton.setImage(UIImage(named: "flipButton"), forState: .Normal)
        flipButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 24)
        flipButton.addTarget(self, action: Selector("toggleCamera:"), forControlEvents: .TouchUpInside)
        flipButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        flipButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        flipButton.titleLabel!.layer.shadowOpacity = 1
        flipButton.titleLabel!.layer.shadowRadius = 1
     //   flipButton.sizeToFit()

        view.addSubview(flipButton)
    }
    
    func addImagePickerButton(){
        var imagePickerButton = UIButton(frame: CGRect(x: 38, y: view.frame.height-150, width: 52, height: 52))
        imagePickerButton.setImage(UIImage(named: "imagePickerButton"), forState: .Normal)
        imagePickerButton.addTarget(self, action: Selector("openKeyboard:"), forControlEvents: .TouchUpInside)
        imagePickerButton.tag = 101
        view.addSubview(imagePickerButton)
    }
    
    
    func addTextButton(){
        
        if textButton != nil {
            textButton.removeFromSuperview()
        }
        textButton = UIButton(frame: CGRect(x: view.frame.width-90, y: view.frame.height-150, width: 52, height: 52))
        textButton.setImage(UIImage(named: "addTextButton"), forState: .Normal)
        textButton.addTarget(self, action: Selector("openKeyboard:"), forControlEvents: .TouchUpInside)
        textButton.tag = 101



        
//        textButton = UIButton(frame: CGRectMake(view.frame.width-50, view.frame.height-54, 40, 40))
//        textButton.setTitle("Aa", forState: .Normal)
//   
//        textButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 32)
//        textButton.addTarget(self, action: Selector("openKeyboard:"), forControlEvents: .TouchUpInside)
//        textButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
//        textButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
//        textButton.titleLabel!.layer.shadowOpacity = 1
//        textButton.titleLabel!.layer.shadowRadius = 1
//        textButton.sizeToFit()
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
    
    
    

    
    func showAlbumList(sender:UIButton){
        
        
        
        let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
    //    avc.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        avc.image = self.image


        
        
        
        
        avc.modalPresentationStyle = .OverCurrentContext
        self.presentViewController(avc, animated: true, completion: nil)
        
//            vc.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
//            vc.modalPresentationStyle = .OverCurrentContext
//            
//            
//            nc = UINavigationController(rootViewController: vc)
//            nc!.navigationBar.hidden = true
//            nc!.modalPresentationStyle = .OverCurrentContext
//            
//            presentViewController(nc!, animated: false, completion: nil)
        
    }
    
    
    func snapButtonPressed(sender: UIButton){
        println("snapped")
        
        //MARK: - Lifecycle
        //freeze connection
        //capture still image async
        //bring up relevant modal
        
        //(modal is responsible for scheduling or filing the image, unfreezing the connection, and flashing the ani)
        
        
        self.previewLayer?.connection.enabled = false
        
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            // update the video orientation to the device one
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            
            let pvc = self.parentViewController?.parentViewController as! ViewController

            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    println("should be disabling connection...")
                   // pvc.cameraButtonsAreHidden(true)
                    

                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    //TODO: Reduce image size here maybe? Or at least make them the same size.
                    
                    
                    if let theImage = UIImage(data: imageData) {
                        
                        

                        //TODO: figure out low image quality
                        
                        let imageView = UIImageView(frame: CGRectMake(0, 0, theImage.size.width*self.view.frame.height/theImage.size.height, self.view.frame.height))
                        if !self.currentDeviceIsBack {
                            imageView.image = UIImage(CGImage: theImage.CGImage, scale: theImage.scale, orientation: UIImageOrientation.LeftMirrored)
                        }
                        else {
                            imageView.image = theImage
                        }
                        self.textView.frame.origin.x = self.textView.frame.origin.x + (imageView.frame.width-self.view.frame.width)/2
                        imageView.contentMode = UIViewContentMode.ScaleToFill
                        self.textView.removeFromSuperview()
                        self.textView.hidden = false
                        imageView.addSubview(self.textView)



                        println(self.textView)
//                        self.tempView = UIView(frame: self.view.frame)
//                        self.tempView.addSubview(imageView)
                   //     self.textView.removeFromSuperview()
                   //     self.tempView.addSubview(self.textView)
//                        UIGraphicsBeginImageContextWithOptions(tempView.bounds.size, tempView.opaque, 0)
//                        tempView.drawViewHierarchyInRect(tempView.bounds, afterScreenUpdates: false)
//                        let snapShotImage = UIGraphicsGetImageFromCurrentImageContext()
//                        UIGraphicsEndImageContext()
                        
                        
                        
                        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.opaque, 0.0)
                        imageView.layer.renderInContext(UIGraphicsGetCurrentContext())
                        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        self.image = snapshotImage
                        
                        
                        
                        if sender.tag == 1234 {
                            
                            let avc = self.storyboard!.instantiateViewControllerWithIdentifier("AlbumViewController") as! AlbumViewController
                            //    avc.view = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
                            avc.image = self.image
                            avc.viewToShow = "album"
                            
                            avc.modalPresentationStyle = .OverCurrentContext
                            self.presentViewController(avc, animated: true, completion: nil)
                        }
                        
                        else if sender.tag == 0 {
                            
                            pvc.scheduleL8r(self.snapButton)
                            self.flashConfirm()
                            self.previewLayer?.connection.enabled = true
                        }
                        
                        self.addTextView()
                        
                    

                    }
                }
                    
                else {
                    NSLog("error while capturing still image: \(error)")
                }
            }
        }
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
                
            }
            else {
                println("back camera not possible i guess?")
            }

        }

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
    
    func inboxButtonPressed(sender:UIButton){
        let ivc = self.storyboard!.instantiateViewControllerWithIdentifier("InboxViewController") as! InboxViewController
        self.presentViewController(ivc, animated: true, completion: nil)
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
    
    func textViewDidBeginEditing(textView: UITextView) {
        let pvc = self.parentViewController?.parentViewController as! ViewController
    //    pvc.toggleTriggerButtonVisibility(textButton)
        
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        textToSave = textView.text
        println(textToSave)
    }

}
