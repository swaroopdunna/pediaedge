//
//  SwiftCapturePhotoView.swift
//  CapturePhoto
//
//  Created by Mohammad Ali Yektaie on 9/14/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

@objc(ISwiftCapturePhotoViewListener)
public protocol ISwiftCapturePhotoViewListener {
    func onError(title: NSString, message: NSString);
    func onRecordingStarted();
    func onRecordingStopped();
    func onPreviewLoad();
    func onCloseModule();
}

@available(iOS 11.1, *)
@objc(SwiftCapturePhotoView)
public class SwiftCapturePhotoView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDataOutputSynchronizerDelegate, AVCaptureDepthDataOutputDelegate {
    private let DEFAULT_SAVE_FOLDER_NAME = "temp_capture";
    private let DEVICE_TYPE_DEPTH_MODE = [AVCaptureDevice.DeviceType.builtInTrueDepthCamera, AVCaptureDevice.DeviceType.builtInDualCamera];
    private let DEVICE_TYPE_TELEPHOTO = [AVCaptureDevice.DeviceType.builtInTelephotoCamera];
    private let DEVICE_TYPE_WIDE_ANGLE = [AVCaptureDevice.DeviceType.builtInWideAngleCamera];
    private let CAPTURE_DEFAULT_PRESET = AVCaptureSession.Preset.vga640x480;
    
    // 50ms ~> 20 capture/sec
    // 200ms ~> 5 capture/sec
    private let DELAY_BETWEEN_CAPTURES = 200.0; // in miliseconds
    private let ENABLE_ABSOLUTE_DEPTH = true
    private let DISPLAY_OVERLAY = true
    let PI : CGFloat = 3.14159265359
    
