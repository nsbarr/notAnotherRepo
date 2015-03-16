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
    
    var attr: NSDictionary!
    let session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var textView: UITextView!
    
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    
    var currentInput: AVCaptureDeviceInput?
    var currentDeviceIsBack = true
    
    var textToSave = NSString()
    
    var image: UIImage!
    
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
    
    var l8rs = [NSManagedObject]()
    var l8rCount = Int()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        println("new branch")
        super.viewDidLoad()
        self.setUpCamera()
        self.addSnapButton()
        self.addFlipButton()

        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        let pvc = self.parentViewController?.parentViewController? as ViewController
        pvc.cameraButtonsAreHidden(false)
        previewLayer?.connection.enabled = true
        textToSave = ""


    }
    
    // MARK: - Set up the Camera
    func setUpCamera(){
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
    
    func addSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-100, width: 80, height: 80))
        snapButton.center.x = view.center.x
        let buttonImage = UIImage(named: "snapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchDown)
        snapButton.hidden = false
        
        view.addSubview(snapButton)
        
    }
    
    func addFlipButton(){
        flipButton = UIButton(frame: CGRectMake(10, 20, 40, 40))
        flipButton.setTitle("Flip", forState: .Normal)
        flipButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 24)
        flipButton.addTarget(self, action: Selector("toggleCamera:"), forControlEvents: .TouchUpInside)
        flipButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        flipButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        flipButton.titleLabel!.layer.shadowOpacity = 1
        flipButton.titleLabel!.layer.shadowRadius = 1
        flipButton.sizeToFit()

        view.addSubview(flipButton)
    }
    
    func addTextButton(){
        
        if textButton != nil {
            textButton.removeFromSuperview()
        }
        textButton = UIButton(frame: CGRectMake(view.frame.width-50, view.frame.height-54, 40, 40))
        textButton.setTitle("Aa", forState: .Normal)
        textButton.tag = 101
        textButton.titleLabel?.font = UIFont(name: "Arial-BoldMT", size: 24)
        textButton.addTarget(self, action: Selector("openKeyboard:"), forControlEvents: .TouchUpInside)
        textButton.titleLabel!.layer.shadowColor = UIColor.blackColor().CGColor
        textButton.titleLabel!.layer.shadowOffset = CGSizeMake(0, 1)
        textButton.titleLabel!.layer.shadowOpacity = 1
        textButton.titleLabel!.layer.shadowRadius = 1
        textButton.sizeToFit()
        view.addSubview(textButton)
    }
    
    func openKeyboard(sender: UIButton){
        textView.becomeFirstResponder()
    }
    
    func snapButtonPressed(sender: UIButton){
        println("snapped")
      //  let text = self.textToSave as NSString

        
        dispatch_async(sessionQueue) { () -> Void in
            
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            // update the video orientation to the device one
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!
            
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) {
                (imageDataSampleBuffer, error) -> Void in
                
                if error == nil {
                    println("should be disabling connection...")
                    let pvc = self.parentViewController?.parentViewController as ViewController
                    pvc.cameraButtonsAreHidden(true)
                    self.addTextButton()
                    self.addTextView()
                    self.previewLayer?.connection.enabled = false

                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    //TODO: Reduce image size here maybe? Or at least make them the same size.
                    
                    //TODO: Mirror front camera photo

                    
                    if let theImage = UIImage(data: imageData) {
                        
                       self.image = theImage

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
    
    func addTextView(){
        
        if textView != nil {
            textView.removeFromSuperview()
        }
        
        textView = UITextView(frame: CGRectMake(0, 80, self.view.frame.width, self.view.frame.height-200))
        textView.backgroundColor = UIColor.clearColor()
        textView.returnKeyType = UIReturnKeyType.Done
        textView.delegate = self
        
        let font = UIFont(name: "Helvetica Bold", size: 36.0)!
        let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as NSMutableParagraphStyle
        textStyle.alignment = NSTextAlignment.Center
        let textColor = UIColor.whiteColor()
        
        attr = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: textStyle
        ]
        let placeholderText = NSMutableAttributedString(string: " ", attributes: attr)
        textView.attributedText = placeholderText
        textView.textAlignment = .Center
        textView.textContainerInset = UIEdgeInsets(top: self.view.center.y-200, left: 0, bottom: 0, right: 0)
        let offset:CGPoint = self.view.center
        textView.contentOffset = offset
        //  textView.font = UIFont(name: "Arial-BoldMT", size: 36)
        //  textView.textColor = UIColor.whiteColor()
        self.view.addSubview(textView)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            let pvc = self.parentViewController?.parentViewController as ViewController
            pvc.toggleTriggerButtonVisibility(pvc.triggerToggleButton)
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        let pvc = self.parentViewController?.parentViewController as ViewController
        pvc.toggleTriggerButtonVisibility(textButton)
        
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        textToSave = textView.text
        println(textToSave)
    }

}
