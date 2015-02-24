//
//  CameraController.swift
//  L8R
//


import UIKit
import AVFoundation
import CoreData

class CameraController: UIViewController {
    
    
    // MARK: - Variables
    
    var snapButton: UIButton!
    
    let session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var backCameraDevice:AVCaptureDevice?
    var frontCameraDevice:AVCaptureDevice?
    var stillCameraOutput:AVCaptureStillImageOutput!
    
    var captureDevice : AVCaptureDevice?
    
    var image: UIImage!
    
    var sessionQueue = dispatch_queue_create("com.example.camera.capture_session", DISPATCH_QUEUE_SERIAL)
    
    var l8rs = [NSManagedObject]()
    var l8rCount = Int()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        println("Camera view did load")
        super.viewDidLoad()
        self.setUpCamera()
        self.addSnapButton()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        println("view will appear")
        super.viewWillAppear(true)
        let pageController = self.parentViewController?.parentViewController? as ViewController
        pageController.hideButtons(true)
        snapButton.hidden = false
        previewLayer?.connection.enabled = true

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
        previewLayer?.connection.enabled = true

        
    }
    
    //MARK: - Add and configure capture button
    
    func addSnapButton(){
        snapButton = UIButton(frame: CGRect(x: 0, y: view.frame.height-100, width: 80, height: 80))
        snapButton.center.x = view.center.x
        let buttonImage = UIImage(named: "snapButton")
        snapButton.setImage(buttonImage, forState: .Normal)
        snapButton.addTarget(self, action: Selector("snapButtonPressed:"), forControlEvents: .TouchUpInside)
        snapButton.hidden = false
        
        view.addSubview(snapButton)

        
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
                    
                    self.previewLayer?.connection.enabled = false
                    let pageController = self.parentViewController?.parentViewController as ViewController
                    self.snapButton.hidden = true
                    pageController.hideButtons(false)
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
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
}
