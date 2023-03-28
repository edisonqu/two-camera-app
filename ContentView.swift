//
//  ContentView.swift
//  two-camera
//
//  Created by edison on 2023-03-27.
//

import SwiftUI
import AVFoundation
import Photos

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var frontCaptureSession: AVCaptureSession?
    @Published var backCaptureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var frontPhotoOutput: AVCapturePhotoOutput
    var backPhotoOutput: AVCapturePhotoOutput

    // Initialization
    override init() {
        frontPhotoOutput = AVCapturePhotoOutput()
        backPhotoOutput = AVCapturePhotoOutput()
        super.init()
        setupSessions()
    }

    func setupSessions() {
        // Find front and back cameras
        let cameraDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices

        for device in cameraDevices {
            if device.position == .front {
                frontCamera = device
            } else if device.position == .back {
                backCamera = device
            }
        }

        // Set up front camera session
        if let frontCamera = frontCamera {
            let frontCaptureSession = AVCaptureSession()
            do {
                let frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                if frontCaptureSession.canAddInput(frontCameraInput) {
                    frontCaptureSession.addInput(frontCameraInput)
                }
                if frontCaptureSession.canAddOutput(frontPhotoOutput) {
                    frontCaptureSession.addOutput(frontPhotoOutput)
                }
                
            } catch {
                print("Error setting up front camera session: \(error)")
            }
        }

        // Set up back camera session
        if let backCamera = backCamera {
            let backCaptureSession = AVCaptureSession()
            do {
                let backCameraInput = try AVCaptureDeviceInput(device: backCamera)
                if backCaptureSession.canAddInput(backCameraInput) {
                    backCaptureSession.addInput(backCameraInput)
                }
                if backCaptureSession.canAddOutput(backPhotoOutput) {
                    backCaptureSession.addOutput(backPhotoOutput)
                }

            } catch {
                print("Error setting up back camera session: \(error)")
            }
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.frontCaptureSession?.startRunning()
//            self?.backCaptureSession?.startRunning()

        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()

        if let frontCaptureSession = frontCaptureSession {
            if frontCaptureSession.canAddOutput(frontPhotoOutput) {
                frontCaptureSession.addOutput(frontPhotoOutput)
                frontPhotoOutput.capturePhoto(with: settings, delegate: self)
            }
        }

        if let backCaptureSession = backCaptureSession {
            if backCaptureSession.canAddOutput(backPhotoOutput) {
                backCaptureSession.addOutput(backPhotoOutput)
                backPhotoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Save the captured photo
        if let imageData = photo.fileDataRepresentation() {
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: imageData, options: nil)
            } completionHandler: { success, error in
                if success {
                    print("Photo saved successfully")
                } else if let error = error {
                    print("Error saving photo: \(error)")
                }
            }
        }
    }
}

struct CameraView: UIViewRepresentable {
    @ObservedObject var cameraViewModel: CameraViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let frontCaptureSession = cameraViewModel.frontCaptureSession {
            let frontPreviewLayer = AVCaptureVideoPreviewLayer(session: frontCaptureSession)
            frontPreviewLayer.videoGravity = .resizeAspectFill
            frontPreviewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
            view.layer.addSublayer(frontPreviewLayer)
        }
        
        if let backCaptureSession = cameraViewModel.backCaptureSession {
            let backPreviewLayer = AVCaptureVideoPreviewLayer(session: backCaptureSession)
            backPreviewLayer.videoGravity = .resizeAspectFill
            backPreviewLayer.frame = CGRect(x: view.bounds.width / 2, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
            view.layer.addSublayer(backPreviewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let frontPreviewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            frontPreviewLayer.frame = CGRect(x: 0, y: 0, width: uiView.bounds.width / 2, height: uiView.bounds.height)
        }
        
        if let backPreviewLayer = uiView.layer.sublayers?.last as? AVCaptureVideoPreviewLayer {
            backPreviewLayer.frame = CGRect(x: uiView.bounds.width / 2, y: 0, width: uiView.bounds.width / 2, height: uiView.bounds.height)
        }
    }
}

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            CameraView(cameraViewModel: cameraViewModel)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Button(action: {
                    cameraViewModel.takePhoto()
                }) {
                    Image(systemName: "camera.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding()
                }
                .padding(.bottom)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