    private var mainCameraView: UIView!
    private var overlay: UIImageView!
    private var recordButton: UIButton!
    private var closeButton: UIButton!
    private var previewButton: UIButton!
    private var timerLabel:UILabel!
    private var progressBar: CircularProgressBar!

    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private var isRecording = false
    private var isCloseTapped = false
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], autoreleaseFrequency: .workItem) // Communicate with the session and other session objects on this queue.
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let photoOutputQueue = DispatchQueue(label: "photo data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var photoDataOutput = AVCapturePhotoOutput()
    private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private let depthOutputQueue = DispatchQueue(label: "depth data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    private var renderingEnabled = true
    private var imageIndex = 0;
    private var lastTimeImageCaptured = 0.0;
    private var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera], mediaType: .video, position: .back)
    private var listener: ISwiftCapturePhotoViewListener?

    private func showError(title: String?, message: String?) {
        if let list = listener {
            let title = NSString(utf8String: title ?? "Error");
            let message = NSString(utf8String: message ?? "An unexpected error ocurred.");
            list.onError(title: title!, message: message!);
        }
    }
    
    private var timerCount = 0
    private var timer:Timer?
    let maxTimerSecs = 10
    
    @objc
    public func setup(listener: ISwiftCapturePhotoViewListener) {
        self.listener = listener;
        self.backgroundColor = UIColor.white;
        
        self.mainCameraView = UIView();
        self.addSubview(self.mainCameraView);
        
        self.overlay = UIImageView(image: UIImage(named: "OverlayImage", in: Bundle(for: type(of: self)), compatibleWith: nil));
        self.overlay.contentMode = .scaleAspectFill;
        self.addSubview(self.overlay);
        
        self.progressBar = CircularProgressBar()
        self.progressBar.setProgress(to: 0, withAnimation: false)
        self.addSubview(self.progressBar);
        
        self.recordButton = UIButton();
        self.recordButton.setImage(UIImage(named: "NotRecordImage", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal);
        self.recordButton.addTarget(self, action: #selector(onRecordButtonClick), for: .touchUpInside)
        self.addSubview(self.recordButton);
        
        self.timerLabel = UILabel()
//        timerLabel.center = CGPoint(x: 160, y: 285)
        timerLabel.textAlignment = .center
        timerLabel.text = "00:00"
        timerLabel.textColor =  UIColor(red: 0.27, green: 0.215, blue: 0.18, alpha: 1.0)
        self.addSubview(timerLabel);
        
        self.closeButton = UIButton();
        self.closeButton.setImage(UIImage(named: "closeImage", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal);
        self.closeButton.addTarget(self, action: #selector(onCloseButtonClick), for: .touchUpInside)
        self.addSubview(self.closeButton);
        
        self.previewButton = UIButton();
        // Hide the "preview" button since the app automatically moves to preview page.
        self.previewButton.isHidden = true;
        self.previewButton.setImage(UIImage(named: "previewImage", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal);
        self.previewButton.addTarget(self, action: #selector(onPreviewButtonClick), for: .touchUpInside)
        self.addSubview(self.previewButton);
    }
    
    override public func layoutSubviews() {
        let margin = CGFloat(40);
        
        let recordButtonWidth = CGFloat(48);
        let recordButtonHeight = CGFloat(48);

        let timerlabelWidth = CGFloat(100);
        let timerlabelHeight = CGFloat(20);

        let closeButtonWidth = CGFloat(36);
        let closeButtonHeight = CGFloat(36);

        let previewButtonWidth = CGFloat(48);
        let previewButtonHeight = CGFloat(48);

        let overlayRatio: CGFloat = 1.3333333 // Overlay ratio should be 3x4 ratio.
        
        var width = CGFloat(self.frame.size.width-margin);
        var height = CGFloat(width * overlayRatio);
        
        if height > 0.9 * self.frame.size.height {
            height = CGFloat(0.7 * self.frame.size.height)
            width = CGFloat(height * 0.75)
        }
        
        print("width : \(width) and height: \(height)");
        
//        var location = CGPoint(x: (self.frame.size.width - width) / 2, y: (self.frame.size.height - height) / 2);
        var location = CGPoint(x: (self.frame.size.width - width) / 2, y:  (self.frame.size.height - height) / 2 - margin);

        var size = CGSize(width: width, height: height);
        
        self.mainCameraView.frame = CGRect(origin: location, size: size);
        self.overlay.frame = CGRect(origin: location, size: size);
        
        let recordHeight = ((self.frame.size.height - (self.frame.size.width * overlayRatio)) / 2) - 2 * margin;
        location = CGPoint(x: (self.frame.size.width - recordHeight) / 2, y: self.frame.size.height - margin - recordHeight);
//        size = CGSize(width: recordHeight, height: recordHeight);
        size = CGSize(width: recordButtonWidth, height: recordButtonHeight);

        let recordBtnLocation = CGPoint(x: (self.frame.size.width) / 2, y: self.frame.size.height - margin - recordHeight + 8)

        self.recordButton.frame = CGRect(origin: recordBtnLocation, size: size);
        
        self.recordButton.center = recordBtnLocation;
        
        self.progressBar.frame = CGRect(origin: .zero, size: CGSize(width: size.width * 1.3, height: size.height * 1.3))
        self.progressBar.center = self.recordButton.center
        
        let timerLabelLocation = CGPoint(x: (self.frame.size.width) / 2, y: self.frame.size.height - margin - recordHeight - timerlabelHeight-15);
        self.timerLabel.frame = CGRect(origin: timerLabelLocation, size: CGSize(width: timerlabelWidth, height: timerlabelHeight));
        self.timerLabel.center = timerLabelLocation;

        
        let closeBtnLocation = CGPoint(x: 20.0, y: self.recordButton.frame.origin.y + (margin * 0.4));

        self.closeButton.frame = CGRect(origin: closeBtnLocation, size: CGSize(width: closeButtonWidth, height: closeButtonHeight));

        let previewBtnLocation = CGPoint(x: self.frame.size.width - (margin*1.5), y: self.recordButton.frame.origin.y + (margin*0.2));

        self.previewButton.frame = CGRect(origin: previewBtnLocation, size: CGSize(width: previewButtonWidth, height: previewButtonHeight));

        super.layoutSubviews();
    }
    
    @objc
        public func onContainerPause() {
            sessionQueue.async {
                self.renderingEnabled = false
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
    
    @objc
    public func onContainerResume() {
        FileSystem.deleteFolder(inDocuments: DEFAULT_SAVE_FOLDER_NAME)
        FileSystem.createFolder(inDocuments: DEFAULT_SAVE_FOLDER_NAME)
        
        setupCamera()
    }
    
    func setupCamera() {
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Why not do all of this on the main queue?
         Because AVCaptureSession.startRunning() is a blocking call which can
         take a long time. We dispatch session setup to the sessionQueue so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        
        sessionQueue.async {
            if (!self.configureSession()) {
                
            }
        }
    }
    
    private func configureSession() -> Bool {
        videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: DEVICE_TYPE_DEPTH_MODE, mediaType: .video, position: .back)
        
        var result = false
        
        if (videoDeviceDiscoverySession.devices.count != 0) {
            result = configureSessionWithDepth();
        } else {
            videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: DEVICE_TYPE_TELEPHOTO, mediaType: .video, position: .back)
            if (videoDeviceDiscoverySession.devices.count != 0) {
                result = configureSessionWithoutDepth(deviceTypes: DEVICE_TYPE_TELEPHOTO);
            } else {
                result = configureSessionWithoutDepth(deviceTypes: DEVICE_TYPE_WIDE_ANGLE);
            }
        }
        
        return result;
    }
        
    private func configureSessionWithoutDepth(deviceTypes: [AVCaptureDevice.DeviceType]) -> Bool {
           let defaultVideoDevice: AVCaptureDevice? = AVCaptureDevice.default(deviceTypes[0], for: .video, position: .back)
           
           guard let videoDevice = defaultVideoDevice else {
               print("Could not find any video device")
               return false
           }
           
           do {
               videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
           } catch {
               print("Could not create video device input: \(error)")
               return false
           }
           
           session.beginConfiguration()
           
           // Add a video input
           guard session.canAddInput(videoDeviceInput) else {
               print("Could not add video device input to the session")
               session.commitConfiguration()
               return false
           }
           session.addInput(videoDeviceInput)
        
           session.sessionPreset = CAPTURE_DEFAULT_PRESET
               
           // Add a video data output
           if session.canAddOutput(videoDataOutput) {
               session.addOutput(videoDataOutput)
               videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
           } else {
               print("Could not add video data output to the session")
               session.commitConfiguration()
               return false
           }

           videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue);
           
           session.commitConfiguration()
           session.startRunning()
           
           DispatchQueue.main.async {
               self.initializePreviews()
           }
           
           return true
       }
    
    private func configureSessionWithDepth() -> Bool {
        let defaultVideoDevice: AVCaptureDevice? = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        
        guard let videoDevice = defaultVideoDevice else {
            print("Could not find any video device")
            return false
        }
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Could not create video device input: \(error)")
            return false
        }
        
        session.beginConfiguration()
        
        // Add a video input
        guard session.canAddInput(videoDeviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return false
        }
        session.addInput(videoDeviceInput)
        session.sessionPreset = CAPTURE_DEFAULT_PRESET
        if (ENABLE_ABSOLUTE_DEPTH) {
            session.sessionPreset = CAPTURE_DEFAULT_PRESET
            
            // Add a video data output
            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            } else {
                print("Could not add video data output to the session")
                session.commitConfiguration()
                return false
            }
            
            // Add a depth data output
            if session.canAddOutput(depthDataOutput) {
                session.addOutput(depthDataOutput)
    //            depthDataOutput.setDelegate(self, callbackQueue: depthOutputQueue)
                depthDataOutput.isFilteringEnabled = false
                if let connection = depthDataOutput.connection(with: .depthData) {
                    connection.isEnabled = true
                } else {
                    print("No AVCaptureConnection")
                }
            } else {
                print("Could not add depth data output to the session")
                session.commitConfiguration()
                return false
            }
            
            // Search for highest resolution with half-point depth values
            let depthFormats = videoDevice.activeFormat.supportedDepthDataFormats
            
            let filtered = depthFormats.filter({
                CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16
            })
            
            
            
            
            let selectedFormat = filtered.max(by: {
                first, second in CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
            })
            
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.activeDepthDataFormat = selectedFormat
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
                session.commitConfiguration()
                return false
            }
            
            // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
            // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
            
            outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
            outputSynchronizer!.setDelegate(self, queue: dataOutputQueue)
        } else {
            // Add a video data output
            photoDataOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoDataOutput) {
                session.addOutput(photoDataOutput)
                
                let isDepthSupported = photoDataOutput.isDepthDataDeliverySupported
                photoDataOutput.isDepthDataDeliveryEnabled = isDepthSupported
                
            } else {
                print("Could not add video data output to the session")
                session.commitConfiguration()
                return false
            }
            
            session.sessionPreset = AVCaptureSession.Preset.photo
        }
        
        session.commitConfiguration()
        session.startRunning()
        
        DispatchQueue.main.async {
            self.initializePreviews()
        }
        
        return true
    }

    private func initializePreviews() {
        let view : UIView = self.mainCameraView
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        let rootLayer :CALayer = view.layer
        rootLayer.masksToBounds=true
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if (isRecording) {
            let timeInMS = Date().timeIntervalSince1970 * 1000
            if (abs(self.lastTimeImageCaptured - timeInMS) > DELAY_BETWEEN_CAPTURES) {
                self.lastTimeImageCaptured = timeInMS
                let videoImage = loadVideoData(sampleBuffer: sampleBuffer)

                saveImage(videoImage, "video", imageIndex)

                imageIndex+=1
            }
        }

    }

    public func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {

        if !renderingEnabled {
           return
        }

        // Read all outputs
        guard renderingEnabled,
           let syncedDepthData: AVCaptureSynchronizedDepthData =
           synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData,
           let syncedVideoData: AVCaptureSynchronizedSampleBufferData =
           synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else {
               // only work on synced pairs
               return
        }

        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped {
           return
        }

        let depthData = syncedDepthData.depthData

        let depthImage = convertDepthToImage(depthData: depthData)

        if (isRecording) {
            let timeInMS = Date().timeIntervalSince1970 * 1000
            if (abs(self.lastTimeImageCaptured - timeInMS) > DELAY_BETWEEN_CAPTURES) {
//                if depthData.depthDataQuality == .high {
                    self.lastTimeImageCaptured = timeInMS
                    let videoImage = loadVideoData(sampleBuffer: syncedVideoData.sampleBuffer)

                    saveImage(depthImage, "depth", imageIndex)
                    saveImage(videoImage, "video", imageIndex)

                    imageIndex+=1
                    
    //                DispatchQueue.main.async {
    //                    self.title = "Recording (\(self.imageIndex))";
    //                }
//                }
            }
        }
    }
    
    func saveImage(_ image: UIImage, _ prefix: String, _ index: Int) {
        let fileName = "\(prefix)_\(index)"

//        let imageData = image.pngData()!
        
        let imageData = UIImagePNGRepresentation(image)
        var fileExtension = "png";
        if (prefix == "depth") {
            fileExtension = "depth";
        }
        FileSystem.writeFileDocument(imageData, atPath: DEFAULT_SAVE_FOLDER_NAME, inFile: fileName, withExtension: fileExtension)
    }
    
    func loadVideoData(sampleBuffer buffer : CMSampleBuffer) -> UIImage {
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(buffer)!
        let cmage : CIImage = CIImage(cvPixelBuffer: imageBuffer).imageRotatedByRadians(radians: PI / 2, imageOrientation: UIImage.Orientation.right)
        
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        
        return image
    }
    
    func convertDepthToImage(depthData : AVDepthData) -> UIImage {
        let depthPixelBuffer : CVPixelBuffer = depthData.depthDataMap
        
        let ciImage : CIImage = CIImage(cvPixelBuffer: depthPixelBuffer).imageRotatedByRadians(radians: PI / 2, imageOrientation: UIImage.Orientation.right);
        let temporaryContext : CIContext = CIContext(options: nil);
        
        let w = CVPixelBufferGetWidth(depthPixelBuffer)
        let h = CVPixelBufferGetHeight(depthPixelBuffer)
                
        let translation = 0;
        let videoImage = temporaryContext.createCGImage(ciImage, from: CGRect(x: 0 - translation, y: 0 + translation, width: h, height: w))
        
        var image : UIImage? = nil
        if let vImage = videoImage {
            let uiImage : UIImage = UIImage(cgImage: vImage)
            image = uiImage
        }
        
        return image!
    }
    
    func applyDepthFilters(_ image: CIImage) -> CIImage {
        let gaussianFilter = CIFilter(name:"CIBoxBlur")
        gaussianFilter?.setValue(image, forKey: kCIInputImageKey)
        gaussianFilter?.setValue(40, forKey: kCIInputRadiusKey)
        
        if let r = gaussianFilter?.outputImage {
            return r
        }
        
        return image
    }
        
    func startRecording() {
        isRecording = true;
        self.imageIndex = 0
        
        if let list = listener {
            list.onRecordingStarted();
        }
        
//        handleTimer()
        callTimer()
    }
    
    func callTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)

    }
    
    @objc func fireTimer() {
        self.timerCount += 1
        print("timer \(self.timerCount)")
        self.timerLabel.text = String(format: "00:%02d", self.timerCount)

        if(self.timerCount >= maxTimerSecs ){
            print("timer finished..stop recording")
                timer?.invalidate()
            self.stopRecording()
            self.timerCount = 0
            self.timerLabel.text = String(format: "00:%02d", self.timerCount)
            
            self.progressBar.setProgress(to: 0, withAnimation: false)
        } else {
            self.progressBar.setProgress(to: Double(min(1, Double(self.timerCount) / Double(maxTimerSecs))), withAnimation: false)
        }
    }
    
    func closeTimer() {
        self.timerCount = 0
        self.timerLabel.text = String(format: "00:%02d", self.timerCount)
        timer?.invalidate()

    }
    
    func stopRecording() {
        let wasRecording = isRecording
        isRecording = false;

        if (wasRecording && !isCloseTapped) {
            finalizeRecording()
        }
        closeTimer()
    }
    
    @objc
    func onRecordButtonClick(_ sender: Any) {
        if (isRecording) {
            stopRecording()
            self.progressBar.setProgress(to: 0, withAnimation: false)
        } else {
            self.progressBar.setProgress(to: 0, withAnimation: false)
            startRecording()
        }
    }
    
    @objc
    func onCloseButtonClick(_ sender: Any) {
        isCloseTapped = true
        
        if (isRecording) {
            stopRecording()
        }
        if let list = listener {
            list.onCloseModule();
        }
    }
    
    @objc
    func onPreviewButtonClick(_ sender: Any) {
        print("preview clicked");
        if let list = listener {
            list.onPreviewLoad();
        }
    }
    
    func finalizeRecording() {
        if let list = listener {
            list.onRecordingStopped();
        }

//        let alert = UIAlertController(title: "Sample Name", message: "Please enter the name of the sample you just collected:", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
//            FileSystem.deleteFolder(inDocuments: "temp")
//            self.close()
//        }))
//
//        alert.addTextField(configurationHandler: { textField in
//            textField.placeholder = "Sample name here..."
//        })
//
//        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
//            FileSystem.renameFolder(inDocuments: "temp", to: alert.textFields![0].text!)
//            self.navigationController?.popViewController(animated: true)
//
//            self.close()
//        }))
//
//        self.present(alert, animated: true)
    }
}


extension CIImage {
    // https://beckyhansmeyer.com/tag/ciimage/
    func imageRotatedByRadians(radians: CGFloat, imageOrientation: UIImage.Orientation) -> CIImage {
        let finalRadians = -radians
        var image = self
        
        let rotation = CGAffineTransform.init(rotationAngle: finalRadians)
        let transformFilter = CIFilter(name: "CIAffineTransform")
        transformFilter!.setValue(image, forKey: "inputImage")
        transformFilter!.setValue(NSValue(cgAffineTransform: rotation), forKey: "inputTransform")
        image = transformFilter!.value(forKey: "outputImage") as! CIImage
        
        let extent:CGRect = image.extent
        let translation = CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
        transformFilter!.setValue(image, forKey: "inputImage")
        transformFilter!.setValue(NSValue(cgAffineTransform: translation), forKey: "inputTransform")
        image = transformFilter!.value(forKey: "outputImage") as! CIImage
        
        return image
    }
    
    
}
