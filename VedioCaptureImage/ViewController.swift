//
//  ViewController.swift
//  VedioCaptureImage
//
//  Created by iyzsh on 16/6/6.
//  Copyright © 2016年 iyzsh. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var captureImageView: UIImageView!
    
    let captureSession = AVCaptureSession()
    var previewLayer:AVCaptureVideoPreviewLayer! = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setupCatptureSession()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        print(orientation)
        
        switch (orientation)
        {
        case .Portrait:
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            break
        case .LandscapeRight:
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
            break
        case .LandscapeLeft:
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            break
        default:
            previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            break
        }
    }

    func setupCatptureSession() {
//        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            // If permission hasn't been granted, notify the user.
            if !granted {
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                })
            }
        });
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            captureSession.addInput(input)
        } catch {
            print("can't access camera")
            return
        }

        // although we don't use this, it's required to get captureOutput invoked
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        captureImageView.layer.addSublayer(previewLayer)
        
        
//        let orientation: AVCaptureVideoOrientation?
        
//        switch UIApplication.sharedApplication().statusBarOrientation{
//        case .LandscapeLeft:
//            orientation = .LandscapeLeft
//        case .LandscapeRight:
//            orientation = .LandscapeRight
//        case .Portrait:
//            orientation = .Portrait
//        case .PortraitUpsideDown:
//            orientation = .PortraitUpsideDown
//        case .Unknown:
//            orientation = nil
//        }
//        
//        if let orientation = orientation{
//            print(orientation)
//            previewLayer.connection.videoOrientation = orientation
//        }
//        dispatch_async(dispatch_get_main_queue(), {
//            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
//        })
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey:Int(kCVPixelFormatType_32BGRA)]
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        if let image = self.imageFromSampleBuffer(sampleBuffer) {
            dispatch_async(dispatch_get_main_queue()) {
                self.captureImageView.image = UIImage(CGImage: image, scale: 1.0, orientation: UIImageOrientation.Right)
            }
        }
        
        
    }
    
    private func imageFromSampleBuffer(sampleBuffer :CMSampleBufferRef) -> CGImage? {
        
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let address = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent: Int = 8
        let context = CGBitmapContextCreate(address, width, height, bitsPerCompornent, bytesPerRow, colorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue)
        let imageRef = CGBitmapContextCreateImage(context)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        return imageRef
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }

}

