//
//  ImagePicker.swift
//  picpro
//
//  Created by mica dai on 2024/7/16.
//

import SwiftUI
import PhotosUI
import AppKit

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}
#elseif os(macOS)
struct ImagePicker: NSViewControllerRepresentable {
    @Binding var selectedImage: NSImage?
    @Binding var isPresented: Bool
    
    class Coordinator: NSObject {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func openPanelDidEnd(_ panel: NSOpenPanel, returnCode: NSApplication.ModalResponse) {
            if returnCode == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
            parent.isPresented = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = false
            openPanel.canChooseFiles = true
            // 'allowedFileTypes' was deprecated in macOS 12.0: Use -allowedContentTypes instead
            if #available(macOS 12.0, *){
                openPanel.allowedContentTypes = [.png, .tiff, .jpeg]
            } else {
                openPanel.allowedFileTypes = ["png", "jpg", "jpeg"]
            }
            openPanel.begin { response in
                context.coordinator.openPanelDidEnd(openPanel, returnCode: response)
            }
        }
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif

struct UploadImageView: View {
#if os(iOS)
    @State private var selectedImage: UIImage?
#elseif os(macOS)
    @State private var selectedImage: NSImage?
#endif
    @State private var isImagePickerPresented = false
    @State private var isUploading = false
    @State private var uploadStatusMessage = ""
    
    var body: some View {
        VStack {
#if os(iOS)
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Text("Select an image")
                    .foregroundColor(.gray)
            }
#elseif os(macOS)
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Text("Select an image")
                    .foregroundColor(.gray)
            }
#endif
            
            Button(action: {
                isImagePickerPresented = true
            }) {
                Text("Choose Image")
            }
            .padding()
            
            if selectedImage != nil {
                Button(action: uploadImage) {
                    Text(isUploading ? "Uploading..." : "Upload Image")
                }
                .padding()
                .disabled(isUploading)
            }
            
            Text(uploadStatusMessage)
                .foregroundColor(.red)
                .padding()
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage, isPresented: $isImagePickerPresented)
        }
    }
    
    private func uploadImage() {
        guard let image = selectedImage else { return }
        isUploading = true
        
#if os(iOS)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadStatusMessage = "Failed to convert image to data."
            isUploading = false
            return
        }
#elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let imageData = bitmap.representation(using: .jpeg, properties: [:]) else {
            uploadStatusMessage = "Failed to convert image to data."
            isUploading = false
            return
        }
#endif
        
        let url = URL(string: "https://your-server.com/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let session = URLSession.shared
        session.uploadTask(with: request, from: body) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                if let error = error {
                    uploadStatusMessage = "Upload failed: \(error.localizedDescription)"
                } else {
                    uploadStatusMessage = "Upload successful!"
                }
            }
        }.resume()
    }
}

struct UploadImageView_Previews: PreviewProvider {
    static var previews: some View {
        UploadImageView()
    }
}
